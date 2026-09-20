import 'package:flutter/material.dart';

class ReminderDayItem {
  const ReminderDayItem({
    required this.id,
    required this.title,
    required this.message,
    required this.remindAt,
    this.notifyInApp = false,
    this.notifyTelegram = false,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final String id;

  final String title;

  final String message;

  final DateTime remindAt;

  final bool notifyInApp;

  final bool notifyTelegram;

  // ============================================================
  // STATUS
  // ============================================================

  bool get isExpired {
    return !remindAt.toUtc().isAfter(
      DateTime.now().toUtc(),
    );
  }
}

class ReminderDayDialog
    extends
        StatefulWidget {
  const ReminderDayDialog({
    super.key,
    required this.date,
    required this.reminders,
    this.onEdit,
    this.onDelete,
    this.onDeleteExpired,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final DateTime date;

  final List<
    ReminderDayItem
  >
  reminders;

  // ============================================================
  // AÇÕES
  // ============================================================

  final Future<
    void
  >
  Function(
    ReminderDayItem reminder,
  )?
  onEdit;

  final Future<
    bool
  >
  Function(
    ReminderDayItem reminder,
  )?
  onDelete;

  final Future<
    bool
  >
  Function(
    List<
      ReminderDayItem
    >
    reminders,
  )?
  onDeleteExpired;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    void
  >
  show(
    BuildContext context, {
    required DateTime date,
    required List<
      ReminderDayItem
    >
    reminders,
    Future<
      void
    >
    Function(
      ReminderDayItem reminder,
    )?
    onEdit,
    Future<
      bool
    >
    Function(
      ReminderDayItem reminder,
    )?
    onDelete,
    Future<
      bool
    >
    Function(
      List<
        ReminderDayItem
      >
      reminders,
    )?
    onDeleteExpired,
  }) {
    return showDialog<
      void
    >(
      context: context,
      builder:
          (
            context,
          ) {
            return ReminderDayDialog(
              date: date,
              reminders: reminders,
              onEdit: onEdit,
              onDelete: onDelete,
              onDeleteExpired: onDeleteExpired,
            );
          },
    );
  }

  @override
  State<
    ReminderDayDialog
  >
  createState() {
    return _ReminderDayDialogState();
  }
}

class _ReminderDayDialogState
    extends
        State<
          ReminderDayDialog
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF7FBF7,
  );

  static const Color _surfaceStrong = Color(
    0xFFF0F7F1,
  );

  static const Color _border = Color(
    0xFFD7E3D9,
  );

  static const Color _primary = Color(
    0xFF198754,
  );

  static const Color _primarySoft = Color(
    0xFFE8F5EC,
  );

  static const Color _primaryBorder = Color(
    0xFFA9DEA5,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _danger = Color(
    0xFFC43A52,
  );

  static const Color _expiredSurface = Color(
    0xFFF4F5F4,
  );

  static const Color _expiredBorder = Color(
    0xFFD8DDD9,
  );

  static const Color _expiredText = Color(
    0xFF8B938D,
  );

  // ============================================================
  // STATE
  // ============================================================

  late List<
    ReminderDayItem
  >
  _reminders;

  final Set<
    String
  >
  _deletingIds = {};

  bool _deletingExpired = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _reminders =
        List<
          ReminderDayItem
        >.from(
          widget.reminders,
        );

    _sort();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final expired = _reminders.where(
      (
        reminder,
      ) {
        return reminder.isExpired;
      },
    ).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 560,
          maxHeight: 680,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x16000000,
                ),
                blurRadius: 28,
                offset: Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              _buildHeader(
                context,
                _reminders.length,
                expired.length,
              ),

              const Divider(
                height: 1,
                color: _border,
              ),

              // ==================================================
              // CONTEÚDO
              // ==================================================
              Flexible(
                child: _reminders.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(
                          16,
                        ),
                        shrinkWrap: true,
                        itemCount: _reminders.length,
                        separatorBuilder:
                            (
                              _,
                              _,
                            ) {
                              return const SizedBox(
                                height: 10,
                              );
                            },
                        itemBuilder:
                            (
                              context,
                              index,
                            ) {
                              return _buildReminderCard(
                                context,
                                _reminders[index],
                              );
                            },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    int count,
    int expiredCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        12,
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: _primaryBorder,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: _primary,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lembretes do dia',
                  style: TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '${_formatDate(widget.date)} • ${_countText(count)}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (expiredCount >
              0) ...[
            TextButton.icon(
              onPressed: _deletingExpired
                  ? null
                  : () {
                      _deleteExpired(
                        context,
                      );
                    },
              style: TextButton.styleFrom(
                foregroundColor: _danger,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              icon: _deletingExpired
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _danger,
                      ),
                    )
                  : const Icon(
                      Icons.delete_sweep_outlined,
                      size: 17,
                    ),
              label: Text(
                _deletingExpired
                    ? 'Excluindo'
                    : 'Excluir expirados',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(
              width: 4,
            ),
          ],

          IconButton(
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.of(
                context,
              ).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
              color: _muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 42,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: _muted,
            size: 36,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Nenhum lembrete para este dia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'Os lembretes programados aparecem aqui e podem ser removidos quando expirarem.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DO LEMBRETE
  // ============================================================

  Widget _buildReminderCard(
    BuildContext context,
    ReminderDayItem reminder,
  ) {
    final expired = reminder.isExpired;

    final deleting = _deletingIds.contains(
      reminder.id,
    );

    final foreground = expired
        ? _expiredText
        : _primary;

    final surface = expired
        ? _expiredSurface
        : _surface;

    final surfaceStrong = expired
        ? const Color(
            0xFFECEFED,
          )
        : _surfaceStrong;

    final border = expired
        ? _expiredBorder
        : _border;

    final timeBorder = expired
        ? _expiredBorder
        : _primaryBorder;

    return AnimatedOpacity(
      duration: const Duration(
        milliseconds: 160,
      ),
      opacity: deleting
          ? .45
          : 1,
      child: IgnorePointer(
        ignoring: deleting,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====================================================
                // HORÁRIO
                // ====================================================
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceStrong,
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color: timeBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(
                          reminder.remindAt,
                        ),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Icon(
                        expired
                            ? Icons.history_rounded
                            : Icons.schedule_rounded,
                        color: foreground,
                        size: 13,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // ====================================================
                // CONTEÚDO
                // ====================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.title.trim().isEmpty
                                  ? 'Lembrete'
                                  : reminder.title.trim(),
                              style: TextStyle(
                                color: expired
                                    ? _expiredText
                                    : _text,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          _StatusChip(
                            expired: expired,
                          ),
                        ],
                      ),

                      if (reminder.message.trim().isNotEmpty) ...[
                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          reminder.message.trim(),
                          style: TextStyle(
                            color: expired
                                ? _expiredText
                                : _muted,
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      if (reminder.notifyInApp ||
                          reminder.notifyTelegram) ...[
                        const SizedBox(
                          height: 9,
                        ),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (reminder.notifyInApp)
                              _ChannelChip(
                                icon: Icons.notifications_none_rounded,
                                label: 'App',
                                expired: expired,
                              ),

                            if (reminder.notifyTelegram)
                              _ChannelChip(
                                icon: Icons.send_rounded,
                                label: 'Telegram',
                                expired: expired,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ====================================================
                // EXCLUIR
                // ====================================================
                if (widget.onDelete !=
                    null)
                  IconButton(
                    tooltip: 'Excluir lembrete',
                    onPressed: () {
                      _deleteOne(
                        context,
                        reminder,
                      );
                    },
                    icon: deleting
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _danger,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline_rounded,
                            color: _danger,
                            size: 19,
                          ),
                  )
                else if (widget.onEdit !=
                    null)
                  IconButton(
                    tooltip: 'Editar lembrete',
                    onPressed: () {
                      widget.onEdit!(
                        reminder,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _muted,
                      size: 19,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXCLUIR UM
  // ============================================================

  Future<
    void
  >
  _deleteOne(
    BuildContext context,
    ReminderDayItem reminder,
  ) async {
    final callback = widget.onDelete;

    if (callback ==
        null) {
      return;
    }

    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir lembrete?',
      message: '“${reminder.title.trim().isEmpty ? 'Lembrete' : reminder.title.trim()}” será removido definitivamente.',
      confirmText: 'Excluir',
    );

    if (confirmed !=
        true) {
      return;
    }

    setState(
      () {
        _deletingIds.add(
          reminder.id,
        );
      },
    );

    var deleted = false;

    try {
      deleted = await callback(
        reminder,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _deletingIds.remove(
              reminder.id,
            );

            if (deleted) {
              _reminders.removeWhere(
                (
                  item,
                ) {
                  return item.id ==
                      reminder.id;
                },
              );
            }
          },
        );
      }
    }
  }

  // ============================================================
  // EXCLUIR EXPIRADOS
  // ============================================================

  Future<
    void
  >
  _deleteExpired(
    BuildContext context,
  ) async {
    final expired = _reminders.where(
      (
        reminder,
      ) {
        return reminder.isExpired;
      },
    ).toList();

    if (expired.isEmpty) {
      return;
    }

    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir lembretes expirados?',
      message:
          expired.length ==
              1
          ? '1 lembrete expirado será removido definitivamente.'
          : '${expired.length} lembretes expirados serão removidos definitivamente.',
      confirmText: 'Excluir expirados',
    );

    if (confirmed !=
        true) {
      return;
    }

    setState(
      () {
        _deletingExpired = true;
      },
    );

    var deleted = false;

    try {
      final callback = widget.onDeleteExpired;

      if (callback !=
          null) {
        deleted = await callback(
          expired,
        );
      } else {
        final deleteOne = widget.onDelete;

        if (deleteOne ==
            null) {
          return;
        }

        deleted = true;

        for (final reminder in expired) {
          final result = await deleteOne(
            reminder,
          );

          if (!result) {
            deleted = false;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _deletingExpired = false;

            if (deleted) {
              final ids = expired.map(
                (
                  reminder,
                ) {
                  return reminder.id;
                },
              ).toSet();

              _reminders.removeWhere(
                (
                  reminder,
                ) {
                  return ids.contains(
                    reminder.id,
                  );
                },
              );
            }
          },
        );
      }
    }
  }

  // ============================================================
  // CONFIRMAR EXCLUSÃO
  // ============================================================

  Future<
    bool?
  >
  _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<
      bool
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              backgroundColor: _background,
              title: Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                message,
                style: const TextStyle(
                  color: _muted,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(
                      false,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(
                      true,
                    );
                  },
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sort() {
    _reminders.sort(
      (
        a,
        b,
      ) {
        return a.remindAt.compareTo(
          b.remindAt,
        );
      },
    );
  }

  // ============================================================
  // DATA
  // ============================================================

  static String _formatDate(
    DateTime value,
  ) {
    final day = value.day.toString().padLeft(
      2,
      '0',
    );

    final month = value.month.toString().padLeft(
      2,
      '0',
    );

    final year = value.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // HORÁRIO
  // ============================================================

  static String _formatTime(
    DateTime value,
  ) {
    final brasilia = value.toUtc().subtract(
      const Duration(
        hours: 3,
      ),
    );

    final hour = brasilia.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = brasilia.minute.toString().padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // ============================================================
  // CONTAGEM
  // ============================================================

  static String _countText(
    int count,
  ) {
    if (count ==
        0) {
      return 'nenhum alerta';
    }

    if (count ==
        1) {
      return '1 alerta';
    }

    return '$count alertas';
  }
}

// ============================================================
// STATUS
// ============================================================

class _StatusChip
    extends
        StatelessWidget {
  const _StatusChip({
    required this.expired,
  });

  final bool expired;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: expired
            ? const Color(
                0xFFE9ECEA,
              )
            : const Color(
                0xFFE8F5EC,
              ),
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: expired
              ? const Color(
                  0xFFD3D8D4,
                )
              : const Color(
                  0xFFA9DEA5,
                ),
        ),
      ),
      child: Text(
        expired
            ? 'Expirado'
            : 'Programado',
        style: TextStyle(
          color: expired
              ? const Color(
                  0xFF858D87,
                )
              : const Color(
                  0xFF347A3D,
                ),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// CHIP DE CANAL
// ============================================================

class _ChannelChip
    extends
        StatelessWidget {
  const _ChannelChip({
    required this.icon,
    required this.label,
    required this.expired,
  });

  final IconData icon;

  final String label;

  final bool expired;

  @override
  Widget build(
    BuildContext context,
  ) {
    final foreground = expired
        ? const Color(
            0xFF858D87,
          )
        : const Color(
            0xFF198754,
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: expired
            ? const Color(
                0xFFE9ECEA,
              )
            : const Color(
                0xFFE8F5EC,
              ),
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: expired
              ? const Color(
                  0xFFD3D8D4,
                )
              : const Color(
                  0xFFA9DEA5,
                ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 12,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
