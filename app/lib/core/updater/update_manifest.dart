import 'dart:convert';

class ReleaseVersion implements Comparable<ReleaseVersion> {
  ReleaseVersion(String value) : value = value.trim() {
    final match = _pattern.firstMatch(this.value);
    if (match == null) {
      throw const FormatException('Versão SemVer inválida.');
    }
    final pre = match.group(4);
    if (pre != null) {
      for (final part in pre.split('.')) {
        if (RegExp(r'^\d+$').hasMatch(part) &&
            part.length > 1 &&
            part.startsWith('0')) {
          throw const FormatException('Pré-release SemVer inválida.');
        }
      }
    }
    _match = match;
  }

  static final RegExp _pattern = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
    r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
  );

  final String value;
  late final RegExpMatch _match;

  List<BigInt> get _core => [
    BigInt.parse(_match.group(1)!),
    BigInt.parse(_match.group(2)!),
    BigInt.parse(_match.group(3)!),
  ];

  List<String> get _preRelease {
    final raw = _match.group(4);
    return raw == null ? const [] : raw.split('.');
  }

  @override
  int compareTo(ReleaseVersion other) {
    final a = _core;
    final b = other._core;
    for (var i = 0; i < 3; i++) {
      final result = a[i].compareTo(b[i]);
      if (result != 0) return result;
    }

    final preA = _preRelease;
    final preB = other._preRelease;
    if (preA.isEmpty && preB.isEmpty) return 0;
    if (preA.isEmpty) return 1;
    if (preB.isEmpty) return -1;

    final count = preA.length < preB.length ? preA.length : preB.length;
    for (var i = 0; i < count; i++) {
      final left = preA[i];
      final right = preB[i];
      final leftNumeric = RegExp(r'^\d+$').hasMatch(left);
      final rightNumeric = RegExp(r'^\d+$').hasMatch(right);

      if (leftNumeric && rightNumeric) {
        final result = BigInt.parse(left).compareTo(BigInt.parse(right));
        if (result != 0) return result;
      } else if (leftNumeric != rightNumeric) {
        return leftNumeric ? -1 : 1;
      } else {
        final result = left.compareTo(right);
        if (result != 0) return result;
      }
    }
    return preA.length.compareTo(preB.length);
  }
}

class UpdateAsset {
  UpdateAsset.fromMap(
    Map<String, dynamic> map, {
    required Set<String> allowedHosts,
  }) : platform = _string(map, 'platform'),
       architecture = _string(map, 'architecture'),
       format = _string(map, 'format'),
       url = Uri.parse(_string(map, 'url')),
       size = _integer(map, 'size'),
       sha256 = _string(map, 'sha256').toLowerCase() {
    if (!{'linux', 'windows'}.contains(platform)) {
      throw const FormatException('Plataforma não suportada.');
    }
    if (!{'x64', 'arm64'}.contains(architecture)) {
      throw const FormatException('Arquitetura não suportada.');
    }
    final expectedFormat = platform == 'linux' ? 'tar.gz' : 'zip';
    if (format != expectedFormat) {
      throw const FormatException('Formato de pacote inválido.');
    }
    if (!_allowedUrl(url, allowedHosts)) {
      throw const FormatException('URL de atualização não permitida.');
    }
    if (size <= 0 || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException('Tamanho ou SHA-256 inválido.');
    }
  }

  final String platform;
  final String architecture;
  final String format;
  final Uri url;
  final int size;
  final String sha256;

  static bool _allowedUrl(Uri uri, Set<String> allowedHosts) {
    return uri.scheme == 'https' &&
        uri.userInfo.isEmpty &&
        !uri.hasPort &&
        uri.fragment.isEmpty &&
        allowedHosts.contains(uri.host.toLowerCase());
  }

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Campo obrigatório inválido: $key');
    }
    return value.trim();
  }

  static int _integer(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('Campo inteiro inválido: $key');
    }
    return value;
  }
}

class UpdateManifest {
  UpdateManifest.fromMap(
    Map<String, dynamic> map, {
    required Set<String> allowedHosts,
  }) : schema = UpdateAsset._integer(map, 'schema'),
       appId = UpdateAsset._string(map, 'appId'),
       channel = UpdateAsset._string(map, 'channel'),
       version = ReleaseVersion(UpdateAsset._string(map, 'version')),
       publishedAt = DateTime.parse(
         UpdateAsset._string(map, 'publishedAt'),
       ).toUtc(),
       minDataSchema = UpdateAsset._integer(map, 'minDataSchema'),
       maxDataSchema = UpdateAsset._integer(map, 'maxDataSchema'),
       dataSchema = map['dataSchema'] is int ? map['dataSchema'] as int : null,
       assets = _parseAssets(map, allowedHosts) {
    if (schema != 1 || appId != 'evrylux') {
      throw const FormatException('Manifesto incompatível com o EVRYLUX.');
    }
    if (!{'stable', 'beta'}.contains(channel)) {
      throw const FormatException('Canal inválido.');
    }
    if (minDataSchema < 1 ||
        maxDataSchema < minDataSchema ||
        (dataSchema != null && dataSchema! < 1) ||
        assets.isEmpty) {
      throw const FormatException('Compatibilidade ou pacotes inválidos.');
    }
    final identities = <String>{};
    for (final asset in assets) {
      final identity = '${asset.platform}/${asset.architecture}';
      if (!identities.add(identity)) {
        throw const FormatException(
          'Pacote duplicado para a mesma plataforma.',
        );
      }
    }
  }

  final int schema;
  final String appId;
  final String channel;
  final ReleaseVersion version;
  final DateTime publishedAt;
  final int minDataSchema;
  final int maxDataSchema;

  /// Required by the installer; nullable only for legacy read-only tests.
  final int? dataSchema;
  final List<UpdateAsset> assets;

  static List<UpdateAsset> _parseAssets(
    Map<String, dynamic> map,
    Set<String> allowedHosts,
  ) {
    final raw = map['assets'];
    if (raw is! List) {
      throw const FormatException('Lista de pacotes inválida.');
    }
    return raw
        .map((entry) {
          if (entry is! Map<String, dynamic>) {
            throw const FormatException('Pacote inválido.');
          }
          return UpdateAsset.fromMap(entry, allowedHosts: allowedHosts);
        })
        .toList(growable: false);
  }

  UpdateAsset? assetFor({
    required String platform,
    required String architecture,
  }) {
    for (final asset in assets) {
      if (asset.platform == platform && asset.architecture == architecture) {
        return asset;
      }
    }
    return null;
  }

  bool isNewerThan(String installedVersion) =>
      version.compareTo(ReleaseVersion(installedVersion)) > 0;

  bool supportsDataSchema(int currentSchema) =>
      currentSchema >= minDataSchema && currentSchema <= maxDataSchema;

  static UpdateManifest fromJson(
    String json, {
    required Set<String> allowedHosts,
  }) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifesto JSON inválido.');
    }
    return UpdateManifest.fromMap(decoded, allowedHosts: allowedHosts);
  }
}
