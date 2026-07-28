import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/brain_file.dart';
import '../models/brain_concept.dart';

class BrainStorage {
  static const String _brainFolderName = 'ghost_brain';

  const BrainStorage();

  // =========================================================
  // PASTA PRINCIPAL
  // =========================================================

  Future<
    Directory
  >
  getBrainDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final brainDirectory = Directory(
      '${documentsDirectory.path}/$_brainFolderName',
    );

    if (!await brainDirectory.exists()) {
      await brainDirectory.create(
        recursive: true,
      );
    }

    return brainDirectory;
  }

  // =========================================================
  // SALVAR NOTA
  // =========================================================

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

    final brainDirectory = await getBrainDirectory();

    final topicFolderName = _sanitizeName(
      cleanTopic,
    );

    final topicDirectory = Directory(
      '${brainDirectory.path}/$topicFolderName',
    );

    if (!await topicDirectory.exists()) {
      await topicDirectory.create(
        recursive: true,
      );
    }

    final filePath =
        existingPath !=
                null &&
            existingPath.trim().isNotEmpty
        ? existingPath
        : '${topicDirectory.path}/${_sanitizeName(cleanTitle)}.md';

    final file = File(
      filePath,
    );

    final conceptsCopy =
        List<
          BrainConcept
        >.unmodifiable(
          concepts,
        );

    final markdown = _createMarkdown(
      topic: cleanTopic,
      title: cleanTitle,
      content: cleanContent,
      concepts: conceptsCopy,
    );

    await file.writeAsString(
      markdown,
      flush: true,
    );

    final updatedAt = await file.lastModified();

    return BrainFile(
      topic: cleanTopic,
      title: cleanTitle,
      path: file.path,
      content: cleanContent,
      concepts: conceptsCopy,
      updatedAt: updatedAt,
    );
  }

  // =========================================================
  // CARREGAR NOTAS
  // =========================================================

  Future<
    List<
      BrainFile
    >
  >
  loadNotes() async {
    final brainDirectory = await getBrainDirectory();

    final notes =
        <
          BrainFile
        >[];

    await for (final entity in brainDirectory.list(
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
        final note = await _readFile(
          entity,
        );

        notes.add(
          note,
        );
      } catch (
        _
      ) {
        // Ignora somente o arquivo que não pôde ser lido.
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

  // =========================================================
  // ABRIR NOTA
  // =========================================================

  Future<
    BrainFile
  >
  openNote(
    String path,
  ) async {
    final file = File(
      path,
    );

    if (!await file.exists()) {
      throw const FileSystemException(
        'A anotação não foi encontrada.',
      );
    }

    return _readFile(
      file,
    );
  }

  // =========================================================
  // EXCLUIR NOTA
  // =========================================================

  Future<
    void
  >
  deleteNote(
    BrainFile note,
  ) async {
    final file = File(
      note.path,
    );

    if (await file.exists()) {
      await file.delete();
    }

    final parentDirectory = file.parent;

    if (await parentDirectory.exists()) {
      final remainingFiles = await parentDirectory.list().toList();

      if (remainingFiles.isEmpty) {
        await parentDirectory.delete();
      }
    }
  }

  // =========================================================
  // LEITURA INTERNA
  // =========================================================

  Future<
    BrainFile
  >
  _readFile(
    File file,
  ) async {
    final markdown = await file.readAsString();

    final updatedAt = await file.lastModified();

    final metadata = _parseMarkdown(
      markdown,
    );

    return BrainFile(
      topic: metadata.topic,
      title: metadata.title,
      path: file.path,
      content: metadata.content,
      concepts: metadata.concepts,
      updatedAt: updatedAt,
    );
  }

  // =========================================================
  // CRIAR MARKDOWN
  // =========================================================

  String _createMarkdown({
    required String topic,
    required String title,
    required String content,
    required List<
      BrainConcept
    >
    concepts,
  }) {
    final savedAt = DateTime.now().toIso8601String();

    final encodedConcepts = _encodeConcepts(
      concepts,
    );

    return '''
---
tema: $topic
titulo: $title
atualizado_em: $savedAt
conceitos: $encodedConcepts
---

# $title

**Tema:** $topic

$content
''';
  }

  // =========================================================
  // LER MARKDOWN
  // =========================================================

  _BrainMarkdownData _parseMarkdown(
    String markdown,
  ) {
    String topic = 'Sem tema';
    String title = 'Sem título';
    String content = markdown.trim();

    List<
      BrainConcept
    >
    concepts = [];

    final frontMatterExpression = RegExp(
      r'^---\s*\n([\s\S]*?)\n---\s*\n?',
    );

    final frontMatterMatch = frontMatterExpression.firstMatch(
      markdown,
    );

    if (frontMatterMatch !=
        null) {
      final metadataText =
          frontMatterMatch.group(
            1,
          ) ??
          '';

      for (final line in metadataText.split(
        '\n',
      )) {
        final separatorIndex = line.indexOf(
          ':',
        );

        if (separatorIndex <=
            0) {
          continue;
        }

        final key = line
            .substring(
              0,
              separatorIndex,
            )
            .trim();

        final value = line
            .substring(
              separatorIndex +
                  1,
            )
            .trim();

        if (key ==
                'tema' &&
            value.isNotEmpty) {
          topic = value;
        }

        if (key ==
                'titulo' &&
            value.isNotEmpty) {
          title = value;
        }

        if (key ==
                'conceitos' &&
            value.isNotEmpty) {
          concepts = _decodeConcepts(
            value,
          );
        }
      }

      content = markdown
          .replaceFirst(
            frontMatterMatch.group(
                  0,
                ) ??
                '',
            '',
          )
          .trim();
    }

    final titleExpression = RegExp(
      r'^#\s+(.+)$',
      multiLine: true,
    );

    final titleMatch = titleExpression.firstMatch(
      content,
    );

    if (titleMatch !=
        null) {
      final markdownTitle = titleMatch
          .group(
            1,
          )
          ?.trim();

      if (markdownTitle !=
              null &&
          markdownTitle.isNotEmpty) {
        title = markdownTitle;
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
      r'^\*\*Tema:\*\*\s*(.+)$',
      multiLine: true,
    );

    final topicMatch = topicExpression.firstMatch(
      content,
    );

    if (topicMatch !=
        null) {
      final markdownTopic = topicMatch
          .group(
            1,
          )
          ?.trim();

      if (markdownTopic !=
              null &&
          markdownTopic.isNotEmpty) {
        topic = markdownTopic;
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

  // =========================================================
  // CONVERTER CONCEITOS PARA TEXTO
  // =========================================================

  String _encodeConcepts(
    List<
      BrainConcept
    >
    concepts,
  ) {
    final conceptsData = concepts.map(
      (
        concept,
      ) {
        return {
          'id': concept.id,
          'title': concept.title,
          'description': concept.description,
          'type': concept.type.name,
        };
      },
    ).toList();

    final jsonText = jsonEncode(
      conceptsData,
    );

    final jsonBytes = utf8.encode(
      jsonText,
    );

    return base64Url.encode(
      jsonBytes,
    );
  }

  // =========================================================
  // CONVERTER TEXTO PARA CONCEITOS
  // =========================================================

  List<
    BrainConcept
  >
  _decodeConcepts(
    String encodedConcepts,
  ) {
    try {
      final normalizedValue = base64Url.normalize(
        encodedConcepts.trim(),
      );

      final decodedBytes = base64Url.decode(
        normalizedValue,
      );

      final jsonText = utf8.decode(
        decodedBytes,
      );

      final decodedData = jsonDecode(
        jsonText,
      );

      if (decodedData
          is! List) {
        return [];
      }

      final concepts =
          <
            BrainConcept
          >[];

      for (final item in decodedData) {
        if (item
            is! Map) {
          continue;
        }

        final id =
            item['id']?.toString().trim() ??
            '';

        final title =
            item['title']?.toString().trim() ??
            '';

        final description =
            item['description']?.toString().trim() ??
            '';

        final typeName =
            item['type']?.toString().trim() ??
            '';

        if (id.isEmpty ||
            title.isEmpty ||
            description.isEmpty) {
          continue;
        }

        final type =
            typeName ==
                BrainConceptType.keep.name
            ? BrainConceptType.keep
            : BrainConceptType.memorize;

        concepts.add(
          BrainConcept(
            id: id,
            title: title,
            description: description,
            type: type,
          ),
        );
      }

      return concepts;
    } catch (
      _
    ) {
      return [];
    }
  }

  // =========================================================
  // NOME SEGURO PARA ARQUIVO
  // =========================================================

  String _sanitizeName(
    String value,
  ) {
    var result = value.trim().toLowerCase();

    const replacements = {
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
        character,
        replacement,
      ) {
        result = result.replaceAll(
          character,
          replacement,
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
