import 'package:flutter/material.dart';

class TrainingHistoryEntry {
  const TrainingHistoryEntry({
    required this.id,
    required this.title,
    required this.activity,
    required this.date,
    this.subtitle,
    this.durationMinutes,
    this.completed = true,
  });

  final String id;
  final String title;
  final String activity;
  final DateTime date;
  final String? subtitle;
  final int? durationMinutes;
  final bool completed;
}

class TrainingHistoryRecords
    extends
        StatelessWidget {
  const TrainingHistoryRecords({
    super.key,
    required this.entries,
    this.onEdit,
    this.onDelete,
  });

  final List<
    TrainingHistoryEntry
  >
  entries;
  final Future<
    void
  >
  Function(
    TrainingHistoryEntry entry,
  )?
  onEdit;
  final Future<
    void
  >
  Function(
    TrainingHistoryEntry entry,
  )?
  onDelete;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );
  static const Color _soft = Color(
    0xFFF3F8EE,
  );
  static const Color _border = Color(
    0xFFC7DFC9,
  );
  static const Color _primary = Color(
    0xFF3B6939,
  );
  static const Color _text = Color(
    0xFF172019,
  );
  static const Color _muted = Color(
    0xFF68746B,
  );
  static const Color _error = Color(
    0xFFB3261E,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 34,
        ),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: _border,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 34,
              color: _muted,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'Nenhum treino neste período.',
              style: TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 4,
            ),
            Text(
              'Altere o filtro para consultar outros registros.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder:
            (
              _,
              _,
            ) => const Divider(
              height: 1,
              color: _border,
            ),
        itemBuilder:
            (
              context,
              index,
            ) {
              final entry = entries[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        border: Border.all(
                          color: _border,
                        ),
                      ),
                      child: Icon(
                        entry.completed
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                        size: 19,
                        color: _primary,
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
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 3,
                            children: [
                              Text(
                                _formatDate(
                                  entry.date,
                                ),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                entry.activity,
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (entry.durationMinutes !=
                                  null)
                                Text(
                                  '${entry.durationMinutes} min',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          if (entry.subtitle?.trim().isNotEmpty ??
                              false) ...[
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              entry.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onEdit !=
                        null)
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () async => onEdit!(
                          entry,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: _muted,
                        ),
                      ),
                    if (onDelete !=
                        null)
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () async => onDelete!(
                          entry,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: _error,
                        ),
                      ),
                  ],
                ),
              );
            },
      ),
    );
  }

  static String _formatDate(
    DateTime date,
  ) {
    final d = date.day.toString().padLeft(
      2,
      '0',
    );
    final m = date.month.toString().padLeft(
      2,
      '0',
    );
    return '$d/$m/${date.year}';
  }
}
