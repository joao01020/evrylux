import '../../core/storage/local_storage.dart';
import '../controllers/crypto/crypto_controller.dart';
import '../controllers/finance_controller.dart';
import '../data/repository/crypto/crypto_repository.dart';
import '../data/repository/finance_repository_web.dart';
import '../services/crypto/crypto_price_service.dart';
import '../services/crypto/crypto_service.dart';
import '../services/persistence/finance_service.dart';

final _financeRepository = FinanceRepository();
final _financeService = FinanceService(repository: _financeRepository);

final financeController = FinanceController(_financeService);

final _cryptoRepository = CryptoRepository(storage: LocalStorage());
final _cryptoService = CryptoService(repository: _cryptoRepository);

final cryptoController = CryptoController(service: _cryptoService);
final cryptoPriceService = CryptoPriceService();
