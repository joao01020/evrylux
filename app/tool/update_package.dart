import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Uso: dart run tool/update_package.dart '
      '<linux|windows> <x64|arm64> <arquivo.tar.gz|arquivo.zip>',
    );
    exit(64);
  }

  final platform = args[0];
  final architecture = args[1];
  final file = File(args[2]);

  if (!{'linux', 'windows'}.contains(platform) ||
      !{'x64', 'arm64'}.contains(architecture)) {
    throw const FormatException('Plataforma ou arquitetura inválida.');
  }

  final expected = platform == 'linux' ? '.tar.gz' : '.zip';
  if (!file.path.toLowerCase().endsWith(expected)) {
    throw FormatException('O pacote deve terminar em $expected.');
  }

  final size = await file.length();
  if (size <= 0) {
    throw const FormatException('Pacote vazio.');
  }

  final sink = Sha256().newHashSink();
  await for (final chunk in file.openRead()) {
    sink.add(chunk);
  }
  sink.close();
  final digest = await sink.hash();
  final sha256 = digest.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'platform': platform,
      'architecture': architecture,
      'format': platform == 'linux' ? 'tar.gz' : 'zip',
      'size': size,
      'sha256': sha256,
    }),
  );
}
