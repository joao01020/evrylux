/// Computes breadcrumbs locally from the E2EE trail graph for future search UI.
/// Returns IDs in root-to-leaf order; resolve their titles from BrainController.notes.
List<String> brainTrailObjectPath(Map<String, dynamic> trail, String objectId) {
  final nodes = (trail['nodes'] as List).cast<Map>();
  final byId = <String, Map>{
    for (final node in nodes) node['id'] as String: node,
  };
  Map? current;
  for (final node in nodes) {
    if (node['object_id'] == objectId) {
      current = node;
      break;
    }
  }
  final result = <String>[];
  final visited = <String>{};
  while (current != null) {
    final nodeId = current['id'] as String;
    if (!visited.add(nodeId)) throw StateError('Ciclo na Trilha.');
    result.add(current['object_id'] as String);
    current = byId[current['parent_node_id']];
  }
  return result.reversed.toList();
}
