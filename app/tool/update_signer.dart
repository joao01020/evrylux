import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) _usage();

  switch (args.first) {
    case 'keygen':
      if (args.length != 3) _usage();
      await _keygen(args[1], args[2]);
      break;
    case 'sign':
      if (args.length != 4) _usage();
      await _sign(args[1], args[2], args[3]);
      break;
    default:
      _usage();
  }
}

Never _usage() {
  stderr.writeln(
    'Uso:\n'
    '  dart run tool/update_signer.dart keygen <chave.json> <keyId>\n'
    '  dart run tool/update_signer.dart sign <chave.json> <manifesto.json> <saida.json>',
  );
  exit(64);
}

Future<void> _keygen(String path, String keyId) async {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(keyId)) {
    throw const FormatException('keyId inválido.');
  }
  final file = File(path);
  if (await file.exists()) {
    throw StateError('O arquivo de chave já existe. Não será sobrescrito.');
  }

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final privateKey = await keyPair.extract();
  final publicKey = await keyPair.extractPublicKey();

  await file.parent.create(recursive: true);
  final contents = jsonEncode({
    'keyId': keyId,
    'seed': base64Encode(privateKey.bytes),
    'publicKey': base64Encode(publicKey.bytes),
  });
  if (Platform.isLinux || Platform.isMacOS) {
    // FileMode has no portable exclusive-create mode.
    // The release operator should invoke this command with umask 077.
    final process = await Process.start('sh', [
      '-c',
      'umask 077; set -C; cat > "\$1"',
      'sh',
      file.path,
    ]);
    process.stdin.write(contents);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('Não foi possível criar a chave privada.');
    }
  } else {
    await file.writeAsString(contents, flush: true);
  }

  if (!Platform.isWindows) {
    final result = await Process.run('chmod', ['600', file.path]);
    if (result.exitCode != 0) {
      stderr.writeln('Atenção: ajuste manualmente as permissões da chave.');
    }
  }

  stdout.writeln('Chave criada em: ${file.path}');
  stdout.writeln('keyId: $keyId');
  stdout.writeln('Chave pública: ${base64Encode(publicKey.bytes)}');
  stdout.writeln(
    'Guarde a chave privada fora do projeto e faça um backup seguro.',
  );
}

Future<void> _sign(
  String keyPath,
  String manifestPath,
  String outputPath,
) async {
  final key =
      jsonDecode(await File(keyPath).readAsString()) as Map<String, dynamic>;

  final keyId = key['keyId'] as String;
  if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(keyId)) {
    throw const FormatException('keyId inválido.');
  }
  final seed = base64Decode(key['seed'] as String);
  if (seed.length != 32) {
    throw const FormatException('Seed Ed25519 inválida.');
  }

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(seed);
  final publicKey = await keyPair.extractPublicKey();
  final expectedPublicKey = base64Decode(key['publicKey'] as String);
  if (!_sameBytes(publicKey.bytes, expectedPublicKey)) {
    throw const FormatException('Chave pública não corresponde à privada.');
  }

  final payload = await File(manifestPath).readAsBytes();
  final signature = await algorithm.sign(payload, keyPair: keyPair);

  final output = File(outputPath);
  if (await output.exists()) {
    throw StateError('O manifesto assinado já existe. Não será sobrescrito.');
  }

  await output.parent.create(recursive: true);
  await output.writeAsString(
    jsonEncode({
      'keyId': keyId,
      'payload': base64Encode(payload),
      'signature': base64Encode(signature.bytes),
    }),
    flush: true,
  );

  stdout.writeln('Manifesto assinado: ${output.path}');
  stdout.writeln('Chave pública: ${base64Encode(publicKey.bytes)}');
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
