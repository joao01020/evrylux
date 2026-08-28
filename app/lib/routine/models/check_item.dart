class CheckItem {
  CheckItem(
    this.text, {
    this.id,
    this.done = false,
  });

  final String? id;
  final String text;

  bool done;

  void toggle() {
    done = !done;
  }

  void complete() {
    done = true;
  }

  void reopen() {
    done = false;
  }

  CheckItem copyWith({
    String? id,
    String? text,
    bool? done,
  }) {
    return CheckItem(
      text ??
          this.text,
      id:
          id ??
          this.id,
      done:
          done ??
          this.done,
    );
  }

  CheckItem copy() {
    return CheckItem(
      text,
      done: done,
    );
  }

  Map<
    String,
    dynamic
  >
  toMap({
    required String blockId,
    int position = 0,
  }) {
    return {
      if (id !=
          null)
        'id': id,
      'block_id': blockId,
      'text': text,
      'completed': done,
      'position': position,
    };
  }

  factory CheckItem.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CheckItem(
      _readString(
        map['text'],
      ),
      id: _readNullableString(
        map['id'],
      ),
      done: _readBool(
        map['completed'] ??
            map['done'],
      ),
    );
  }

  static String _readString(
    Object? value,
  ) {
    return value?.toString() ??
        '';
  }

  static String? _readNullableString(
    Object? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static bool _readBool(
    Object? value,
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

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

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

    if (other
        is! CheckItem) {
      return false;
    }

    if (id !=
            null &&
        other.id !=
            null) {
      return id ==
          other.id;
    }

    return text ==
            other.text &&
        done ==
            other.done;
  }

  @override
  int get hashCode {
    if (id !=
        null) {
      return id.hashCode;
    }

    return Object.hash(
      text,
      done,
    );
  }

  @override
  String toString() {
    return 'CheckItem('
        'id: $id, '
        'text: $text, '
        'done: $done'
        ')';
  }
}
