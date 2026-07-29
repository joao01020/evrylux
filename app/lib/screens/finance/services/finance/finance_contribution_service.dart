import '../../models/finance_model.dart';
import '../history/investment_history.dart';

class FinanceContributionService {
  const FinanceContributionService();

  void addContribution({
    required FinanceModel model,
    required double contribution,
  }) {
    model.invested += contribution;
    model.totalInvested += contribution;
    model.investedMonths += 1;
    model.patrimony += contribution;

    _updateAverageContribution(
      model,
    );
  }

  void removeContribution({
    required FinanceModel model,
    required InvestmentHistory contribution,
  }) {
    final value = contribution.safeValue;

    model.invested = _subtractWithoutNegative(
      model.invested,
      value,
    );

    model.totalInvested = _subtractWithoutNegative(
      model.totalInvested,
      value,
    );

    model.patrimony = _subtractWithoutNegative(
      model.patrimony,
      value,
    );

    if (model.investedMonths >
        0) {
      model.investedMonths -= 1;
    }

    _updateAverageContribution(
      model,
    );
  }

  void _updateAverageContribution(
    FinanceModel model,
  ) {
    model.averageContribution =
        model.investedMonths >
            0
        ? model.totalInvested /
              model.investedMonths
        : 0;
  }

  double _subtractWithoutNegative(
    double currentValue,
    double valueToRemove,
  ) {
    return (currentValue -
            valueToRemove)
        .clamp(
          0.0,
          double.infinity,
        )
        .toDouble();
  }
}
