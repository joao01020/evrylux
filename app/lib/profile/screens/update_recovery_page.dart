import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/updater/update_recovery_service.dart';

class UpdateRecoveryPage extends StatefulWidget {
  const UpdateRecoveryPage({super.key});

  @override
  State<UpdateRecoveryPage> createState() => _UpdateRecoveryPageState();
}

class _UpdateRecoveryPageState extends State<UpdateRecoveryPage> {
  final _service = const UpdateRecoveryService();

  List<RecoveryBackup> _backups = const [];
  RecoveryBackup? _selected;
  RecoveryInspection? _inspection;

  bool _busy = false;
  bool _error = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });

    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = 'Não foi possível concluir a operação: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _load() => _run(() async {
    final backups = await _service.listBackups();

    if (!mounted) return;

    setState(() {
      _backups = backups;
      _selected = null;
      _inspection = null;
    });
  });

  Future<void> _inspect(RecoveryBackup backup) => _run(() async {
    final result = await _service.inspect(backup.path);

    if (!mounted) return;

    setState(() {
      _selected = backup;
      _inspection = result;
      _message = 'Verificação concluída: ${result.fileCount} arquivos.';
    });
  });

  /// Abre o seletor nativo de diretórios do Linux.
  ///
  /// Não usa shell nem executa comandos recebidos do usuário.
  /// O caminho escolhido é apenas encaminhado ao serviço de exportação.
  Future<String?> _chooseDirectory() async {
    if (!Platform.isLinux) {
      throw UnsupportedError(
        'A seleção de pastas está disponível somente no Linux.',
      );
    }

    // Primeiro tenta o seletor GTK.
    try {
      final result = await Process.run('zenity', [
        '--file-selection',
        '--directory',
        '--title=Escolha uma pasta para a cópia de recuperação',
      ]);

      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        return path.isEmpty ? null : path;
      }

      // Código 1 normalmente significa que o usuário cancelou.
      if (result.exitCode == 1) return null;

      throw StateError(
        'O seletor de pastas não pôde ser aberto: ${result.stderr}',
      );
    } on ProcessException {
      // Zenity não está instalado; tenta o seletor KDE.
    }

    try {
      final result = await Process.run('kdialog', [
        '--getexistingdirectory',
        '',
        'Escolha uma pasta para a cópia de recuperação',
      ]);

      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        return path.isEmpty ? null : path;
      }

      if (result.exitCode == 1) return null;

      throw StateError(
        'O seletor de pastas não pôde ser aberto: ${result.stderr}',
      );
    } on ProcessException {
      throw StateError(
        'Nenhum seletor de pastas foi encontrado. '
        'Instale zenity ou kdialog para escolher o destino.',
      );
    }
  }

  Future<void> _export() async {
    final backup = _selected;

    if (backup == null || _inspection == null || _busy) {
      return;
    }

    String? parent;

    try {
      parent = await _chooseDirectory();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = error.toString();
        });
      }
      return;
    }

    if (parent == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exportar cópia de recuperação?'),
        content: const Text(
          'Uma pasta nova será criada no local escolhido. '
          'O banco atual não será substituído. A cópia pode conter '
          'informações pessoais e dados protegidos; guarde-a em um local seguro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exportar cópia'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _run(() async {
      final destination = await _service.export(backup.path, parent!);

      if (!mounted) return;

      setState(() {
        _message = 'Cópia criada em: $destination';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backups e recuperação')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Recuperação local', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Verifique backups criados pelo atualizador e exporte uma '
                'cópia sem alterar os dados atuais. A restauração automática '
                'e a mesclagem de dados ainda não estão disponíveis.',
              ),
              const SizedBox(height: 16),

              if (!Platform.isLinux)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Esta etapa está disponível somente no Linux.'),
                  ),
                )
              else ...[
                if (_busy) const LinearProgressIndicator(),

                if (_message != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    _message!,
                    style: TextStyle(
                      color: _error ? theme.colorScheme.error : null,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Atualizar lista'),
                  ),
                ),

                const SizedBox(height: 12),

                if (_backups.isEmpty && !_busy)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhum backup local encontrado.'),
                    ),
                  ),

                for (final backup in _backups)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(backup.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Modificado: ${backup.createdAt.toLocal()}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _inspect(backup),
                                icon: const Icon(Icons.verified_outlined),
                                label: const Text('Verificar'),
                              ),

                              if (_selected?.path == backup.path &&
                                  _inspection != null)
                                FilledButton.icon(
                                  onPressed: _busy ? null : _export,
                                  icon: const Icon(Icons.copy_all_rounded),
                                  label: const Text('Exportar cópia'),
                                ),
                            ],
                          ),

                          if (_selected?.path == backup.path &&
                              _inspection != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_inspection!.fileCount} arquivos • '
                              '${(_inspection!.bytes / 1048576).toStringAsFixed(2)} MB',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              const Text(
                'Os backups podem conter chaves, tokens e outros dados '
                'sensíveis. A verificação confirma a integridade local, '
                'não a autenticidade criptográfica do backup. '
                'Não compartilhe a cópia com terceiros.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
