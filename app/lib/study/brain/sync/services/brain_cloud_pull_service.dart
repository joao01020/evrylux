import '../../security/crypto/brain_crypto_service.dart';
import '../../security/keys/brain_key_service.dart';

import '../../vault/compaction/brain_vault_compaction_ledger.dart';
import '../../vault/models/brain_vault_object.dart';
import '../../vault/services/brain_vault_serializer.dart';
import '../../vault/services/brain_vault_service.dart';
import '../../vault/storage/brain_vault_storage.dart';

import '../models/brain_cloud_pull_result.dart';
import '../models/brain_remote_deletion_floor.dart';
import '../ports/brain_remote_object_source.dart';

typedef BrainDeletionObservationSink =
    Future<
      void
    >
    Function({
      required String vaultId,
      required List<
        BrainDeletionObservation
      >
      observations,
    });

class BrainCloudPullService {
  BrainCloudPullService({
    required BrainRemoteObjectSource remote,
    required BrainVaultService vaultService,
    required BrainVaultStorage vaultStorage,
    required BrainKeyService keyService,
    BrainDeletionObservationSink? deletionObservationSink,
    BrainCryptoService? cryptoService,
    BrainVaultSerializer? serializer,
  }) : _remote =
           remote,
       _vaultService = vaultService,
       _vaultStorage = vaultStorage,
       _keyService = keyService,
       _deletionObservationSink = deletionObservationSink,
       _cryptoService =
           cryptoService ??
           BrainCryptoService(),
       _serializer =
           serializer ??
           const BrainVaultSerializer();

  final BrainRemoteObjectSource _remote;
  final BrainVaultService _vaultService;
  final BrainVaultStorage _vaultStorage;
  final BrainKeyService _keyService;
  final BrainDeletionObservationSink? _deletionObservationSink;
  final BrainCryptoService _cryptoService;
  final BrainVaultSerializer _serializer;

  Future<
    BrainCloudPullResult
  >
  pullCurrentVault() async {
    final manifest = await _vaultService.openVault();

    var ledger = await _vaultStorage.loadCompactionLedger(
      vaultId: manifest.vaultId,
    );

    // Phase 3: deletion floors are loaded before normal objects so a device
    // that was offline during remote GC learns the irreversible deletion
    // before any stale local state can participate in merge/backfill.
    final remoteFloors = await _remote.loadDeletionFloors(
      vaultId: manifest.vaultId,
    );

    var appliedRemoteFloors = 0;
    var purgedByRemoteFloor = 0;
    var ledgerChanged = false;

    // First persist every authoritative floor. Only after this durable local
    // write may any .evobj be removed. This ordering is crash-safe.
    for (final remoteFloor in remoteFloors) {
      if (remoteFloor.vaultId !=
          manifest.vaultId) {
        throw const FormatException(
          'Deletion floor pertence a outro Vault.',
        );
      }

      final existingFloor = ledger.floorFor(
        remoteFloor.objectId,
      );

      if (existingFloor ==
              null ||
          existingFloor.objectVersion <
              remoteFloor.objectVersion) {
        ledger = ledger.record(
          BrainVaultCompactionFloor(
            objectId: remoteFloor.objectId,
            vaultId: remoteFloor.vaultId,
            objectVersion: remoteFloor.objectVersion,
            deletedAt: remoteFloor.deletedAt,
            compactedAt:
                remoteFloor.compactedAt.isBefore(
                  remoteFloor.deletedAt,
                )
                ? remoteFloor.deletedAt
                : remoteFloor.compactedAt,
          ),
        );

        ledgerChanged = true;
        appliedRemoteFloors++;
      }
    }

    if (ledgerChanged) {
      await _vaultStorage.saveCompactionLedger(
        ledger,
      );
    }

    for (final remoteFloor in remoteFloors) {
      final local = await _vaultStorage.loadObject(
        remoteFloor.objectId,
      );

      if (local ==
          null) {
        continue;
      }

      final removed = await _vaultStorage.purgeObjectCoveredByDeletionFloor(
        objectId: remoteFloor.objectId,
        expectedCurrentObjectVersion: local.header.objectVersion.value,
      );

      if (removed) {
        purgedByRemoteFloor++;
      }
    }

    final remoteObjects = await _remote.loadVaultObjects(
      vaultId: manifest.vaultId,
    );

    var applied = 0;
    var skippedSameVersion = 0;
    var skippedNewerLocal = 0;
    var skippedCompactedFloor = 0;
    var rejectedResurrection = 0;

    final observedDeletions =
        <
          String,
          BrainDeletionObservation
        >{};

    for (final remotePayload in remoteObjects) {
      if (remotePayload.vaultId !=
          manifest.vaultId) {
        throw const FormatException(
          'Objeto remoto pertence a outro Vault.',
        );
      }

      final remoteObject = remotePayload.toVaultObject(
        serializer: _serializer,
      );

      if (remoteObject.isDeleted) {
        await _validateRemoteObjectAuthenticity(
          remoteObject,
        );

        final previous = observedDeletions[remoteObject.header.objectId];

        final currentVersion = remoteObject.header.objectVersion.value;

        if (previous ==
                null ||
            previous.objectVersion <
                currentVersion) {
          observedDeletions[remoteObject.header.objectId] = BrainDeletionObservation(
            objectId: remoteObject.header.objectId,
            objectVersion: currentVersion,
          );
        }
      }

      final floor = ledger.floorFor(
        remoteObject.header.objectId,
      );

      if (floor !=
          null) {
        final remoteVersion = remoteObject.header.objectVersion.value;

        if (remoteObject.isActive) {
          rejectedResurrection++;
          continue;
        }

        if (remoteVersion <=
            floor.objectVersion) {
          skippedCompactedFloor++;
          continue;
        }
      }

      final localObject = await _vaultStorage.loadObject(
        remoteObject.header.objectId,
      );

      if (localObject !=
          null) {
        final localVersion = localObject.header.objectVersion.value;

        final remoteVersion = remoteObject.header.objectVersion.value;

        if (localVersion >
            remoteVersion) {
          skippedNewerLocal++;
          continue;
        }

        if (localVersion ==
            remoteVersion) {
          skippedSameVersion++;
          continue;
        }
      }

      if (remoteObject.isActive) {
        await _validateRemoteObjectAuthenticity(
          remoteObject,
        );
      }

      await _vaultStorage.saveObject(
        remoteObject,
      );

      applied++;
    }

    if (observedDeletions.isNotEmpty &&
        _deletionObservationSink !=
            null) {
      await _deletionObservationSink(
        vaultId: manifest.vaultId,
        observations: observedDeletions.values.toList(
          growable: false,
        ),
      );
    }

    if (applied >
            0 ||
        purgedByRemoteFloor >
            0) {
      final currentManifest = await _vaultStorage.loadManifest();

      if (currentManifest ==
          null) {
        throw StateError(
          'Manifest não encontrado após pull.',
        );
      }

      final now = DateTime.now().toUtc();

      final floor =
          currentManifest.updatedAt.isAfter(
            currentManifest.createdAt,
          )
          ? currentManifest.updatedAt
          : currentManifest.createdAt;

      await _vaultStorage.saveManifest(
        currentManifest.touch(
          updatedAt:
              now.isAfter(
                floor,
              )
              ? now
              : floor,
        ),
      );
    }

    return BrainCloudPullResult(
      vaultId: manifest.vaultId,
      remoteCount: remoteObjects.length,
      remoteDeletionFloorCount: remoteFloors.length,
      applied: applied,
      appliedRemoteFloors: appliedRemoteFloors,
      purgedByRemoteFloor: purgedByRemoteFloor,
      skippedSameVersion: skippedSameVersion,
      skippedNewerLocal: skippedNewerLocal,
      skippedCompactedFloor: skippedCompactedFloor,
      rejectedResurrection: rejectedResurrection,
    );
  }

  Future<
    void
  >
  _validateRemoteObjectAuthenticity(
    BrainVaultObject object,
  ) async {
    object.header.validate();

    if (object.isDeleted) {
      final tombstone = object.tombstone;

      if (tombstone ==
          null) {
        throw const FormatException(
          'Objeto remoto excluído sem tombstone.',
        );
      }

      tombstone.validate();

      if (tombstone.objectId !=
              object.header.objectId ||
          tombstone.vaultId !=
              object.header.vaultId) {
        throw const FormatException(
          'Tombstone remoto não corresponde ao header.',
        );
      }

      return;
    }

    final encryptedPayload = object.encryptedPayload;

    if (encryptedPayload ==
        null) {
      throw const FormatException(
        'Objeto remoto ativo sem payload criptografado.',
      );
    }

    final key = await _keyService.requireKeyBundle(
      vaultId: object.header.vaultId,
    );

    if (key.keyVersion !=
        object.header.keyVersion) {
      throw StateError(
        'A versão da Master Key local não abre o objeto remoto.',
      );
    }

    final plaintext = await _cryptoService.decryptString(
      payload: encryptedPayload,
      keyBundle: key,
    );

    final decoded = _serializer.deserializeLogicalPayload(
      plaintext,
    );

    _serializer.verifyBinding(
      header: object.header,
      decoded: decoded,
    );
  }
}
