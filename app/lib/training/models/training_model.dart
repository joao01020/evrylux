class TrainingModel {
  final String day;

  final String training;

  final int minutes;

  final DateTime date;

  const TrainingModel({
    required this.day,
    required this.training,
    required this.minutes,
    required this.date,
  });

  factory TrainingModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return TrainingModel(
      day:
          map['day']
              as String,
      training:
          map['training']
              as String,
      minutes:
          map['minutes']
              as int,
      date: DateTime.parse(
        map['date']
            as String,
      ),
    );
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'day': day,
      'training': training,
      'minutes': minutes,
      'date': date.toIso8601String(),
    };
  }

  TrainingModel copyWith({
    String? day,
    String? training,
    int? minutes,
    DateTime? date,
  }) {
    return TrainingModel(
      day:
          day ??
          this.day,
      training:
          training ??
          this.training,
      minutes:
          minutes ??
          this.minutes,
      date:
          date ??
          this.date,
    );
  }
}
