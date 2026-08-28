class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // FIELDS
  // ============================================================

  final String id;

  final String fullName;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasName {
    return fullName.trim().isNotEmpty;
  }

  String get firstName {
    final normalizedName = fullName.trim();

    if (normalizedName.isEmpty) {
      return '';
    }

    return normalizedName
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .first;
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory UserProfile.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return UserProfile(
      id:
          map['id']?.toString() ??
          '',
      fullName:
          map['full_name']?.toString().trim() ??
          '',
      createdAt: _parseDate(
        map['created_at'],
      ),
      updatedAt: _parseDate(
        map['updated_at'],
      ),
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
      'full_name': fullName.trim(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  UserProfile copyWith({
    String? id,
    String? fullName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id:
          id ??
          this.id,
      fullName:
          fullName ??
          this.fullName,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
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
            is UserProfile &&
        other.id ==
            id &&
        other.fullName ==
            fullName &&
        other.createdAt ==
            createdAt &&
        other.updatedAt ==
            updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      createdAt,
      updatedAt,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'UserProfile('
        'id: $id, '
        'fullName: $fullName, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
