class BrainBackupException implements Exception {
  const BrainBackupException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'BrainBackupException: $message';
    }

    return 'BrainBackupException: $message '
        '(cause: $cause)';
  }
}
