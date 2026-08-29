import '../../data/repository/crypto/crypto_repository.dart';
import '../../models/crypto/crypto_transaction_model.dart';

class CryptoService {
  const CryptoService({
    required this.repository,
  });

  // ============================================================
  // REPOSITORY
  // ============================================================

  final CryptoRepository repository;

  // ============================================================
  // CARREGAR TRANSAÇÕES
  // ============================================================

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

  // ============================================================
  // ADICIONAR
  // ============================================================

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

  // ============================================================
  // EDITAR
  // ============================================================

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

  // ============================================================
  // EXCLUIR
  // ============================================================

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

  // ============================================================
  // TOTAL DE QUANTIDADE
  // ============================================================

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

  // ============================================================
  // TOTAL INVESTIDO
  // ============================================================

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
