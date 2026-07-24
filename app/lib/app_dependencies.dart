import 'core/storage/local_storage.dart';
import 'services/finance_service.dart';
import 'controllers/finance_controller.dart';

final localStorage = LocalStorage();

final financeService = FinanceService(
  storage: localStorage,
);

final financeController = FinanceController(
  financeService,
);
