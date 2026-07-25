import 'core/storage/local_storage.dart';
import 'services/finance/finance_service.dart';
import 'controllers/finance/finance_controller.dart';

final localStorage = LocalStorage();

final financeService = FinanceService(
  storage: localStorage,
);

final financeController = FinanceController(
  financeService,
);
