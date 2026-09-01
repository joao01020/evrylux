import 'package:flutter/material.dart';

import '../../models/study_day_summary.dart';

// ============================================================
// STUDY DAY DIALOG
// ============================================================
//
// Exibe:
//
// - tempo estudado;
// - quantidade de anotações;
// - preview das anotações;
// - conteúdo completo ao clicar em uma anotação.
//
// ============================================================

class StudyDayDialog
    extends
        StatelessWidget {
  const StudyDayDialog({
    super.key,
    required this.summary,
  });

  final StudyDaySummary summary;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    void
  >
  show(
    BuildContext context, {
    required StudyDaySummary summary,
  }) {
    return showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _surface,
      constraints: const BoxConstraints(
        maxWidth: 680,
      ),
      builder:
          (
            context,
          ) {
            return StudyDayDialog(
              summary: summary,
            );
          },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(
              context,
            ).size.height *
            0.82,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: _primaryDark,
                    size: 23,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullDate(
                          summary.date,
                        ),
                        style: const TextStyle(
                          color: _text,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      const Text(
                        'Conteúdo registrado neste dia.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

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
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // METRICS
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.timer_outlined,
                    title: 'Tempo estudado',
                    value: _timeText(),
                    subtitle: summary.timeAvailable
                        ? 'Registro da semana atual'
                        : 'Histórico por data ainda não disponível',
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: _MetricCard(
                    icon: Icons.description_outlined,
                    title: 'Anotações',
                    value: '${summary.noteCount}',
                    subtitle:
                        summary.noteCount ==
                            1
                        ? 'anotação salva'
                        : 'anotações salvas',
                  ),
                ),
              ],
            ),

            if (!summary.timeAvailable) ...[
              const SizedBox(
                height: 12,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: _surfaceSoft,
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                  border: Border.all(
                    color: _border,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: _primaryDark,
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        'O tempo de estudo atual ainda é salvo por dia da semana. '
                        'Por isso, em semanas antigas o modal não mostra um valor possivelmente incorreto. '
                        'As anotações continuam sendo encontradas pela data.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // NOTES HEADER
            // ==================================================
            const Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: _primaryDark,
                  size: 20,
                ),

                SizedBox(
                  width: 8,
                ),

                Text(
                  'Anotações do Cérebro',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'Clique em uma anotação para abrir o conteúdo completo.',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // NOTES
            // ==================================================
            if (summary.notes.isEmpty)
              const _EmptyNotes()
            else
              for (final note in summary.notes) ...[
                _NoteCard(
                  note: note,
                  onTap: () {
                    _showFullNote(
                      context,
                      note,
                    );
                  },
                ),

                const SizedBox(
                  height: 8,
                ),
              ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FULL NOTE
  // ============================================================

  static Future<
    void
  >
  _showFullNote(
    BuildContext context,
    StudyDayNote note,
  ) {
    return showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return Dialog(
              backgroundColor: _surface,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 28,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  22,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                  maxHeight: 720,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==========================================
                    // HEADER
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        20,
                        14,
                        14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(
                                13,
                              ),
                            ),
                            child: const Icon(
                              Icons.article_outlined,
                              color: _primaryDark,
                              size: 22,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),

                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  note.topic,
                                  style: const TextStyle(
                                    color: _primaryDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: _border,
                    ),

                    // ==========================================
                    // CONTENT
                    // ==========================================
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          20,
                          22,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: _surfaceSoft,
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                                border: Border.all(
                                  color: _border,
                                ),
                              ),
                              child: SelectableText(
                                note.content.trim().isEmpty
                                    ? 'Sem conteúdo.'
                                    : note.content,
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _NoteDateRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Criada em',
                              date: note.createdAt,
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            _NoteDateRow(
                              icon: Icons.update_rounded,
                              label: 'Atualizada em',
                              date: note.updatedAt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  String _timeText() {
    if (!summary.timeAvailable) {
      return '—';
    }

    if (summary.minutes <=
        0) {
      return '0 min';
    }

    final hours =
        summary.minutes ~/
        60;

    final minutes =
        summary.minutes %
        60;

    if (hours ==
        0) {
      return '$minutes min';
    }

    if (minutes ==
        0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}min';
  }

  // ============================================================
  // DATE
  // ============================================================

  static String _fullDate(
    DateTime date,
  ) {
    const months =
        <
          String
        >[
          'janeiro',
          'fevereiro',
          'março',
          'abril',
          'maio',
          'junho',
          'julho',
          'agosto',
          'setembro',
          'outubro',
          'novembro',
          'dezembro',
        ];

    return '${date.day} de '
        '${months[date.month - 1]} de '
        '${date.year}';
  }

  static String _dateTimeText(
    DateTime date,
  ) {
    final local = date.toLocal();

    final day = local.day.toString().padLeft(
      2,
      '0',
    );

    final month = local.month.toString().padLeft(
      2,
      '0',
    );

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${local.year} • $hour:$minute';
  }
}

// ============================================================
// METRIC CARD
// ============================================================

class _MetricCard
    extends
        StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;

  final String title;

  final String value;

  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 112,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: StudyDayDialog._surfaceSoft,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: StudyDayDialog._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: StudyDayDialog._primaryDark,
            size: 19,
          ),

          const SizedBox(
            height: 9,
          ),

          Text(
            title,
            style: const TextStyle(
              color: StudyDayDialog._muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            value,
            style: const TextStyle(
              color: StudyDayDialog._text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: StudyDayDialog._muted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NOTE CARD
// ============================================================

class _NoteCard
    extends
        StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
  });

  final StudyDayNote note;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          15,
        ),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: StudyDayDialog._surface,
            borderRadius: BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: StudyDayDialog._border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: StudyDayDialog._primary,
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  color: StudyDayDialog._primaryDark,
                  size: 19,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudyDayDialog._text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      note.topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudyDayDialog._primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      note.preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudyDayDialog._muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Padding(
                padding: EdgeInsets.only(
                  top: 10,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: StudyDayDialog._primaryDark,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTE DATE
// ============================================================

class _NoteDateRow
    extends
        StatelessWidget {
  const _NoteDateRow({
    required this.icon,
    required this.label,
    required this.date,
  });

  final IconData icon;

  final String label;

  final DateTime date;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: StudyDayDialog._primaryDark,
          size: 15,
        ),

        const SizedBox(
          width: 7,
        ),

        Text(
          '$label: ',
          style: const TextStyle(
            color: StudyDayDialog._muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),

        Expanded(
          child: Text(
            StudyDayDialog._dateTimeText(
              date,
            ),
            style: const TextStyle(
              color: StudyDayDialog._text,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY NOTES
// ============================================================

class _EmptyNotes
    extends
        StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: StudyDayDialog._surfaceSoft,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: StudyDayDialog._border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.note_alt_outlined,
            color: StudyDayDialog._primaryDark,
            size: 28,
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Nenhuma anotação neste dia',
            style: TextStyle(
              color: StudyDayDialog._text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            'As anotações salvas no Cérebro nesta data aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StudyDayDialog._muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
