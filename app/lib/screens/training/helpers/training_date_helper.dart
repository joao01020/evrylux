class TrainingDateHelper {
  const TrainingDateHelper._();

  // =========================================================
  // NOMES DOS DIAS DA SEMANA
  // =========================================================

  static const List<
    String
  >
  weekDays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  // =========================================================
  // NORMALIZAR DATA
  // =========================================================

  static DateTime normalize(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // =========================================================
  // VERIFICAR SE É O MESMO DIA
  // =========================================================

  static bool isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  // =========================================================
  // CHAVE YYYY-MM-DD
  // =========================================================

  static String dateKey(
    DateTime date,
  ) {
    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    return '${date.year}-$month-$day';
  }

  // =========================================================
  // DATA FORMATADA
  // =========================================================

  static String formatDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  // =========================================================
  // HORA FORMATADA
  // =========================================================

  static String formatTime(
    DateTime date,
  ) {
    final hour = date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // =========================================================
  // DATA + HORA
  // =========================================================

  static String formatDateTime(
    DateTime date,
  ) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  // =========================================================
  // NOME DO DIA
  // =========================================================

  static String getDayName(
    DateTime date,
  ) {
    final index =
        date.weekday -
        1;

    if (index <
            0 ||
        index >=
            weekDays.length) {
      return weekDays.first;
    }

    return weekDays[index];
  }

  // =========================================================
  // INÍCIO DA SEMANA
  // =========================================================

  static DateTime startOfWeek(
    DateTime date,
  ) {
    final normalized = normalize(
      date,
    );

    return normalized.subtract(
      Duration(
        days:
            normalized.weekday -
            1,
      ),
    );
  }

  // =========================================================
  // FIM DA SEMANA
  // =========================================================

  static DateTime endOfWeek(
    DateTime date,
  ) {
    return startOfWeek(
      date,
    ).add(
      const Duration(
        days: 6,
      ),
    );
  }

  // =========================================================
  // PRIMEIRO DIA DO MÊS
  // =========================================================

  static DateTime startOfMonth(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      1,
    );
  }

  // =========================================================
  // ÚLTIMO DIA DO MÊS
  // =========================================================

  static DateTime endOfMonth(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month +
          1,
      0,
    );
  }

  // =========================================================
  // MÊS ATUAL
  // =========================================================

  static bool isCurrentMonth(
    DateTime date, {
    DateTime? referenceDate,
  }) {
    final now =
        referenceDate ??
        DateTime.now();

    return date.year ==
            now.year &&
        date.month ==
            now.month;
  }

  // =========================================================
  // DIA DA SEMANA VÁLIDO
  // =========================================================

  static bool isValidWeekday(
    int weekday,
  ) {
    return weekday >=
            DateTime.monday &&
        weekday <=
            DateTime.sunday;
  }

  // =========================================================
  // NORMALIZAR DIAS DA SEMANA
  // =========================================================

  static Set<
    int
  >
  normalizeWeekdays(
    Iterable<
      int
    >
    weekdays,
  ) {
    return weekdays
        .where(
          isValidWeekday,
        )
        .toSet();
  }

  // =========================================================
  // CAPITALIZAR TEXTO
  // =========================================================

  static String capitalize(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  // =========================================================
  // DIAS ENTRE DUAS DATAS
  // =========================================================

  static Iterable<
    DateTime
  >
  daysBetween(
    DateTime start,
    DateTime end,
  ) sync* {
    DateTime current = normalize(
      start,
    );

    final last = normalize(
      end,
    );

    while (!current.isAfter(
      last,
    )) {
      yield current;

      current = current.add(
        const Duration(
          days: 1,
        ),
      );
    }
  }

  // =========================================================
  // VERIFICAR HOJE
  // =========================================================

  static bool isToday(
    DateTime date,
  ) {
    return isSameDay(
      date,
      DateTime.now(),
    );
  }

  // =========================================================
  // VERIFICAR ONTEM
  // =========================================================

  static bool isYesterday(
    DateTime date,
  ) {
    final yesterday = DateTime.now().subtract(
      const Duration(
        days: 1,
      ),
    );

    return isSameDay(
      date,
      yesterday,
    );
  }

  // =========================================================
  // DIAS DA SEMANA ORDENADOS
  // =========================================================

  static List<
    int
  >
  sortWeekdays(
    Iterable<
      int
    >
    weekdays,
  ) {
    final ordered = normalizeWeekdays(
      weekdays,
    ).toList();

    ordered.sort();

    return ordered;
  }

  // =========================================================
  // NOMES DOS DIAS
  // =========================================================

  static List<
    String
  >
  weekdayNames(
    Iterable<
      int
    >
    weekdays,
  ) {
    return sortWeekdays(
      weekdays,
    ).map(
      (
        weekday,
      ) {
        return weekDays[weekday -
            1];
      },
    ).toList();
  }

  // =========================================================
  // TEXTO DOS DIAS
  // =========================================================

  static String weekdaysText(
    Iterable<
      int
    >
    weekdays,
  ) {
    final names = weekdayNames(
      weekdays,
    );

    if (names.isEmpty) {
      return 'Nenhum dia';
    }

    if (names.length ==
        1) {
      return capitalize(
        names.first,
      );
    }

    if (names.length ==
        2) {
      return '${capitalize(names[0])} e ${names[1]}';
    }

    final text = names
        .take(
          names.length -
              1,
        )
        .map(
          capitalize,
        )
        .join(
          ', ',
        );

    return '$text e ${names.last}';
  }
}
