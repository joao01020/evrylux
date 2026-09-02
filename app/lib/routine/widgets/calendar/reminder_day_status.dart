enum ReminderDayStatus {
  // ============================================================
  // SEM LEMBRETE
  // ============================================================

  none,

  // ============================================================
  // LEMBRETE ATIVO
  // ============================================================
  //
  // Existe pelo menos um lembrete futuro para este dia.
  //
  // Exemplo:
  //
  // agora: 14:00
  // lembrete: 18:00
  //
  // ============================================================

  active,

  // ============================================================
  // LEMBRETE EXPIRADO
  // ============================================================
  //
  // Todos os lembretes existentes para este dia já passaram.
  //
  // Exemplo:
  //
  // agora: 14:00
  // lembrete: 10:00
  //
  // ============================================================

  expired,

  // ============================================================
  // MISTO
  // ============================================================
  //
  // O mesmo dia possui:
  //
  // - pelo menos um lembrete expirado;
  // - pelo menos um lembrete ainda ativo.
  //
  // Exemplo:
  //
  // agora: 14:00
  //
  // 10:00 -> expirado
  // 18:00 -> ativo
  //
  // ============================================================

  mixed;

  // ============================================================
  // POSSUI QUALQUER LEMBRETE
  // ============================================================

  bool get hasReminder {
    return this !=
        ReminderDayStatus.none;
  }

  // ============================================================
  // POSSUI LEMBRETE ATIVO
  // ============================================================

  bool get hasActive {
    return this ==
            ReminderDayStatus.active ||
        this ==
            ReminderDayStatus.mixed;
  }

  // ============================================================
  // POSSUI LEMBRETE EXPIRADO
  // ============================================================

  bool get hasExpired {
    return this ==
            ReminderDayStatus.expired ||
        this ==
            ReminderDayStatus.mixed;
  }

  // ============================================================
  // SOMENTE ATIVOS
  // ============================================================

  bool get isActiveOnly {
    return this ==
        ReminderDayStatus.active;
  }

  // ============================================================
  // SOMENTE EXPIRADOS
  // ============================================================

  bool get isExpiredOnly {
    return this ==
        ReminderDayStatus.expired;
  }

  // ============================================================
  // POSSUI ATIVO + EXPIRADO
  // ============================================================

  bool get isMixed {
    return this ==
        ReminderDayStatus.mixed;
  }

  // ============================================================
  // NÃO POSSUI LEMBRETE
  // ============================================================

  bool get isEmpty {
    return this ==
        ReminderDayStatus.none;
  }
}
