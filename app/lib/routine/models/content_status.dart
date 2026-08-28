enum ContentStatus {
  idea,
  script,
  recording,
  editing,
  published;

  String get label => switch (this) {
    ContentStatus.idea => 'Ideia',
    ContentStatus.script => 'Roteiro',
    ContentStatus.recording => 'Gravação',
    ContentStatus.editing => 'Edição',
    ContentStatus.published => 'Publicado',
  };

  String get databaseValue => switch (this) {
    ContentStatus.idea => 'idea',
    ContentStatus.script => 'script',
    ContentStatus.recording => 'recording',
    ContentStatus.editing => 'editing',
    ContentStatus.published => 'published',
  };

  static ContentStatus fromDatabase(
    String value,
  ) {
    return switch (value) {
      'idea' => ContentStatus.idea,
      'script' => ContentStatus.script,
      'recording' => ContentStatus.recording,
      'editing' => ContentStatus.editing,
      'published' => ContentStatus.published,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Status de conteúdo inválido',
      ),
    };
  }
}
