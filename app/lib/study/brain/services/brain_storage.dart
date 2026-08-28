import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';

class BrainStorage {
  const BrainStorage();

  // ============================================================
  // CONFIG
  // ============================================================

  static const String _brainFolderName = 'ghost_brain';

  static const String _conceptsFolderName = '_concepts';

  static const String _backupFolderName = '_backup';

  // ============================================================
  // ROOT
  // ============================================================

  Future<
    Directory
  >
  getBrainDirectory() async {
    final documents = await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${documents.path}/$_brainFolderName',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // CONCEPT ROOT
  // ============================================================

  Future<
    Directory
  >
  getConceptsDirectory() async {
    final brain = await getBrainDirectory();

    final directory = Directory(
      '${brain.path}/$_conceptsFolderName',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // BACKUP ROOT
  // ============================================================

  Future<
    Directory
  >
  getBackupDirectory() async {
    final brain = await getBrainDirectory();

    final directory = Directory(
      '${brain.path}/$_backupFolderName',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // TYPE DIRECTORY
  // ============================================================

  Future<
    Directory
  >
  getConceptTypeDirectory(
    BrainConceptType type,
  ) async {
    final root = await getConceptsDirectory();

    final directory = Directory(
      '${root.path}/${type.folderName}',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // ENSURE
  // ============================================================

  Future<
    void
  >
  ensureConceptDirectories() async {
    for (final type in BrainConceptType.values) {
      await getConceptTypeDirectory(
        type,
      );
    }
  }

  // ============================================================
  // SAVE NOTE LOCALLY
  //
  // Agora funciona como backup/cache local.
  // O Supabase deve ser a fonte principal.
  // ============================================================

  Future<
    BrainFile
  >
  saveNote({
    required String topic,
    required String title,
    required String content,
    required List<
      BrainConcept
    >
    concepts,
    String? existingPath,
  }) async {
    final cleanTopic = topic.trim();

    final cleanTitle = title.trim();

    final cleanContent = content.trim();

    if (cleanTopic.isEmpty) {
      throw const FormatException(
        'Informe o tema da anotação.',
      );
    }

    if (cleanTitle.isEmpty) {
      throw const FormatException(
        'Informe o título da anotação.',
      );
    }

    if (cleanContent.isEmpty) {
      throw const FormatException(
        'Escreva algum conteúdo.',
      );
    }

    final root = await getBrainDirectory();

    final topicDirectory = Directory(
      '${root.path}/${_sanitizeName(cleanTopic)}',
    );

    if (!await topicDirectory.exists()) {
      await topicDirectory.create(
        recursive: true,
      );
    }

    final hasExistingPath =
        existingPath !=
            null &&
        existingPath.trim().isNotEmpty &&
        existingPath.toLowerCase().endsWith(
          '.md',
        );

    final path = hasExistingPath
        ? existingPath.trim()
        : '${topicDirectory.path}/${_sanitizeName(cleanTitle)}.md';

    final file = File(
      path,
    );

    final conceptsCopy =
        List<
          BrainConcept
        >.unmodifiable(
          List<
            BrainConcept
          >.from(
            concepts,
          ),
        );

    final markdown = _createMarkdown(
      topic: cleanTopic,
      title: cleanTitle,
      content: cleanContent,
      concepts: conceptsCopy,
    );

    try {
      if (!await file.parent.exists()) {
        await file.parent.create(
          recursive: true,
        );
      }

      await file.writeAsString(
        markdown,
        encoding: utf8,
        flush: true,
      );

      await _syncConceptFiles(
        notePath: file.path,
        topic: cleanTopic,
        noteTitle: cleanTitle,
        concepts: conceptsCopy,
      );

      final updatedAt = await file.lastModified();

      debugPrint(
        'BrainStorage: backup local salvo: ${file.path}',
      );

      return BrainFile(
        topic: cleanTopic,
        title: cleanTitle,
        path: file.path,
        content: cleanContent,
        concepts: conceptsCopy,
        updatedAt: updatedAt,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: erro ao salvar backup local.',
      );

      debugPrint(
        'BrainStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // SAVE BACKUP COPY
  // ============================================================

  Future<
    File
  >
  saveBackup({
    required String topic,
    required String title,
    required String content,
    required List<
      BrainConcept
    >
    concepts,
  }) async {
    final directory = await getBackupDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final file = File(
      '${directory.path}/'
      '${_sanitizeName(title)}-$timestamp.md',
    );

    final markdown = _createMarkdown(
      topic: topic.trim(),
      title: title.trim(),
      content: content.trim(),
      concepts: concepts,
    );

    await file.writeAsString(
      markdown,
      encoding: utf8,
      flush: true,
    );

    return file;
  }

  // ============================================================
  // SYNC CONCEPT FILES
  // ============================================================

  Future<
    void
  >
  _syncConceptFiles({
    required String notePath,
    required String topic,
    required String noteTitle,
    required List<
      BrainConcept
    >
    concepts,
  }) async {
    await ensureConceptDirectories();

    await _deleteConceptFilesForNote(
      notePath,
    );

    for (final concept in concepts) {
      await _saveConceptFile(
        concept: concept,
        notePath: notePath,
        topic: topic,
        noteTitle: noteTitle,
      );
    }
  }

  // ============================================================
  // SAVE ONE CONCEPT
  // ============================================================

  Future<
    File
  >
  _saveConceptFile({
    required BrainConcept concept,
    required String notePath,
    required String topic,
    required String noteTitle,
  }) async {
    final directory = await getConceptTypeDirectory(
      concept.type,
    );

    final safeTitle = _sanitizeName(
      concept.title,
    );

    final safeId = _sanitizeName(
      concept.id,
    );

    final file = File(
      '${directory.path}/$safeTitle-$safeId.md',
    );

    await file.writeAsString(
      _createConceptMarkdown(
        concept: concept,
        notePath: notePath,
        topic: topic,
        noteTitle: noteTitle,
      ),
      encoding: utf8,
      flush: true,
    );

    return file;
  }

  // ============================================================
  // CONCEPT MARKDOWN
  // ============================================================

  String _createConceptMarkdown({
    required BrainConcept concept,
    required String notePath,
    required String topic,
    required String noteTitle,
  }) {
    final encodedSource = base64Url.encode(
      utf8.encode(
        notePath,
      ),
    );

    return '''---
id: ${concept.id}
tipo: ${concept.type.name}
categoria: ${concept.label}
emoji: ${concept.emoji}
pasta: ${concept.folderName}
tema: $topic
anotacao: $noteTitle
origem: $encodedSource
atualizado_em: ${DateTime.now().toIso8601String()}
---

# ${concept.emoji} ${concept.title}

${concept.description}
''';
  }

  // ============================================================
  // LOAD CONCEPTS BY TYPE
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadConceptsByType(
    BrainConceptType type,
  ) async {
    final directory = await getConceptTypeDirectory(
      type,
    );

    final result =
        <
          BrainConcept
        >[];

    await for (final entity in directory.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity
          is! File) {
        continue;
      }

      if (!entity.path.toLowerCase().endsWith(
        '.md',
      )) {
        continue;
      }

      try {
        final markdown = await entity.readAsString(
          encoding: utf8,
        );

        final concept = _parseConceptFile(
          markdown,
          fallbackType: type,
        );

        if (concept !=
            null) {
          result.add(
            concept,
          );
        }
      } catch (
        error
      ) {
        debugPrint(
          'BrainStorage: erro ao carregar conceito local: $error',
        );
      }
    }

    return result;
  }

  // ============================================================
  // LOAD ALL CONCEPTS
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadAllConcepts() async {
    final result =
        <
          BrainConcept
        >[];

    for (final type in BrainConceptType.values) {
      result.addAll(
        await loadConceptsByType(
          type,
        ),
      );
    }

    return result;
  }

  // ============================================================
  // PARSE CONCEPT
  // ============================================================

  BrainConcept? _parseConceptFile(
    String markdown, {
    required BrainConceptType fallbackType,
  }) {
    try {
      var normalized = markdown;

      if (normalized.startsWith(
        '\uFEFF',
      )) {
        normalized = normalized.substring(
          1,
        );
      }

      normalized = normalized
          .replaceAll(
            '\r\n',
            '\n',
          )
          .replaceAll(
            '\r',
            '\n',
          );

      var id = '';

      var type = fallbackType;

      final metadataExpression = RegExp(
        r'^\s*---\s*\n([\s\S]*?)\n---\s*\n?',
      );

      final metadataMatch = metadataExpression.firstMatch(
        normalized,
      );

      var content = normalized.trim();

      if (metadataMatch !=
          null) {
        final metadata =
            metadataMatch.group(
              1,
            ) ??
            '';

        for (final line in metadata.split(
          '\n',
        )) {
          final separator = line.indexOf(
            ':',
          );

          if (separator <=
              0) {
            continue;
          }

          final key = line
              .substring(
                0,
                separator,
              )
              .trim();

          final value = line
              .substring(
                separator +
                    1,
              )
              .trim();

          switch (key) {
            case 'id':
              id = value;
              break;

            case 'tipo':
              type = BrainConceptTypeExtension.fromString(
                value,
              );
              break;
          }
        }

        content = normalized
            .replaceFirst(
              metadataMatch.group(
                    0,
                  ) ??
                  '',
              '',
            )
            .trim();
      }

      final titleExpression = RegExp(
        r'^#\s+(.+?)\s*$',
        multiLine: true,
      );

      final titleMatch = titleExpression.firstMatch(
        content,
      );

      if (titleMatch ==
          null) {
        return null;
      }

      var title =
          titleMatch
              .group(
                1,
              )
              ?.trim() ??
          '';

      for (final conceptType in BrainConceptType.values) {
        if (title.startsWith(
          conceptType.emoji,
        )) {
          title = title
              .substring(
                conceptType.emoji.length,
              )
              .trim();

          break;
        }
      }

      content = content
          .replaceFirst(
            titleMatch.group(
                  0,
                ) ??
                '',
            '',
          )
          .trim();

      if (id.isEmpty) {
        id = DateTime.now().microsecondsSinceEpoch.toString();
      }

      if (title.isEmpty ||
          content.isEmpty) {
        return null;
      }

      return BrainConcept(
        id: id,
        title: title,
        description: content,
        type: type,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: erro ao interpretar conceito.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // ============================================================
  // DELETE CONCEPT FILES FOR NOTE
  // ============================================================

  Future<
    void
  >
  _deleteConceptFilesForNote(
    String notePath,
  ) async {
    final root = await getConceptsDirectory();

    if (!await root.exists()) {
      return;
    }

    final encodedSource = base64Url.encode(
      utf8.encode(
        notePath,
      ),
    );

    await for (final entity in root.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity
          is! File) {
        continue;
      }

      if (!entity.path.toLowerCase().endsWith(
        '.md',
      )) {
        continue;
      }

      try {
        final content = await entity.readAsString(
          encoding: utf8,
        );

        if (content.contains(
          'origem: $encodedSource',
        )) {
          await entity.delete();
        }
      } catch (
        error
      ) {
        debugPrint(
          'BrainStorage: erro removendo conceito local: $error',
        );
      }
    }
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================

  Future<
    List<
      BrainFile
    >
  >
  loadNotes() async {
    final root = await getBrainDirectory();

    final conceptsDirectory = await getConceptsDirectory();

    final backupDirectory = await getBackupDirectory();

    final notes =
        <
          BrainFile
        >[];

    await for (final entity in root.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity
          is! File) {
        continue;
      }

      if (!entity.path.toLowerCase().endsWith(
        '.md',
      )) {
        continue;
      }

      if (_isInsideDirectory(
        entity,
        conceptsDirectory,
      )) {
        continue;
      }

      if (_isInsideDirectory(
        entity,
        backupDirectory,
      )) {
        continue;
      }

      try {
        final note = await _readFile(
          entity,
        );

        notes.add(
          note,
        );
      } catch (
        error,
        stackTrace
      ) {
        debugPrint(
          'BrainStorage: erro ao carregar nota local: ${entity.path}',
        );

        debugPrint(
          '$error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }
    }

    notes.sort(
      (
        first,
        second,
      ) {
        return second.updatedAt.compareTo(
          first.updatedAt,
        );
      },
    );

    return notes;
  }

  // ============================================================
  // INSIDE DIRECTORY
  // ============================================================

  bool _isInsideDirectory(
    File file,
    Directory directory,
  ) {
    final directoryPath = directory.absolute.path;

    final filePath = file.absolute.path;

    return filePath ==
            directoryPath ||
        filePath.startsWith(
          '$directoryPath${Platform.pathSeparator}',
        );
  }

  // ============================================================
  // OPEN
  // ============================================================

  Future<
    BrainFile
  >
  openNote(
    String path,
  ) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      throw const FileSystemException(
        'O caminho da anotação está vazio.',
      );
    }

    final file = File(
      cleanPath,
    );

    if (!await file.exists()) {
      throw FileSystemException(
        'A anotação local não foi encontrada.',
        cleanPath,
      );
    }

    return _readFile(
      file,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  deleteNote(
    BrainFile note,
  ) async {
    final path = note.path.trim();

    if (path.isEmpty) {
      return;
    }

    // ========================================================
    // Só tenta excluir se for realmente um caminho de arquivo.
    //
    // Agora BrainFile.path também pode conter um UUID remoto
    // quando usado pelo BrainController/Supabase.
    // ========================================================

    final file = File(
      path,
    );

    if (!await file.exists()) {
      return;
    }

    await _deleteConceptFilesForNote(
      path,
    );

    await file.delete();

    final parent = file.parent;

    final root = await getBrainDirectory();

    if (parent.absolute.path ==
        root.absolute.path) {
      return;
    }

    try {
      final remaining = await parent.list().toList();

      if (remaining.isEmpty) {
        await parent.delete();
      }
    } catch (
      _
    ) {
      // Sem ação.
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<
    BrainFile
  >
  _readFile(
    File file,
  ) async {
    if (!await file.exists()) {
      throw FileSystemException(
        'O arquivo não existe.',
        file.path,
      );
    }

    final markdown = await file.readAsString(
      encoding: utf8,
    );

    final updatedAt = await file.lastModified();

    final metadata = _parseMarkdown(
      markdown,
    );

    return BrainFile(
      topic: metadata.topic,
      title: metadata.title,
      path: file.path,
      content: metadata.content,
      concepts:
          List<
            BrainConcept
          >.unmodifiable(
            metadata.concepts,
          ),
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // MARKDOWN
  // ============================================================

  String _createMarkdown({
    required String topic,
    required String title,
    required String content,
    required List<
      BrainConcept
    >
    concepts,
  }) {
    final encodedConcepts = _encodeConcepts(
      concepts,
    );

    return '''---
tema: $topic
titulo: $title
atualizado_em: ${DateTime.now().toIso8601String()}
conceitos: $encodedConcepts
---

# $title

**Tema:** $topic

$content
''';
  }

  // ============================================================
  // PARSE NOTE
  // ============================================================

  _BrainMarkdownData _parseMarkdown(
    String markdown,
  ) {
    var normalized = markdown;

    if (normalized.startsWith(
      '\uFEFF',
    )) {
      normalized = normalized.substring(
        1,
      );
    }

    normalized = normalized
        .replaceAll(
          '\r\n',
          '\n',
        )
        .replaceAll(
          '\r',
          '\n',
        );

    var topic = 'Sem tema';

    var title = 'Sem título';

    var content = normalized.trim();

    var concepts =
        <
          BrainConcept
        >[];

    final metadataExpression = RegExp(
      r'^\s*---\s*\n([\s\S]*?)\n---\s*\n?',
    );

    final metadataMatch = metadataExpression.firstMatch(
      normalized,
    );

    if (metadataMatch !=
        null) {
      final metadata =
          metadataMatch.group(
            1,
          ) ??
          '';

      for (final line in metadata.split(
        '\n',
      )) {
        final separator = line.indexOf(
          ':',
        );

        if (separator <=
            0) {
          continue;
        }

        final key = line
            .substring(
              0,
              separator,
            )
            .trim();

        final value = line
            .substring(
              separator +
                  1,
            )
            .trim();

        switch (key) {
          case 'tema':
            if (value.isNotEmpty) {
              topic = value;
            }
            break;

          case 'titulo':
            if (value.isNotEmpty) {
              title = value;
            }
            break;

          case 'conceitos':
            if (value.isNotEmpty) {
              concepts = _decodeConcepts(
                value,
              );
            }
            break;
        }
      }

      content = normalized
          .replaceFirst(
            metadataMatch.group(
                  0,
                ) ??
                '',
            '',
          )
          .trim();
    }

    final titleExpression = RegExp(
      r'^#\s+(.+?)\s*$',
      multiLine: true,
    );

    final titleMatch = titleExpression.firstMatch(
      content,
    );

    if (titleMatch !=
        null) {
      final parsedTitle = titleMatch
          .group(
            1,
          )
          ?.trim();

      if (parsedTitle !=
              null &&
          parsedTitle.isNotEmpty) {
        title = parsedTitle;
      }

      content = content
          .replaceFirst(
            titleMatch.group(
                  0,
                ) ??
                '',
            '',
          )
          .trim();
    }

    final topicExpression = RegExp(
      r'^\*\*Tema:\*\*\s*(.+?)\s*$',
      multiLine: true,
    );

    final topicMatch = topicExpression.firstMatch(
      content,
    );

    if (topicMatch !=
        null) {
      final parsedTopic = topicMatch
          .group(
            1,
          )
          ?.trim();

      if (parsedTopic !=
              null &&
          parsedTopic.isNotEmpty) {
        topic = parsedTopic;
      }

      content = content
          .replaceFirst(
            topicMatch.group(
                  0,
                ) ??
                '',
            '',
          )
          .trim();
    }

    return _BrainMarkdownData(
      topic: topic,
      title: title,
      content: content,
      concepts: concepts,
    );
  }

  // ============================================================
  // ENCODE CONCEPTS
  // ============================================================

  String _encodeConcepts(
    List<
      BrainConcept
    >
    concepts,
  ) {
    final data = concepts.map(
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
    ).toList();

    return base64Url.encode(
      utf8.encode(
        jsonEncode(
          data,
        ),
      ),
    );
  }

  // ============================================================
  // DECODE CONCEPTS
  // ============================================================

  List<
    BrainConcept
  >
  _decodeConcepts(
    String encoded,
  ) {
    try {
      final clean = encoded.trim();

      if (clean.isEmpty) {
        return [];
      }

      final normalized = base64Url.normalize(
        clean,
      );

      final decoded = jsonDecode(
        utf8.decode(
          base64Url.decode(
            normalized,
          ),
        ),
      );

      if (decoded
          is! List) {
        return [];
      }

      final result =
          <
            BrainConcept
          >[];

      for (final raw in decoded) {
        if (raw
            is! Map) {
          continue;
        }

        final data =
            Map<
              String,
              dynamic
            >.from(
              raw,
            );

        final id =
            data['id']?.toString().trim() ??
            '';

        final title =
            data['title']?.toString().trim() ??
            '';

        final description =
            data['description']?.toString().trim() ??
            '';

        if (id.isEmpty ||
            title.isEmpty ||
            description.isEmpty) {
          continue;
        }

        result.add(
          BrainConcept(
            id: id,
            title: title,
            description: description,
            type: BrainConceptTypeExtension.fromString(
              data['type']?.toString(),
            ),
          ),
        );
      }

      return result;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: erro ao decodificar conhecimentos.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return [];
    }
  }

  // ============================================================
  // SANITIZE
  // ============================================================

  String _sanitizeName(
    String value,
  ) {
    var result = value.trim().toLowerCase();

    const replacements =
        <
          String,
          String
        >{
          'á': 'a',
          'à': 'a',
          'ã': 'a',
          'â': 'a',
          'ä': 'a',
          'é': 'e',
          'è': 'e',
          'ê': 'e',
          'ë': 'e',
          'í': 'i',
          'ì': 'i',
          'î': 'i',
          'ï': 'i',
          'ó': 'o',
          'ò': 'o',
          'õ': 'o',
          'ô': 'o',
          'ö': 'o',
          'ú': 'u',
          'ù': 'u',
          'û': 'u',
          'ü': 'u',
          'ç': 'c',
        };

    replacements.forEach(
      (
        from,
        to,
      ) {
        result = result.replaceAll(
          from,
          to,
        );
      },
    );

    result = result
        .replaceAll(
          RegExp(
            r'[^a-z0-9]+',
          ),
          '-',
        )
        .replaceAll(
          RegExp(
            r'-+',
          ),
          '-',
        )
        .replaceAll(
          RegExp(
            r'^-|-$',
          ),
          '',
        );

    if (result.isEmpty) {
      return 'anotacao';
    }

    return result;
  }
}

// ============================================================
// MARKDOWN DATA
// ============================================================

class _BrainMarkdownData {
  final String topic;

  final String title;

  final String content;

  final List<
    BrainConcept
  >
  concepts;

  const _BrainMarkdownData({
    required this.topic,
    required this.title,
    required this.content,
    required this.concepts,
  });
}
