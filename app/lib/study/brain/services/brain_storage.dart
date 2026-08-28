import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';

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

    debugPrint(
      'BrainStorage: pasta das anotações: ${brainDirectory.path}',
    );

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

    final hasExistingPath =
        existingPath !=
            null &&
        existingPath.trim().isNotEmpty;

    final filePath = hasExistingPath
        ? existingPath.trim()
        : '${topicDirectory.path}/${_sanitizeName(cleanTitle)}.md';

    final file = File(
      filePath,
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

      final existsAfterSaving = await file.exists();

      if (!existsAfterSaving) {
        throw const FileSystemException(
          'O arquivo não foi encontrado depois do salvamento.',
        );
      }

      final updatedAt = await file.lastModified();

      debugPrint(
        'BrainStorage: anotação salva em ${file.path}',
      );

      debugPrint(
        'BrainStorage: conceitos salvos: ${conceptsCopy.length}',
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
        'BrainStorage: erro ao salvar ${file.path}',
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

    debugPrint(
      'BrainStorage: iniciando carregamento das anotações.',
    );

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

      debugPrint(
        'BrainStorage: arquivo encontrado: ${entity.path}',
      );

      try {
        final note = await _readFile(
          entity,
        );

        notes.add(
          note,
        );

        debugPrint(
          'BrainStorage: arquivo carregado: ${entity.path}',
        );

        debugPrint(
          'BrainStorage: conceitos carregados: '
          '${note.concepts.length}',
        );
      } catch (
        error,
        stackTrace
      ) {
        debugPrint(
          'BrainStorage: erro ao interpretar ${entity.path}',
        );

        debugPrint(
          'BrainStorage: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );

        final recoveredNote = await _createFallbackNote(
          entity,
        );

        if (recoveredNote !=
            null) {
          notes.add(
            recoveredNote,
          );

          debugPrint(
            'BrainStorage: arquivo recuperado: ${entity.path}',
          );
        }
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

    debugPrint(
      'BrainStorage: total de anotações carregadas: '
      '${notes.length}',
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
      debugPrint(
        'BrainStorage: arquivo não encontrado: $cleanPath',
      );

      throw FileSystemException(
        'A anotação não foi encontrada.',
        cleanPath,
      );
    }

    try {
      final note = await _readFile(
        file,
      );

      debugPrint(
        'BrainStorage: anotação aberta: ${file.path}',
      );

      debugPrint(
        'BrainStorage: conceitos abertos: '
        '${note.concepts.length}',
      );

      return note;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: erro ao abrir ${file.path}',
      );

      debugPrint(
        'BrainStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      final recoveredNote = await _createFallbackNote(
        file,
      );

      if (recoveredNote !=
          null) {
        return recoveredNote;
      }

      rethrow;
    }
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

      debugPrint(
        'BrainStorage: anotação excluída: ${file.path}',
      );
    }

    final parentDirectory = file.parent;

    if (!await parentDirectory.exists()) {
      return;
    }

    final remainingEntities = await parentDirectory.list().toList();

    if (remainingEntities.isEmpty) {
      await parentDirectory.delete();

      debugPrint(
        'BrainStorage: pasta vazia excluída: '
        '${parentDirectory.path}',
      );
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

  // =========================================================
  // RECUPERAR ARQUIVO COM ERRO
  // =========================================================

  Future<
    BrainFile?
  >
  _createFallbackNote(
    File file,
  ) async {
    try {
      if (!await file.exists()) {
        return null;
      }

      final markdown = await file.readAsString(
        encoding: utf8,
      );

      final updatedAt = await file.lastModified();

      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'anotacao.md';

      final fallbackTitle = fileName
          .replaceFirst(
            RegExp(
              r'\.md$',
              caseSensitive: false,
            ),
            '',
          )
          .trim();

      final parentName =
          file.parent.uri.pathSegments.length >=
              2
          ? file.parent.uri.pathSegments[file.parent.uri.pathSegments.length -
                2]
          : 'Sem tema';

      return BrainFile(
        topic: parentName.isEmpty
            ? 'Sem tema'
            : parentName,
        title: fallbackTitle.isEmpty
            ? 'Anotação recuperada'
            : fallbackTitle,
        path: file.path,
        content: markdown.trim(),
        concepts: const [],
        updatedAt: updatedAt,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: não foi possível recuperar ${file.path}',
      );

      debugPrint(
        'BrainStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
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

    return '''---
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
    var normalizedMarkdown = markdown;

    if (normalizedMarkdown.startsWith(
      '\uFEFF',
    )) {
      normalizedMarkdown = normalizedMarkdown.substring(
        1,
      );
    }

    normalizedMarkdown = normalizedMarkdown.replaceAll(
      '\r\n',
      '\n',
    );

    normalizedMarkdown = normalizedMarkdown.replaceAll(
      '\r',
      '\n',
    );

    String topic = 'Sem tema';
    String title = 'Sem título';
    String content = normalizedMarkdown.trim();

    List<
      BrainConcept
    >
    concepts = [];

    final frontMatterExpression = RegExp(
      r'^\s*---\s*\n([\s\S]*?)\n---\s*\n?',
    );

    final frontMatterMatch = frontMatterExpression.firstMatch(
      normalizedMarkdown,
    );

    if (frontMatterMatch !=
        null) {
      final metadataText =
          frontMatterMatch.group(
            1,
          ) ??
          '';

      final metadataLines = metadataText.split(
        '\n',
      );

      for (final line in metadataLines) {
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

      final fullFrontMatter =
          frontMatterMatch.group(
            0,
          ) ??
          '';

      content = normalizedMarkdown
          .replaceFirst(
            fullFrontMatter,
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

      final fullTitle =
          titleMatch.group(
            0,
          ) ??
          '';

      content = content
          .replaceFirst(
            fullTitle,
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

      final fullTopic =
          topicMatch.group(
            0,
          ) ??
          '';

      content = content
          .replaceFirst(
            fullTopic,
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
      final cleanValue = encodedConcepts.trim();

      if (cleanValue.isEmpty) {
        return [];
      }

      final normalizedValue = base64Url.normalize(
        cleanValue,
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
        debugPrint(
          'BrainStorage: os conceitos não estão em uma lista.',
        );

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
          debugPrint(
            'BrainStorage: conceito ignorado por possuir '
            'campos vazios.',
          );

          continue;
        }

        final type = BrainConceptType.values.firstWhere(
          (
            conceptType,
          ) {
            return conceptType.name ==
                typeName;
          },
          orElse: () {
            return BrainConceptType.keep;
          },
        );

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
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: erro ao decodificar conceitos.',
      );

      debugPrint(
        'BrainStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

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
