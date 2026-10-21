import 'models/brain_trail.dart';
import 'models/brain_trail_node.dart';

/// Computes breadcrumbs locally from the E2EE trail graph for future search UI.
/// Returns IDs in root-to-leaf order; resolve their titles from BrainController.notes.
List<String> brainTrailObjectPath(BrainTrail trail, String objectId) {
  final byId = <String, BrainTrailNode>{
    for (final node in trail.nodes) node.id: node,
  };

  BrainTrailNode? current;
  for (final node in trail.nodes) {
    if (node.objectId == objectId) {
      current = node;
      break;
    }
  }

  final result = <String>[];
  final visited = <String>{};
  while (current != null) {
    if (!visited.add(current.id)) {
      throw StateError('Ciclo na Trilha.');
    }
    result.add(current.objectId);
    current = current.parentNodeId == null ? null : byId[current.parentNodeId];
  }
  return result.reversed.toList(growable: false);
}
