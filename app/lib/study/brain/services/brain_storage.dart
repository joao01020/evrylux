import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';

class BrainStorage {
  static const String _brainFolderName = 'ghost_brain';

  static const String _conceptsFolderName = '_concepts';

  const BrainStorage();

  // ============================================================
  // PASTA PRINCIPAL
  // ============================================================

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
      'BrainStorage: pasta principal: ${brainDirectory.path}',
    );

    return brainDirectory;
  }

  // ============================================================
  // PASTA DOS CONCEITOS
  // ============================================================

  Future<
    Directory
  >
  getConceptsDirectory() async {
    final brainDirectory = await getBrainDirectory();

    final directory = Directory(
      '${brainDirectory.path}/$_conceptsFolderName',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // PASTA POR TIPO
  // ============================================================

  Future<
    Directory
  >
  getConceptTypeDirectory(
    BrainConceptType type,
  ) async {
    final conceptsDirectory = await getConceptsDirectory();

    final directory = Directory(
      '${conceptsDirectory.path}/${type.folderName}',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // CRIAR TODAS AS PASTAS
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
  // SALVAR NOTA
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

      if (!await file.exists()) {
        throw const FileSystemException(
          'O arquivo não foi encontrado depois do salvamento.',
        );
      }

      // ========================================================
      // SINCRONIZAR CONCEITOS EM ARQUIVOS INDIVIDUAIS
      // ========================================================

      await _syncConceptFiles(
        notePath: file.path,
        topic: cleanTopic,
        noteTitle: cleanTitle,
        concepts: conceptsCopy,
      );

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

  // ============================================================
  // SALVAR CONCEITOS EM PASTAS
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

    // Remove os arquivos antigos pertencentes à mesma anotação.
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
  // SALVAR UM CONCEITO
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

    final markdown = _createConceptMarkdown(
      concept: concept,
      notePath: notePath,
      topic: topic,
      noteTitle: noteTitle,
    );

    await file.writeAsString(
      markdown,
      encoding: utf8,
      flush: true,
    );

    debugPrint(
      'BrainStorage: ${concept.emoji} '
      '${concept.label} salvo em ${file.path}',
    );

    return file;
  }

  // ============================================================
  // MARKDOWN DO CONCEITO
  // ============================================================

  String _createConceptMarkdown({
    required BrainConcept concept,
    required String notePath,
    required String topic,
    required String noteTitle,
  }) {
    final savedAt = DateTime.now().toIso8601String();

    final encodedSourcePath = base64Url.encode(
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
origem: $encodedSourcePath
atualizado_em: $savedAt
---

# ${concept.emoji} ${concept.title}

${concept.description}
''';
  }

  // ============================================================
  // CARREGAR CONCEITOS POR TIPO
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

    final concepts =
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
          concepts.add(
            concept,
          );
        }
      } catch (
        error
      ) {
        debugPrint(
          'BrainStorage: erro ao carregar conceito '
          '${entity.path}: $error',
        );
      }
    }

    return concepts;
  }

  // ============================================================
  // CARREGAR TODOS OS CONCEITOS
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
  // PARSE DO ARQUIVO DE CONCEITO
  // ============================================================

  BrainConcept? _parseConceptFile(
    String markdown, {
    required BrainConceptType fallbackType,
  }) {
    var id = '';

    var type = fallbackType;

    final metadataExpression = RegExp(
      r'^\s*---\s*\n([\s\S]*?)\n---\s*\n?',
    );

    final metadataMatch = metadataExpression.firstMatch(
      markdown,
    );

    var content = markdown.trim();

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

      content = content
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

    // Remove emoji do começo.
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
  }

  // ============================================================
  // REMOVER ARQUIVOS DE CONCEITOS DA NOTA
  // ============================================================

  Future<
    void
  >
  _deleteConceptFilesForNote(
    String notePath,
  ) async {
    final conceptsDirectory = await getConceptsDirectory();

    if (!await conceptsDirectory.exists()) {
      return;
    }

    final encodedSourcePath = base64Url.encode(
      utf8.encode(
        notePath,
      ),
    );

    await for (final entity in conceptsDirectory.list(
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
          'origem: $encodedSourcePath',
        )) {
          await entity.delete();

          debugPrint(
            'BrainStorage: conceito antigo removido: '
            '${entity.path}',
          );
        }
      } catch (
        error
      ) {
        debugPrint(
          'BrainStorage: erro ao verificar '
          '${entity.path}: $error',
        );
      }
    }
  }

  // ============================================================
  // CARREGAR NOTAS
  // ============================================================

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

    final conceptsDirectory = await getConceptsDirectory();

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

      // Não tratar os arquivos individuais de conceitos
      // como anotações comuns.
      if (_isInsideDirectory(
        entity,
        conceptsDirectory,
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

  // ============================================================
  // VERIFICAR SUBPASTA
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
  // ABRIR NOTA
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
        'A anotação não foi encontrada.',
        cleanPath,
      );
    }

    try {
      return await _readFile(
        file,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainStorage: erro ao abrir ${file.path}',
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

  // ============================================================
  // EXCLUIR NOTA
  // ============================================================

  Future<
    void
  >
  deleteNote(
    BrainFile note,
  ) async {
    // Primeiro remove os conceitos separados.
    await _deleteConceptFilesForNote(
      note.path,
    );

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

    // Não remover a pasta principal do cérebro.
    final brainDirectory = await getBrainDirectory();

    if (parentDirectory.absolute.path ==
        brainDirectory.absolute.path) {
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

  // ============================================================
  // LEITURA INTERNA
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
  // RECUPERAR ARQUIVO COM ERRO
  // ============================================================

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

  // ============================================================
  // CRIAR MARKDOWN DA NOTA
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

  // ============================================================
  // LER MARKDOWN
  // ============================================================

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

    var topic = 'Sem tema';

    var title = 'Sem título';

    var content = normalizedMarkdown.trim();

    var concepts =
        <
          BrainConcept
        >[];

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

      content = normalizedMarkdown
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

  // ============================================================
  // CONVERTER CONCEITOS PARA TEXTO
  // ============================================================

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

  // ============================================================
  // CONVERTER TEXTO PARA CONCEITOS
  // ============================================================

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

        final data =
            Map<
              String,
              dynamic
            >.from(
              item,
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

        final typeName =
            data['type']?.toString().trim() ??
            '';

        if (id.isEmpty ||
            title.isEmpty ||
            description.isEmpty) {
          continue;
        }

        // ======================================================
        // NOVO ENUM + COMPATIBILIDADE COM KEEP / MEMORIZE
        // ======================================================

        final type = BrainConceptTypeExtension.fromString(
          typeName,
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

  // ============================================================
  // NOME SEGURO PARA ARQUIVO
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
