import 'package:flutter/material.dart';

class BoardComment {
  BoardComment({
    required this.id,
    required this.dayId,
    required this.message,
    required this.position,
    required this.createdAt,
    this.authorName = 'Você',
    this.resolved = false,
  });

  // ============================================================
  // ID
  // ============================================================

  final String id;

  // ============================================================
  // DIA DA ROTINA
  // ============================================================

  final String dayId;

  // ============================================================
  // CONTEÚDO
  // ============================================================

  String message;

  // ============================================================
  // POSIÇÃO NA LOUSA
  // ============================================================

  Offset position;

  // ============================================================
  // DATA
  // ============================================================

  DateTime createdAt;

  // ============================================================
  // AUTOR
  // ============================================================

  String authorName;

  // ============================================================
  // STATUS
  // ============================================================

  bool resolved;

  // ============================================================
  // COPY WITH
  // ============================================================

  BoardComment copyWith({
    String? message,
    Offset? position,
    DateTime? createdAt,
    String? authorName,
    bool? resolved,
  }) {
    return BoardComment(
      id: id,
      dayId: dayId,
      message:
          message ??
          this.message,
      position:
          position ??
          this.position,
      createdAt:
          createdAt ??
          this.createdAt,
      authorName:
          authorName ??
          this.authorName,
      resolved:
          resolved ??
          this.resolved,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'day_id': dayId,
      'message': message,
      'position_x': position.dx,
      'position_y': position.dy,
      'created_at': createdAt.toIso8601String(),
      'author_name': authorName,
      'resolved': resolved,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory BoardComment.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return BoardComment(
      id:
          map['id']?.toString() ??
          '',
      dayId:
          map['day_id']?.toString() ??
          '',
      message:
          map['message']?.toString() ??
          '',
      position: Offset(
        _toDouble(
          map['position_x'],
        ),
        _toDouble(
          map['position_y'],
        ),
      ),
      createdAt:
          DateTime.tryParse(
            map['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      authorName:
          map['author_name']?.toString().trim().isNotEmpty ==
              true
          ? map['author_name'].toString()
          : 'Você',
      resolved: _toBool(
        map['resolved'],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  static bool _toBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized =
        value?.toString().trim().toLowerCase() ??
        '';

    return normalized ==
            'true' ||
        normalized ==
            '1' ||
        normalized ==
            'yes';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is BoardComment &&
        other.id ==
            id;
  }

  @override
  int get hashCode => id.hashCode;
}
