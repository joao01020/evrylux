class BrainSyncException implements Exception {
  const BrainSyncException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'BrainSyncException: $message';
    }

    return 'BrainSyncException: $message '
        '(cause: $cause)';
  }
}
