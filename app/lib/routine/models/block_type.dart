import 'package:flutter/material.dart';

enum BlockType {
  tasks,
  note,
  content,
  photo,
  mindMap,
  document;

  // ============================================================
  // LABEL
  // ============================================================

  String get label => switch (this) {
    BlockType.tasks => 'Tarefas',
    BlockType.note => 'Anotação',
    BlockType.content => 'Conteúdo',
    BlockType.photo => 'Foto',
    BlockType.mindMap => 'Mapa mental',
    BlockType.document => 'Documento',
  };

  // ============================================================
  // DEFAULT TITLE
  // ============================================================

  String get defaultTitle => switch (this) {
    BlockType.tasks => 'Tarefas',
    BlockType.note => 'Anotação',
    BlockType.content => 'Conteúdo',
    BlockType.photo => 'Referência visual',
    BlockType.mindMap => 'Mapa mental',
    BlockType.document => 'Documento',
  };

  // ============================================================
  // DIALOG TITLE
  // ============================================================

  String get dialogTitle => switch (this) {
    BlockType.tasks => 'Tarefa',
    BlockType.note => 'Nova anotação',
    BlockType.content => 'Ideia de conteúdo',
    BlockType.photo => 'Adicionar referência visual',
    BlockType.mindMap => 'Ramos do mapa mental',
    BlockType.document => 'Adicionar documento',
  };

  // ============================================================
  // HINT
  // ============================================================

  String get hint => switch (this) {
    BlockType.tasks => 'O que precisa ser feito?',
    BlockType.note => 'Escreva sua ideia ou observação...',
    BlockType.content => 'Título, roteiro ou ideia do que será publicado...',
    BlockType.photo => 'Cole o caminho ou URL da imagem...',
    BlockType.mindMap => 'Digite um ramo por linha...',
    BlockType.document => 'Selecione um arquivo .md, .markdown ou .txt...',
  };

  // ============================================================
  // ICON
  // ============================================================

  IconData get icon => switch (this) {
    BlockType.tasks => Icons.checklist_rounded,
    BlockType.note => Icons.notes_rounded,
    BlockType.content => Icons.movie_creation_outlined,
    BlockType.photo => Icons.image_outlined,
    BlockType.mindMap => Icons.account_tree_outlined,
    BlockType.document => Icons.description_outlined,
  };

  // ============================================================
  // COLOR
  // ============================================================

  Color get color => switch (this) {
    BlockType.tasks => const Color(
      0xFF8BFFB0,
    ),
    BlockType.note => const Color(
      0xFFFFD27A,
    ),
    BlockType.content => const Color(
      0xFFFF7E9D,
    ),
    BlockType.photo => const Color(
      0xFF65C7FF,
    ),
    BlockType.mindMap => const Color(
      0xFFA18CFF,
    ),
    BlockType.document => const Color(
      0xFF6FCF97,
    ),
  };

  // ============================================================
  // DATABASE VALUE
  // ============================================================
  //
  // IMPORTANTE:
  //
  // O enum Flutter se chama "tasks",
  // mas o banco usa "task".
  //
  // Valores esperados no banco:
  //
  // note
  // content
  // photo
  // task
  // mind_map
  // document
  //
  // ============================================================

  String get databaseValue => switch (this) {
    BlockType.tasks => 'task',
    BlockType.note => 'note',
    BlockType.content => 'content',
    BlockType.photo => 'photo',
    BlockType.mindMap => 'mind_map',
    BlockType.document => 'document',
  };

  // ============================================================
  // FROM DATABASE
  // ============================================================

  static BlockType fromDatabase(
    String value,
  ) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(
          '-',
          '_',
        )
        .replaceAll(
          ' ',
          '_',
        );

    return switch (normalized) {
      // Valor atual correto do banco.
      'task' => BlockType.tasks,

      // Compatibilidade com dados antigos.
      'tasks' => BlockType.tasks,

      'note' => BlockType.note,

      'content' => BlockType.content,

      'photo' => BlockType.photo,

      'mind_map' => BlockType.mindMap,

      // Compatibilidade extra.
      'mindmap' => BlockType.mindMap,

      'document' => BlockType.document,

      // Compatibilidade extra para nomes alternativos.
      'doc' => BlockType.document,
      'file' => BlockType.document,

      _ => throw ArgumentError.value(
        value,
        'value',
        'Tipo de bloco inválido',
      ),
    };
  }

  // ============================================================
  // TRY FROM DATABASE
  // ============================================================

  static BlockType? tryFromDatabase(
    Object? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    try {
      return fromDatabase(
        text,
      );
    } catch (
      _
    ) {
      return null;
    }
  }

  // ============================================================
  // FROM DATABASE OR DEFAULT
  // ============================================================

  static BlockType fromDatabaseOrDefault(
    Object? value, {
    BlockType fallback = BlockType.note,
  }) {
    return tryFromDatabase(
          value,
        ) ??
        fallback;
  }

  // ============================================================
  // IS TASK
  // ============================================================

  bool get isTask =>
      this ==
      BlockType.tasks;

  // ============================================================
  // IS NOTE
  // ============================================================

  bool get isNote =>
      this ==
      BlockType.note;

  // ============================================================
  // IS CONTENT
  // ============================================================

  bool get isContent =>
      this ==
      BlockType.content;

  // ============================================================
  // IS PHOTO
  // ============================================================

  bool get isPhoto =>
      this ==
      BlockType.photo;

  // ============================================================
  // IS MIND MAP
  // ============================================================

  bool get isMindMap =>
      this ==
      BlockType.mindMap;

  // ============================================================
  // IS DOCUMENT
  // ============================================================

  bool get isDocument =>
      this ==
      BlockType.document;
}
