import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef UserStorageUserIdProvider = String? Function();
typedef UserStorageDirectoryProvider = Future<Directory> Function();

/// Centraliza todos os caminhos locais privados que precisam ser isolados
/// por conta do EVRYLUX.
///
/// Em produção, [userIdProvider] deve apontar para a conta autenticada atual.
/// Em testes, use [UserStorageScope.fixed] com diretórios temporários.
class UserStorageScope {
  UserStorageScope({
    required UserStorageUserIdProvider userIdProvider,
    UserStorageDirectoryProvider? documentsDirectoryProvider,
    UserStorageDirectoryProvider? supportDirectoryProvider,
  }) : _userIdProvider = userIdProvider,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  factory UserStorageScope.fixed({
    required String userId,
    UserStorageDirectoryProvider? documentsDirectoryProvider,
    UserStorageDirectoryProvider? supportDirectoryProvider,
  }) {
    final normalized = _normalizeUserId(userId);

    return UserStorageScope(
      userIdProvider: () => normalized,
      documentsDirectoryProvider: documentsDirectoryProvider,
      supportDirectoryProvider: supportDirectoryProvider,
    );
  }

  final UserStorageUserIdProvider _userIdProvider;
  final UserStorageDirectoryProvider _documentsDirectoryProvider;
  final UserStorageDirectoryProvider _supportDirectoryProvider;

  static const String _rootFolderName = 'evrylux';
  static const String _usersFolderName = 'users';
  static const String _brainFolderName = 'brain';
  static const String _legacyBrainFolderName = 'legacy';
  static const String _reviewsFolderName = 'reviews';
  static const String _vaultFolderName = 'vault';
  static const String _boardsFolderName = 'boards';
  static const String _uiFolderName = 'ui';
  static const String _databaseFileName = 'ghost_core.db';

  /// Usuário ativo neste instante.
  ///
  /// Falha fechada se não houver sessão autenticada. Assim nenhum storage
  /// privado cai silenciosamente em uma pasta global compartilhada.
  String get userId {
    final value = _userIdProvider();

    if (value == null) {
      throw StateError(
        'UserStorageScope indisponível: nenhum usuário autenticado.',
      );
    }

    return _normalizeUserId(value);
  }

  String get safeUserId => _safeSegment(userId);

  Future<Directory> get documentsRoot async {
    final documents = await _documentsDirectoryProvider();

    return _ensureDirectory(
      Directory(
        p.join(
          documents.path,
          _rootFolderName,
          _usersFolderName,
          safeUserId,
        ),
      ),
    );
  }

  Future<Directory> get supportRoot async {
    final support = await _supportDirectoryProvider();

    return _ensureDirectory(
      Directory(
        p.join(
          support.path,
          _rootFolderName,
          _usersFolderName,
          safeUserId,
        ),
      ),
    );
  }

  Future<Directory> get brainDirectory async {
    final root = await documentsRoot;

    return _ensureDirectory(
      Directory(p.join(root.path, _brainFolderName)),
    );
  }

  Future<Directory> get legacyBrainDirectory async {
    final brain = await brainDirectory;

    return _ensureDirectory(
      Directory(p.join(brain.path, _legacyBrainFolderName)),
    );
  }

  Future<Directory> get reviewsDirectory async {
    final brain = await brainDirectory;

    return _ensureDirectory(
      Directory(p.join(brain.path, _reviewsFolderName)),
    );
  }

  Future<Directory> get vaultDirectory async {
    final brain = await brainDirectory;

    return _ensureDirectory(
      Directory(p.join(brain.path, _vaultFolderName)),
    );
  }

  Future<Directory> get boardsDirectory async {
    final root = await documentsRoot;

    return _ensureDirectory(
      Directory(p.join(root.path, _boardsFolderName)),
    );
  }

  Future<Directory> get uiDirectory async {
    final root = await supportRoot;

    return _ensureDirectory(
      Directory(p.join(root.path, _uiFolderName)),
    );
  }

  Future<String> get databasePath async {
    final root = await supportRoot;
    return p.join(root.path, _databaseFileName);
  }

  Future<Directory> _ensureDirectory(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static String _normalizeUserId(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('userId não pode estar vazio.');
    }

    return normalized;
  }

  static String _safeSegment(String value) {
    final normalized = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    if (normalized.isEmpty) {
      throw ArgumentError('Identificador de usuário inválido para caminho.');
    }

    return normalized;
  }
}
