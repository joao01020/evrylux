import '../../data/crypto/crypto_repository.dart';
import '../../../../models/finance/crypto_transaction_model.dart';

class CryptoService {
  final CryptoRepository repository;

  CryptoService({
    required this.repository,
  });

  Future<
    List<
      CryptoTransactionModel
    >
  >
  load(
    String symbol,
  ) {
    return repository.bySymbol(
      symbol,
    );
  }

  Future<
    void
  >
  add(
    CryptoTransactionModel transaction,
  ) {
    return repository.add(
      transaction,
    );
  }

  Future<
    void
  >
  update(
    CryptoTransactionModel transaction,
  ) {
    return repository.update(
      transaction,
    );
  }

  Future<
    void
  >
  delete(
    String id,
  ) {
    return repository.delete(
      id,
    );
  }

  Future<
    double
  >
  totalQuantity(
    String symbol,
  ) {
    return repository.totalQuantity(
      symbol,
    );
  }

  Future<
    double
  >
  totalInvested(
    String symbol,
  ) {
    return repository.totalInvested(
      symbol,
    );
  }
}
