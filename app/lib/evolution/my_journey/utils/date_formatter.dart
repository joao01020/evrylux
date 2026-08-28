class DateFormatter {
  // ===============================
  // CHAVE PARA STORAGE
  // Ex: 2026-07-25
  // ===============================

  static String key(
    DateTime date,
  ) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // ===============================
  // DATA HUMANA
  // Ex: 25/07/2026
  // ===============================

  static String readable(
    DateTime date,
  ) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // ===============================
  // DIA DA SEMANA
  // ===============================

  static String weekDay(
    DateTime date,
  ) {
    const days = [
      "Segunda",

      "Terça",

      "Quarta",

      "Quinta",

      "Sexta",

      "Sábado",

      "Domingo",
    ];

    return days[date.weekday -
        1];
  }
}
