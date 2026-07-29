import '../../models/crypto/crypto_balances.dart';

class CryptoBalanceService {
  final dynamic cryptoController;

  CryptoBalanceService({
    required this.cryptoController,
  });

  Future<
    CryptoBalances
  >
  loadBalances() async {
    return CryptoBalances(
      bitcoin: await _loadQuantity(
        'BTC',
      ),
      ethereum: await _loadQuantity(
        'ETH',
      ),
      solana: await _loadQuantity(
        'SOL',
      ),
      usdt: await _loadQuantity(
        'USDT',
      ),
    );
  }

  Future<
    double
  >
  _loadQuantity(
    String symbol,
  ) async {
    await cryptoController.load(
      symbol,
    );
    return cryptoController.quantity;
  }
}
