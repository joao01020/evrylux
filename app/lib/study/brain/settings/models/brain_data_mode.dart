enum BrainDataMode {
  local,
  cloud;

  // ============================================================
  // STORAGE VALUE
  // ============================================================

  String get storageValue {
    return name;
  }

  // ============================================================
  // LABEL
  // ============================================================

  String get label {
    switch (this) {
      case BrainDataMode.local:
        return 'Local';

      case BrainDataMode.cloud:
        return 'Cloud';
    }
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  String get description {
    switch (this) {
      case BrainDataMode.local:
        return 'O Cérebro permanece somente neste dispositivo.';

      case BrainDataMode.cloud:
        return 'O Cérebro continua local-first e pode sincronizar '
            'somente dados criptografados.';
    }
  }

  // ============================================================
  // RULES
  // ============================================================

  bool get allowsCloudSync {
    return this == BrainDataMode.cloud;
  }

  bool get requiresAuthentication {
    return this == BrainDataMode.cloud;
  }

  bool get isLocalOnly {
    return this == BrainDataMode.local;
  }

  // ============================================================
  // PARSE
  // ============================================================

  static BrainDataMode? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final mode in BrainDataMode.values) {
      if (mode.name == normalized) {
        return mode;
      }
    }

    return null;
  }
}
