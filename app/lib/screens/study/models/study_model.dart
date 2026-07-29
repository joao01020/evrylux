class StudyModel {
  final String day;

  final int minutes;

  StudyModel({
    required this.day,
    required this.minutes,
  });

  factory StudyModel.fromMap(
    String day,
    dynamic value,
  ) {
    return StudyModel(
      day: day,
      minutes: int.parse(
        value.toString(),
      ),
    );
  }
}
