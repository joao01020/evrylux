import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/storage/user_storage_scope.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';

// ============================================================
// BRAIN STORAGE
// ============================================================
//
// Responsável SOMENTE pela compatibilidade com o armazenamento
// legado legível do Brain.
//
// SEGURANÇA ATUAL:
//
// - o Vault criptografado é a fonte principal para novos dados;
// - este serviço continua capaz de LER/MIGRAR/excluir .md antigos;
// - novas gravações plaintext ficam bloqueadas por padrão;
// - escrita legada só pode ser reativada explicitamente para
//   migração/testes controlados.
//
// O diretório raiz pode vir de:
//
// 1. uma pasta escolhida explicitamente pelo usuário;
// 2. o diretório legado fornecido por UserStorageScope.
//
// IMPORTANTE:
//
// O caminho personalizado representa o ROOT FINAL do Brain.
//
// Exemplo:
//
// Linux:
// /home/joao/Documentos/EVRYLUX/Brain
//
// macOS:
// /Users/brenda/Documents/EVRYLUX/Brain
//
// Portanto este serviço NÃO adiciona novamente:
//
// EVRYLUX/Brain
//
// ao caminho recebido.
//
// ============================================================
//
// SEGURANÇA:
//
// Este diretório NÃO armazena a Master Key.
//
// As chaves criptográficas continuam no armazenamento seguro:
//
// Linux:
// Secret Service / Keyring
//
// macOS:
// Keychain
//
// ============================================================
//
// PERFORMANCE:
//
// O caminho do Brain continua sendo resolvido dinamicamente.
//
// NÃO fazemos cache permanente do Directory porque o usuário
// pode trocar a pasta local durante a execução.
//
// Entretanto:
//
// - o mesmo caminho não é mais impresso dezenas de vezes;
// - subpastas conhecidas são derivadas do root já resolvido;
// - ensureConceptDirectories não resolve o root para cada tipo.
//
// ============================================================

class BrainStorage {
  const BrainStorage({
    required UserStorageScope storageScope,

    // ========================================================
    // CUSTOM ROOT PROVIDER
    // ========================================================
    //
    // Retorna o caminho FINAL escolhido para o Brain.
    //
    // Exemplo:
    //
    // /Users/brenda/Documents/EVRYLUX/Brain
    //
    // Se retornar null ou String vazia, usamos o diretório
    // legado atual, preservando compatibilidade.
    //
    // ========================================================
    Future<
      String?
    >
    Function()?
    localRootPathProvider,

    // ========================================================
    // LEGACY PLAINTEXT WRITES
    // ========================================================
    //
    // false por padrão.
    //
    // Mantido apenas para testes/migrações extremamente
    // controladas. O aplicativo normal deve permanecer com
    // escrita Markdown desabilitada.
    //
    // ========================================================
    bool allowLegacyPlaintextWrites = false,
  }) : _storageScope = storageScope,
       _localRootPathProvider = localRootPathProvider,
       _allowLegacyPlaintextWrites = allowLegacyPlaintextWrites;

  final UserStorageScope _storageScope;

  final Future<
    String?
  >
  Function()?
  _localRootPathProvider;

  final bool _allowLegacyPlaintextWrites;

  // ============================================================
  // CONFIG
  // ============================================================

  static const String _conceptsFolderName = '_concepts';

  static const String _backupFolderName = '_backup';

  // ============================================================
  // DIRECTORY LOG CACHE
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Este cache NÃO guarda o Directory usado pelo Brain.
  //
  // Ele serve SOMENTE para saber se determinada mensagem de log
  // já foi apresentada.
  //
  // Portanto:
  //
  // - trocar a pasta do Brain continua funcionando;
  // - trocar de usuário continua funcionando;
  // - o caminho continua sendo resolvido normalmente;
  // - apenas eliminamos mensagens duplicadas no terminal.
  //
  // Exemplo de chave:
  //
  // legado|/home/user/Documents/.../brain/legacy
  //
  // ============================================================

  static final Set<
    String
  >
  _loggedResolvedDirectories =
      <
        String
      >{};

  bool get allowsLegacyPlaintextWrites {
    return _allowLegacyPlaintextWrites;
  }

  // ============================================================
  // RESOLVE ROOT
  // ============================================================
  //
  // Ordem:
  //
  // 1. tenta usar a pasta escolhida pelo usuário;
  // 2. se nenhuma estiver configurada, usa o diretório legado.
  //
  // O fallback é proposital para manter compatibilidade com:
  //
  // - instalações existentes;
  // - Linux atual;
  // - migrações anteriores;
  // - testes;
  // - inicializações onde o usuário ainda não escolheu pasta.
  //
  // IMPORTANTE:
  //
  // Não mantemos cache permanente deste Directory.
  //
  // Isso permite que alterações de configuração sejam percebidas
  // imediatamente pelo BrainStorage.
  //
  // ============================================================

  Future<
    Directory
  >
  _resolveBrainRootDirectory() async {
    final provider = _localRootPathProvider;

    if (provider !=
        null) {
      try {
        final configuredPath = await provider();

        final cleanPath =
            configuredPath?.trim() ??
            '';

        if (cleanPath.isNotEmpty) {
          final directory = Directory(
            _normalizeDirectoryPath(
              cleanPath,
            ),
          );

          if (!await directory.exists()) {
            await directory.create(
              recursive: true,
            );
          }

          _logResolvedDirectoryOnce(
            kind: 'personalizado',
            directory: directory,
          );

          return directory;
        }
      } catch (
        error,
        stackTrace
      ) {
        debugPrint(
          'BrainStorage: não foi possível resolver '
          'o diretório personalizado.',
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

    final legacyDirectory = await _storageScope.legacyBrainDirectory;

    if (!await legacyDirectory.exists()) {
      await legacyDirectory.create(
        recursive: true,
      );
    }

    _logResolvedDirectoryOnce(
      kind: 'legado',
      directory: legacyDirectory,
    );

    return legacyDirectory;
  }

  // ============================================================
  // LOG RESOLVED DIRECTORY ONCE
  // ============================================================
  //
  // Evita:
  //
  // BrainStorage: usando diretório legado...
  // BrainStorage: usando diretório legado...
  // BrainStorage: usando diretório legado...
  //
  // em toda chamada.
  //
  // Não interfere na resolução real do diretório.
  //
  // ============================================================

  void _logResolvedDirectoryOnce({
    required String kind,
    required Directory directory,
  }) {
    final normalizedPath = _normalizeDirectoryPath(
      directory.absolute.path,
    );

    final key = '$kind|$normalizedPath';

    if (!_loggedResolvedDirectories.add(
      key,
    )) {
      return;
    }

    debugPrint(
      'BrainStorage: usando diretório $kind: '
      '$normalizedPath',
    );
  }

  // ============================================================
  // NORMALIZE DIRECTORY PATH
  // ============================================================

  String _normalizeDirectoryPath(
    String path,
  ) {
    var result = path.trim();

    if (result.isEmpty) {
      return result;
    }

    // Mantemos "/" intacto.
    if (result ==
        Platform.pathSeparator) {
      return result;
    }

    // Windows futuramente:
    // C:\
    if (Platform.isWindows &&
        RegExp(
          r'^[a-zA-Z]:\\$',
        ).hasMatch(
          result,
        )) {
      return result;
    }

    while (result.endsWith(
      Platform.pathSeparator,
    )) {
      result = result.substring(
        0,
        result.length -
            Platform.pathSeparator.length,
      );
    }

    return result;
  }

  // ============================================================
  // ROOT
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Este método é deliberadamente NÃO destrutivo.
  //
  // Ele apenas garante que a estrutura necessária exista.
  //
  // Nenhum dado antigo é apagado automaticamente.
  //
  // Isso é essencial para a Fase 3 de migração, porque o conteúdo
  // legado precisa permanecer intacto até que:
  //
  // 1. seja migrado para o Vault;
  // 2. seja validado;
  // 3. o usuário/sistema decida explicitamente remover o legado.
  //
  // ============================================================

  Future<
    Directory
  >
  getBrainDirectory() async {
    final directory = await _resolveBrainRootDirectory();

    await _ensureStorageStructure(
      directory,
    );

    return directory;
  }

  // ============================================================
  // IS USING CUSTOM DIRECTORY
  // ============================================================

  Future<
    bool
  >
  isUsingCustomDirectory() async {
    final provider = _localRootPathProvider;

    if (provider ==
        null) {
      return false;
    }

    try {
      final path = await provider();

      return path !=
              null &&
          path.trim().isNotEmpty;
    } catch (
      _
    ) {
      return false;
    }
  }

  // ============================================================
  // ENSURE STORAGE STRUCTURE
  // ============================================================
  //
  // Cria somente diretórios ausentes.
  //
  // NUNCA:
  //
  // - apaga notas;
  // - apaga conceitos;
  // - apaga backups;
  // - depende de marker;
  // - interpreta ausência de marker como autorização para reset.
  //
  // ============================================================

  Future<
    void
  >
  _ensureStorageStructure(
    Directory root,
  ) async {
    if (!await root.exists()) {
      await root.create(
        recursive: true,
      );
    }

    final conceptsDirectory = Directory(
      '${root.path}'
      '${Platform.pathSeparator}'
      '$_conceptsFolderName',
    );

    final backupDirectory = Directory(
      '${root.path}'
      '${Platform.pathSeparator}'
      '$_backupFolderName',
    );

    if (!await conceptsDirectory.exists()) {
      await conceptsDirectory.create(
        recursive: true,
      );
    }

    if (!await backupDirectory.exists()) {
      await backupDirectory.create(
        recursive: true,
      );
    }

    for (final type in BrainConceptType.values) {
      final directory = Directory(
        '${conceptsDirectory.path}'
        '${Platform.pathSeparator}'
        '${type.folderName}',
      );

      if (!await directory.exists()) {
        await directory.create(
          recursive: true,
        );
      }
    }
  }

  // ============================================================
  // DELETE ALL CHILDREN
  // ============================================================

  Future<
    void
  >
  _deleteAllChildren(
    Directory root,
  ) async {
    if (!await root.exists()) {
      return;
    }

    final entities = await root
        .list(
          recursive: false,
          followLinks: false,
        )
        .toList();

    for (final entity in entities) {
      try {
        if (entity
            is File) {
          await entity.delete();

          continue;
        }

        if (entity
            is Directory) {
          await entity.delete(
            recursive: true,
          );

          continue;
        }

        await entity.delete(
          recursive: true,
        );
      } catch (
        error,
        stackTrace
      ) {
        debugPrint(
          'BrainStorage: erro removendo dado antigo: '
          '${entity.path}',
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
  }

  // ============================================================
  // CLEAR ALL LOCAL DATA
  // ============================================================
  //
  // Operação DESTRUTIVA e EXPLÍCITA.
  //
  // IMPORTANTE:
  //
  // Agora esta operação limpa o diretório ATUAL do Brain.
  //
  // Isso significa:
  //
  // - pasta personalizada, quando configurada;
  // - pasta legado, quando personalizada não existir.
  //
  // NÃO apagamos automaticamente a outra localização.
  //
  // ============================================================

  Future<
    void
  >
  clearAllLocalData() async {
    final root = await _resolveBrainRootDirectory();

    await _deleteAllChildren(
      root,
    );

    await _ensureStorageStructure(
      root,
    );

    debugPrint(
      'BrainStorage: todos os dados locais foram removidos '
      'por solicitação explícita.',
    );
  }

  // ============================================================
  // DEBUG ROOT PATH
  // ============================================================

  Future<
    String
  >
  getBrainDirectoryPath() async {
    final directory = await getBrainDirectory();

    return directory.path;
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
      '${brain.path}'
      '${Platform.pathSeparator}'
      '$_conceptsFolderName',
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
      '${brain.path}'
      '${Platform.pathSeparator}'
      '$_backupFolderName',
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
      '${root.path}'
      '${Platform.pathSeparator}'
      '${type.folderName}',
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
  //
  // Antes:
  //
  // para cada BrainConceptType
  //     ↓
  // getConceptTypeDirectory
  //     ↓
  // getConceptsDirectory
  //     ↓
  // getBrainDirectory
  //
  // Agora resolvemos a pasta _concepts apenas UMA vez.
  //
  // ============================================================

  Future<
    void
  >
  ensureConceptDirectories() async {
    final root = await getConceptsDirectory();

    for (final type in BrainConceptType.values) {
      final directory = Directory(
        '${root.path}'
        '${Platform.pathSeparator}'
        '${type.folderName}',
      );

      if (!await directory.exists()) {
        await directory.create(
          recursive: true,
        );
      }
    }
  }

  // ============================================================
  // REQUIRE LEGACY PLAINTEXT WRITE
  // ============================================================

  void _requireLegacyPlaintextWrite({
    required String operation,
  }) {
    if (_allowLegacyPlaintextWrites) {
      return;
    }

    throw StateError(
      'BrainStorage bloqueou "$operation" porque novas gravações '
      'Markdown em texto puro estão desabilitadas. '
      'Use o Vault criptografado para persistir dados do Cérebro.',
    );
  }

  // ============================================================
  // SAVE NOTE LOCALLY — LEGACY ONLY
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
    _requireLegacyPlaintextWrite(
      operation: 'saveNote',
    );

    final rawTopic = topic.trim();

    final effectiveTopic = rawTopic.isEmpty
        ? 'Sem tema'
        : rawTopic;

    final cleanTitle = title.trim();

    final cleanContent = content.trim();

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

    final hasExistingPath =
        existingPath !=
            null &&
        existingPath.trim().isNotEmpty &&
        existingPath.toLowerCase().endsWith(
          '.md',
        );

    final path = hasExistingPath
        ? existingPath.trim()
        : '${root.path}'
              '${Platform.pathSeparator}'
              '${_sanitizeName(cleanTitle)}-'
              '${DateTime.now().microsecondsSinceEpoch}.md';

    final file = File(
      path,
    );

    DateTime createdAt = DateTime.now();

    if (await file.exists()) {
      try {
        final previousMarkdown = await file.readAsString(
          encoding: utf8,
        );

        final previousMetadata = _parseMarkdown(
          previousMarkdown,
        );

        createdAt =
            previousMetadata.createdAt ??
            await file.lastModified();
      } catch (
        _
      ) {
        createdAt = await file.lastModified();
      }
    }

    final updatedAt = DateTime.now();

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
      title: cleanTitle,
      content: cleanContent,
      concepts: conceptsCopy,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
        noteTitle: cleanTitle,
        concepts: conceptsCopy,
      );

      final actualUpdatedAt = await file.lastModified();

      debugPrint(
        'BrainStorage: Markdown legado salvo: '
        '${file.path}',
      );

      debugPrint(
        'BrainStorage: criado em: '
        '${createdAt.toIso8601String()}',
      );

      debugPrint(
        'BrainStorage: atualizado em: '
        '${actualUpdatedAt.toIso8601String()}',
      );

      return BrainFile(
        topic: effectiveTopic,
        title: cleanTitle,
        path: file.path,
        content: cleanContent,
        concepts: conceptsCopy,
        createdAt: createdAt,
        updatedAt: actualUpdatedAt,
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
    _requireLegacyPlaintextWrite(
      operation: 'saveBackup',
    );

    topic.trim();

    final directory = await getBackupDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final file = File(
      '${directory.path}'
      '${Platform.pathSeparator}'
      '${_sanitizeName(title)}-$timestamp.md',
    );

    final now = DateTime.now();

    final markdown = _createMarkdown(
      title: title.trim(),
      content: content.trim(),
      concepts: concepts,
      createdAt: now,
      updatedAt: now,
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
    required String noteTitle,
  }) async {
    _requireLegacyPlaintextWrite(
      operation: '_saveConceptFile',
    );

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
      '${directory.path}'
      '${Platform.pathSeparator}'
      '$safeTitle-$safeId.md',
    );

    await file.writeAsString(
      _createConceptMarkdown(
        concept: concept,
        notePath: notePath,
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
revisao_habilitada: ${concept.reviewEnabled}
categoria: ${concept.label}
emoji: ${concept.emoji}
pasta: ${concept.folderName}
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
          'BrainStorage: erro ao carregar conceito local: '
          '$error',
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

      var reviewEnabled = false;

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

            case 'revisao_habilitada':
              reviewEnabled = BrainConcept.parseReviewEnabled(
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
        reviewEnabled: reviewEnabled,
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
          'BrainStorage: erro removendo conceito local: '
          '$error',
        );
      }
    }
  }

  // ============================================================
  // LEGACY READ-ONLY COMPATIBILITY
  // ============================================================
  //
  // loadNotes/openNote/loadAllConcepts continuam disponíveis
  // exclusivamente para:
  //
  // - migração de dados antigos;
  // - recuperação compatível;
  // - validação antes da limpeza do plaintext.
  //
  // Eles não representam mais a fonte principal do Brain.
  //
  // ============================================================

  // ============================================================
  // LOAD NOTES
  // ============================================================
  //
  // PERFORMANCE:
  //
  // O root é resolvido apenas UMA vez neste fluxo.
  //
  // Antes:
  //
  // getBrainDirectory()
  //
  // getConceptsDirectory()
  //   ↓
  // getBrainDirectory()
  //
  // getBackupDirectory()
  //   ↓
  // getBrainDirectory()
  //
  // Agora _concepts e _backup são derivados diretamente do root
  // já resolvido.
  //
  // ============================================================

  Future<
    List<
      BrainFile
    >
  >
  loadNotes() async {
    final root = await getBrainDirectory();

    final conceptsDirectory = Directory(
      '${root.path}'
      '${Platform.pathSeparator}'
      '$_conceptsFolderName',
    );

    final backupDirectory = Directory(
      '${root.path}'
      '${Platform.pathSeparator}'
      '$_backupFolderName',
    );

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
          'BrainStorage: erro ao carregar nota local: '
          '${entity.path}',
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
  // DATAS COM ANOTAÇÕES
  // ============================================================

  Future<
    List<
      DateTime
    >
  >
  loadCreatedDates() async {
    final notes = await loadNotes();

    final datesByKey =
        <
          String,
          DateTime
        >{};

    for (final note in notes) {
      final localCreatedAt = note.createdAt.toLocal();

      final date = DateTime(
        localCreatedAt.year,
        localCreatedAt.month,
        localCreatedAt.day,
      );

      datesByKey[_dateKey(
            date,
          )] =
          date;
    }

    final dates = datesByKey.values.toList();

    dates.sort();

    return List<
      DateTime
    >.unmodifiable(
      dates,
    );
  }

  // ============================================================
  // ANOTAÇÕES CRIADAS EM UMA DATA
  // ============================================================

  Future<
    List<
      BrainFile
    >
  >
  loadNotesCreatedOn(
    DateTime date,
  ) async {
    final notes = await loadNotes();

    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final result = notes.where(
      (
        note,
      ) {
        final createdAt = note.createdAt.toLocal();

        return createdAt.year ==
                normalizedDate.year &&
            createdAt.month ==
                normalizedDate.month &&
            createdAt.day ==
                normalizedDate.day;
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        return second.updatedAt.compareTo(
          first.updatedAt,
        );
      },
    );

    return List<
      BrainFile
    >.unmodifiable(
      result,
    );
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
          '$directoryPath'
          '${Platform.pathSeparator}',
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

    final fileUpdatedAt = await file.lastModified();

    final metadata = _parseMarkdown(
      markdown,
    );

    final createdAt =
        metadata.createdAt ??
        fileUpdatedAt;

    final updatedAt =
        metadata.updatedAt ??
        fileUpdatedAt;

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
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // MARKDOWN
  // ============================================================

  String _createMarkdown({
    required String title,
    required String content,
    required List<
      BrainConcept
    >
    concepts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();

    final effectiveCreatedAt =
        createdAt ??
        now;

    final effectiveUpdatedAt =
        updatedAt ??
        now;

    final encodedConcepts = _encodeConcepts(
      concepts,
    );

    return '''---
titulo: $title
criado_em: ${effectiveCreatedAt.toUtc().toIso8601String()}
atualizado_em: ${effectiveUpdatedAt.toUtc().toIso8601String()}
conceitos: $encodedConcepts
---

# $title

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

    DateTime? createdAt;

    DateTime? updatedAt;

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

          case 'criado_em':
            if (value.isNotEmpty) {
              createdAt = DateTime.tryParse(
                value,
              );
            }

            break;

          case 'atualizado_em':
            if (value.isNotEmpty) {
              updatedAt = DateTime.tryParse(
                value,
              );
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
      final parsedTitle =
          titleMatch
              .group(
                1,
              )
              ?.trim() ??
          '';

      if (parsedTitle.isNotEmpty) {
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
      final parsedTopic =
          topicMatch
              .group(
                1,
              )
              ?.trim() ??
          '';

      if (parsedTopic.isNotEmpty) {
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
      createdAt: createdAt,
      updatedAt: updatedAt,
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
          'review_enabled': concept.reviewEnabled,
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
            reviewEnabled: BrainConcept.parseReviewEnabled(
              data['review_enabled'],
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

  // ============================================================
  // DATE KEY
  // ============================================================

  String _dateKey(
    DateTime date,
  ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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

  final DateTime? createdAt;

  final DateTime? updatedAt;

  const _BrainMarkdownData({
    required this.topic,
    required this.title,
    required this.content,
    required this.concepts,
    this.createdAt,
    this.updatedAt,
  });
}
