class ProfilePreferences {
  const ProfilePreferences({
    required this.compactMode,
    required this.reduceMotion,
    required this.confirmBeforeDelete,
  });

  final bool compactMode;
  final bool reduceMotion;
  final bool confirmBeforeDelete;

  factory ProfilePreferences.defaults() {
    return const ProfilePreferences(
      compactMode: false,
      reduceMotion: false,
      confirmBeforeDelete: true,
    );
  }

  factory ProfilePreferences.fromMetadata(
    Map<String, dynamic> metadata,
  ) {
    final confirm = metadata['confirm_before_delete'];

    return ProfilePreferences(
      compactMode: metadata['ui_compact_mode'] == true,
      reduceMotion: metadata['ui_reduce_motion'] == true,
      confirmBeforeDelete: confirm is bool ? confirm : true,
    );
  }

  Map<String, dynamic> applyToMetadata(
    Map<String, dynamic> metadata,
  ) {
    final result = Map<String, dynamic>.from(metadata);

    result['ui_compact_mode'] = compactMode;
    result['ui_reduce_motion'] = reduceMotion;
    result['confirm_before_delete'] = confirmBeforeDelete;

    return result;
  }
}
