import '../../models/brain_concept.dart';
import '../../models/brain_file.dart';

import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_type.dart';
import '../services/brain_vault_service.dart';

// ============================================================
// BRAIN NOTE VAULT STORE
// ============================================================
//
// Fonte criptografada das notas do Cérebro para sync E2EE.
//
// BrainStorage ainda pode existir como mirror/compatibilidade de
// Markdown local, mas nenhuma nota nova entra na SyncQueue em
// plaintext.
//
// ============================================================

class BrainNoteVaultStore {
  BrainNoteVaultStore({
    required BrainVaultService vaultService,
  }) : _vaultService = vaultService;

  final BrainVaultService _vaultService;

  Future<
    void
  >
  initialize() async {
    await _vaultService.getOrCreateVault();
  }

  // ============================================================
  // SAVE / UPSERT
  // ============================================================

  Future<
    BrainVaultObject
  >
  saveNote(
    BrainFile note, {
    String? legacyRemoteId,
  }) async {
    await initialize();

    final data = _toVaultData(
      note,
      legacyRemoteId: legacyRemoteId,
    );

    final existing = await findEncryptedObjectByPath(
      note.path,
    );

    if (existing ==
        null) {
      return _vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: data,
      );
    }

    final decoded = await _vaultService.readObject(
      existing.header.objectId,
    );

    if (decoded !=
            null &&
        _mapsEquivalent(
          decoded.data,
          data,
        )) {
      return existing;
    }

    return _vaultService.updateObject(
      objectId: existing.header.objectId,
      type: BrainVaultObjectType.note,
      data: data,
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    List<
      BrainFile
    >
  >
  loadNotes() async {
    await initialize();

    final objects = await _vaultService.loadAllEncryptedObjects();

    final result =
        <
          BrainFile
        >[];

    for (final object in objects) {
      if (object.isDeleted) {
        continue;
      }

      final decoded = await _vaultService.readObject(
        object.header.objectId,
      );

      if (decoded ==
              null ||
          decoded.type !=
              BrainVaultObjectType.note) {
        continue;
      }

      try {
        result.add(
          _fromVaultData(
            decoded.data,
          ),
        );
      } catch (
        _
      ) {
        // Objeto de outro schema de nota.
      }
    }

    result.sort(
      (
        first,
        second,
      ) {
        return second.updatedAt.compareTo(
          first.updatedAt,
        );
      },
    );

    return result;
  }

  Future<
    BrainFile?
  >
  getNoteByPath(
    String path,
  ) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      return null;
    }

    final object = await findEncryptedObjectByPath(
      cleanPath,
    );

    if (object ==
            null ||
        object.isDeleted) {
      return null;
    }

    final decoded = await _vaultService.readObject(
      object.header.objectId,
    );

    if (decoded ==
            null ||
        decoded.type !=
            BrainVaultObjectType.note) {
      return null;
    }

    return _fromVaultData(
      decoded.data,
    );
  }

  // ============================================================
  // FIND RAW
  // ============================================================

  Future<
    BrainVaultObject?
  >
  findEncryptedObjectByPath(
    String path,
  ) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      return null;
    }

    final objects = await _vaultService.loadAllEncryptedObjects();

    for (final object in objects) {
      if (object.isDeleted) {
        continue;
      }

      final decoded = await _vaultService.readObject(
        object.header.objectId,
      );

      if (decoded ==
              null ||
          decoded.type !=
              BrainVaultObjectType.note) {
        continue;
      }

      final objectPath =
          decoded.data['path']?.toString().trim() ??
          '';

      if (objectPath ==
          cleanPath) {
        return object;
      }
    }

    return null;
  }

  Future<
    BrainVaultObject?
  >
  findEncryptedObjectByLegacyRemoteId(
    String remoteId,
  ) async {
    final cleanId = remoteId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final objects = await _vaultService.loadAllEncryptedObjects();

    for (final object in objects) {
      if (object.isDeleted) {
        continue;
      }

      final decoded = await _vaultService.readObject(
        object.header.objectId,
      );

      if (decoded ==
              null ||
          decoded.type !=
              BrainVaultObjectType.note) {
        continue;
      }

      final storedId =
          decoded.data['legacy_remote_id']?.toString().trim() ??
          '';

      if (storedId ==
          cleanId) {
        return object;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE / TOMBSTONE
  // ============================================================

  Future<
    BrainVaultObject?
  >
  deleteNoteByPath(
    String path,
  ) async {
    final object = await findEncryptedObjectByPath(
      path,
    );

    if (object ==
        null) {
      return null;
    }

    return _vaultService.deleteObject(
      object.header.objectId,
    );
  }

  Future<
    BrainVaultObject?
  >
  deleteNoteByLegacyRemoteId(
    String remoteId,
  ) async {
    final object = await findEncryptedObjectByLegacyRemoteId(
      remoteId,
    );

    if (object ==
        null) {
      return null;
    }

    return _vaultService.deleteObject(
      object.header.objectId,
    );
  }

  // ============================================================
  // MAPPER
  // ============================================================

  Map<
    String,
    dynamic
  >
  _toVaultData(
    BrainFile note, {
    String? legacyRemoteId,
  }) {
    final concepts = note.concepts
        .map(
          (
            concept,
          ) {
            return <
              String,
              dynamic
            >{
              'id': concept.id,
              'title': concept.title,
              'description': concept.description,
              'type': concept.type.name,
            };
          },
        )
        .toList(
          growable: false,
        );

    final cleanLegacyRemoteId = legacyRemoteId?.trim();

    return <
      String,
      dynamic
    >{
      'model': 'brain_note',
      'topic': note.topic.trim(),
      'title': note.title.trim(),
      'path': note.path.trim(),
      'content': note.content,
      'concepts': concepts,
      'legacy_remote_id':
          cleanLegacyRemoteId ==
                  null ||
              cleanLegacyRemoteId.isEmpty
          ? null
          : cleanLegacyRemoteId,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };
  }

  BrainFile _fromVaultData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final topic =
        data['topic']?.toString().trim() ??
        '';

    final title =
        data['title']?.toString().trim() ??
        '';

    final path =
        data['path']?.toString().trim() ??
        '';

    final content =
        data['content']?.toString() ??
        '';

    final createdAt = DateTime.tryParse(
      data['created_at']?.toString().trim() ??
          '',
    )?.toLocal();

    final updatedAt = DateTime.tryParse(
      data['updated_at']?.toString().trim() ??
          '',
    )?.toLocal();

    if (title.isEmpty ||
        path.isEmpty ||
        content.trim().isEmpty ||
        updatedAt ==
            null) {
      throw const FormatException(
        'Nota do Vault inválida.',
      );
    }

    final concepts =
        <
          BrainConcept
        >[];

    final rawConcepts = data['concepts'];

    if (rawConcepts
        is Iterable) {
      for (final raw in rawConcepts) {
        if (raw
            is! Map) {
          continue;
        }

        final map =
            Map<
              String,
              dynamic
            >.from(
              raw,
            );

        final id =
            map['id']?.toString().trim() ??
            '';

        final conceptTitle =
            map['title']?.toString().trim() ??
            '';

        final description =
            map['description']?.toString().trim() ??
            '';

        final typeName =
            map['type']?.toString().trim() ??
            '';

        if (id.isEmpty ||
            conceptTitle.isEmpty ||
            description.isEmpty) {
          continue;
        }

        final type = BrainConceptType.values.firstWhere(
          (
            value,
          ) {
            return value.name ==
                typeName;
          },
          orElse: () {
            return BrainConceptType.concept;
          },
        );

        concepts.add(
          BrainConcept(
            id: id,
            title: conceptTitle,
            description: description,
            type: type,
          ),
        );
      }
    }

    return BrainFile(
      topic: topic,
      title: title,
      path: path,
      content: content,
      concepts: concepts,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool _mapsEquivalent(
    Map<
      String,
      dynamic
    >
    first,
    Map<
      String,
      dynamic
    >
    second,
  ) {
    return _deepEqual(
      first,
      second,
    );
  }

  bool _deepEqual(
    dynamic first,
    dynamic second,
  ) {
    if (identical(
      first,
      second,
    )) {
      return true;
    }

    if (first
            is Map &&
        second
            is Map) {
      if (first.length !=
          second.length) {
        return false;
      }

      for (final key in first.keys) {
        if (!second.containsKey(
          key,
        )) {
          return false;
        }

        if (!_deepEqual(
          first[key],
          second[key],
        )) {
          return false;
        }
      }

      return true;
    }

    if (first
            is Iterable &&
        second
            is Iterable) {
      final firstList = first.toList();

      final secondList = second.toList();

      if (firstList.length !=
          secondList.length) {
        return false;
      }

      for (
        var index = 0;
        index <
            firstList.length;
        index++
      ) {
        if (!_deepEqual(
          firstList[index],
          secondList[index],
        )) {
          return false;
        }
      }

      return true;
    }

    return first ==
        second;
  }
}
