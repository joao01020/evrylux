import '../../../core/sync/sync_status.dart';

abstract interface class FinanceRepositoryContract {
  Future<void> save(Map<String, dynamic> data);

  Future<Map<String, dynamic>> load();

  Future<void> updateCryptoBalance({
    required String symbol,
    required double value,
  });

  Future<void> updateCryptoBalances({
    double? bitcoin,
    double? ethereum,
    double? solana,
    double? usdt,
  });

  Future<void> updatePatrimony(double value);

  Future<void> updateInvested(double value);

  Future<void> clear();

  Future<Map<String, dynamic>> refreshFromRemote();

  Future<Map<String, dynamic>?> loadLocal();

  Future<SyncStatus?> getLocalSyncStatus();
}
