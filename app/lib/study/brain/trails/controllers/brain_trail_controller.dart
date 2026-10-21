import 'package:flutter/foundation.dart';

import '../models/brain_trail.dart';
import '../models/brain_trail_node.dart';
import '../repositories/brain_trail_repository.dart';

class BrainTrailController extends ChangeNotifier {
  BrainTrailController({BrainTrailRepository? repository})
    : _repository = repository ?? BrainTrailRepository();

  final BrainTrailRepository _repository;

  BrainTrail? _trail;
  bool _loading = false;
  String? _error;
  int _loadGeneration = 0;
  bool _disposed = false;

  BrainTrail? get trail => _trail;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadForObject({
    required String objectId,
    required Set<String> existingObjectIds,
  }) async {
    final generation = ++_loadGeneration;
    _loading = true;
    _error = null;
    _notifyIfAlive();
    try {
      final result = await _repository.loadForObject(
        objectId,
        existingObjectIds,
      );
      if (_disposed || generation != _loadGeneration) return;
      _trail = result;
    } catch (error) {
      if (_disposed || generation != _loadGeneration) return;
      _error = '$error';
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<BrainTrail> createTrail({
    required String rootObjectId,
    required String name,
    String? ownerId,
  }) async {
    final result = await _repository.create(
      rootObjectId: rootObjectId,
      name: name,
      ownerId: ownerId,
    );
    _setTrail(result);
    return result;
  }

  Future<BrainTrail> renameTrail(String name) async {
    final current = _requireTrail();
    final result = await _repository.renameTrail(current, name);
    _setTrail(result);
    return result;
  }

  Future<BrainTrail> addNode({
    required String parentNodeId,
    required String objectId,
  }) async {
    final current = _requireTrail();
    final result = await _repository.addNode(
      current,
      parentNodeId: parentNodeId,
      objectId: objectId,
    );
    _setTrail(result);
    return result;
  }

  Future<BrainTrail> renameNode(
    BrainTrailNode node,
    String? displayName,
  ) async {
    final current = _requireTrail();
    final result = await _repository.renameNode(
      current,
      nodeId: node.id,
      displayName: displayName,
    );
    _setTrail(result);
    return result;
  }

  Future<BrainTrail> removeBranch(BrainTrailNode node) async {
    if (node.isRoot) {
      throw StateError('A raiz não pode ser desvinculada da própria Trilha.');
    }
    final current = _requireTrail();
    final result = await _repository.removeBranch(current, nodeId: node.id);
    _setTrail(result);
    return result;
  }

  BrainTrail _requireTrail() {
    final current = _trail;
    if (current == null) {
      throw StateError('Nenhuma Trilha carregada.');
    }
    return current;
  }

  void _setTrail(BrainTrail trail) {
    _trail = trail;
    _error = null;
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
