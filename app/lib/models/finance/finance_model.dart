class FinanceModel {
  double invested;

  double monthlyGoal;

  double investmentGoal;

  double bitcoin;

  double ethereum;

  double solana;

  double usdt;

  List<
    bool
  >
  completedDays;

  String? selectedDay;

  FinanceModel({
    this.invested = 0.0,
    this.monthlyGoal = 0.0,
    this.investmentGoal = 0.0,
    this.bitcoin = 0.0,
    this.ethereum = 0.0,
    this.solana = 0.0,
    this.usdt = 0.0,
    List<
      bool
    >?
    completedDays,
    this.selectedDay,
  }) : completedDays =
           completedDays ??
           List.filled(
             7,
             false,
           );
}
