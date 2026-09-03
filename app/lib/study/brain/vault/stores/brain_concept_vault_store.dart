import '../../models/brain_concept.dart';

import '../mappers/brain_concept_vault_mapper.dart';
import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_type.dart';
import '../services/brain_vault_service.dart';

// ============================================================
// BRAIN CONCEPT VAULT STORE
// ============================================================

class BrainConceptVaultStore {
  BrainConceptVaultStore({
    required BrainVaultService vaultService,
    BrainConceptVaultMapper mapper = const BrainConceptVaultMapper(),
  }) : _vaultService = vaultService,
       _mapper = mapper;

  final BrainVaultService _vaultService;
  final BrainConceptVaultMapper _mapper;

  Future<void> initialize() async {
    await _vaultService.getOrCreateVault();
  }

  // ============================================================
  // SAVE / UPSERT
  // ============================================================

  Future<BrainVaultObject> saveConcept({
    required BrainConcept concept,
    String? sourceNotePath,
  }) async {
    await initialize();

    final data = _mapper.toVaultData(
      concept: concept,
      sourceNotePath: sourceNotePath,
    );

    final existing = await findEncryptedObjectByConceptId(concept.id);

    if (existing == null) {
      return _vaultService.createObject(
        type: BrainVaultObjectType.concept,
        data: data,
      );
    }

    final decoded = await _vaultService.readObject(existing.header.objectId);

    if (decoded != null && _deepEqual(decoded.data, data)) {
      return existing;
    }

    return _vaultService.updateObject(
      objectId: existing.header.objectId,
      type: BrainVaultObjectType.concept,
      data: data,
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<List<BrainConcept>> loadConcepts() async {
    await initialize();

    final objects = await _vaultService.loadAllEncryptedObjects();

    final result = <BrainConcept>[];

    for (final object in objects) {
      if (object.isDeleted) {
        continue;
      }

      final decoded = await _vaultService.readObject(object.header.objectId);

      if (decoded == null || decoded.type != BrainVaultObjectType.concept) {
        continue;
      }

      try {
        result.add(_mapper.fromVaultData(decoded.data));
      } catch (_) {
        // Ignora somente objeto incompatível.
      }
    }

    return result;
  }

  Future<List<BrainConcept>> loadConceptsByType(BrainConceptType type) async {
    final concepts = await loadConcepts();

    return concepts
        .where((concept) => concept.type == type)
        .toList(growable: false);
  }

  Future<BrainConcept?> getConcept(String id) async {
    final object = await findEncryptedObjectByConceptId(id);

    if (object == null || object.isDeleted) {
      return null;
    }

    final decoded = await _vaultService.readObject(object.header.objectId);

    if (decoded == null || decoded.type != BrainVaultObjectType.concept) {
      return null;
    }

    return _mapper.fromVaultData(decoded.data);
  }

  // ============================================================
  // FIND RAW
  // ============================================================

  Future<BrainVaultObject?> findEncryptedObjectByConceptId(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final objects = await _vaultService.loadAllEncryptedObjects();

    for (final object in objects) {
      if (object.isDeleted) {
        continue;
      }

      final decoded = await _vaultService.readObject(object.header.objectId);

      if (decoded == null || decoded.type != BrainVaultObjectType.concept) {
        continue;
      }

      final storedId = decoded.data['id']?.toString().trim() ?? '';

      if (storedId == cleanId) {
        return object;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<BrainVaultObject?> deleteConcept(String id) async {
    final object = await findEncryptedObjectByConceptId(id);

    if (object == null) {
      return null;
    }

    return _vaultService.deleteObject(object.header.objectId);
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  bool _deepEqual(dynamic first, dynamic second) {
    if (identical(first, second)) {
      return true;
    }

    if (first is Map && second is Map) {
      if (first.length != second.length) {
        return false;
      }

      for (final key in first.keys) {
        if (!second.containsKey(key)) {
          return false;
        }

        if (!_deepEqual(first[key], second[key])) {
          return false;
        }
      }

      return true;
    }

    if (first is Iterable && second is Iterable) {
      final firstList = first.toList();

      final secondList = second.toList();

      if (firstList.length != secondList.length) {
        return false;
      }

      for (var index = 0; index < firstList.length; index++) {
        if (!_deepEqual(firstList[index], secondList[index])) {
          return false;
        }
      }

      return true;
    }

    return first == second;
  }
}
