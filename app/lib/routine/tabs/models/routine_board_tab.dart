import 'dart:math';

class RoutineBoardTab {
  const RoutineBoardTab({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isDefault,
    this.blockIds = const <String>[],
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isDefault;
  final List<String> blockIds;

  RoutineBoardTab copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isDefault,
    List<String>? blockIds,
  }) {
    return RoutineBoardTab(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      blockIds: blockIds ?? this.blockIds,
    );
  }

  factory RoutineBoardTab.fromMap(Map<String, dynamic> map) {
    final rawBlockIds = map['block_ids'];

    return RoutineBoardTab(
      id: map['id']?.toString() ?? '',
      name: (map['name']?.toString().trim().isNotEmpty ?? false)
          ? map['name'].toString().trim()
          : 'Lousa',
      sortOrder: _intValue(map['sort_order']),
      isDefault: map['is_default'] == true,
      blockIds: rawBlockIds is List
          ? rawBlockIds
                .map((value) => value.toString())
                .where((value) => value.trim().isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }

  Map<String, dynamic> toDatabaseMap({
    required String userId,
    required DateTime date,
  }) {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'routine_date': _dateKey(date),
      'name': name.trim().isEmpty ? 'Lousa' : name.trim(),
      'sort_order': sortOrder,
      'is_default': isDefault,
      'block_ids': blockIds,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static RoutineBoardTab localDefault() {
    return const RoutineBoardTab(
      id: '__local_default__',
      name: 'Lousa',
      sortOrder: 0,
      isDefault: true,
    );
  }

  static String createId() {
    final random = Random.secure();
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final a = random.nextInt(0x7fffffff).toRadixString(36);
    final b = random.nextInt(0x7fffffff).toRadixString(36);
    return 'rtab-$now-$a-$b';
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
