import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/cache/finance_cache_store.dart';
import 'crypto_price_cache_policy.dart';

class CryptoPriceService {
  const CryptoPriceService({
    http.Client? client,
    this.cacheStore = const FinanceCacheStore(),
  }) : _client = client;

  final FinanceCacheStore cacheStore;
  final http.Client? _client;

  static const String _coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';

  static const String _coinPaprikaBaseUrl =
      'https://api.coinpaprika.com/v1/tickers';

  static const Map<String, String> _coinGeckoIds = <String, String>{
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'USDT': 'tether',
  };

  static const Map<String, String> _coinPaprikaIds = <String, String>{
    'BTC': 'btc-bitcoin',
    'ETH': 'eth-ethereum',
    'SOL': 'sol-solana',
    'USDT': 'usdt-tether',
  };

  // ============================================================
  // PUBLIC
  // ============================================================

  Future<Map<String, double>> getPricesBrl() async {
    final snapshot = await getCachedSnapshot();
    final cached = snapshot.prices;

    final state = CryptoPriceCachePolicy.classify(
      hasPrices: cached.isNotEmpty,
      updatedAt: snapshot.updatedAt,
    );

    switch (state) {
      case CryptoPriceCacheState.fresh:
        _logCache(source: 'cache-fresh', snapshot: snapshot);
        return cached;

      case CryptoPriceCacheState.stale:
        _logCache(source: 'cache-stale', snapshot: snapshot);

        // Stale-while-revalidate:
        // entrega a última cotação válida imediatamente e atualiza
        // em background, sem travar a interface.
        unawaited(_refreshSilently());

        return cached;

      case CryptoPriceCacheState.expired:
        if (cached.isNotEmpty) {
          try {
            return await refreshPricesBrl();
          } catch (error) {
            _log(
              '[FINANCE][PRICE] refresh falhou; '
              'usando cache expirado como último valor conhecido. '
              'error=$error',
            );
            return cached;
          }
        }

        return refreshPricesBrl();

      case CryptoPriceCacheState.empty:
        return refreshPricesBrl();
    }
  }

  Future<Map<String, double>> refreshPricesBrl() async {
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    final snapshot = await getCachedSnapshot();
    final merged = <String, double>{...snapshot.prices};

    Object? coinGeckoError;
    Object? coinPaprikaError;

    try {
      final prices = await _fetchCoinGecko(client);

      _mergeValid(merged, prices);

      _logProvider(provider: 'coingecko', prices: prices);
    } catch (error) {
      coinGeckoError = error;

      _log(
        '[FINANCE][PRICE] provider=coingecko '
        'status=failed error=$error',
      );
    }

    final missing = _coinGeckoIds.keys
        .where((symbol) => !_isValidPrice(merged[symbol]))
        .toList(growable: false);

    if (missing.isNotEmpty) {
      try {
        final prices = await _fetchCoinPaprika(client, symbols: missing);

        _mergeValid(merged, prices);

        _logProvider(provider: 'coinpaprika', prices: prices);
      } catch (error) {
        coinPaprikaError = error;

        _log(
          '[FINANCE][PRICE] provider=coinpaprika '
          'status=failed error=$error',
        );
      }
    }

    final valid = _sanitizePrices(merged);

    if (valid.isNotEmpty) {
      final now = DateTime.now().toUtc();

      // Proteção contra zero:
      // somente valores > 0 são persistidos. Uma API quebrada
      // nunca sobrescreve uma cotação boa por zero.
      await cacheStore.savePrices(valid, updatedAt: now);

      _log(
        '[FINANCE][PRICE] cache=updated '
        'timestamp=${now.toIso8601String()} '
        'symbols=${valid.keys.join(',')}',
      );

      return valid;
    }

    if (snapshot.prices.isNotEmpty) {
      _log(
        '[FINANCE][PRICE] providers indisponíveis; '
        'preservando último cache válido.',
      );

      return snapshot.prices;
    }

    final details = <String>[
      if (coinGeckoError != null) 'CoinGecko: $coinGeckoError',
      if (coinPaprikaError != null) 'CoinPaprika: $coinPaprikaError',
    ].join(' | ');

    throw CryptoPriceException(
      details.isEmpty
          ? 'Nenhuma cotação válida foi encontrada.'
          : 'Não foi possível atualizar as cotações. $details',
    );
  }

  Future<FinancePriceCacheSnapshot> getCachedSnapshot() async {
    final raw = await cacheStore.loadPriceSnapshot();

    return FinancePriceCacheSnapshot(
      prices: _sanitizePrices(raw.prices),
      updatedAt: raw.updatedAt,
    );
  }

  Future<Map<String, double>> getCachedPricesBrl() async {
    final snapshot = await getCachedSnapshot();
    return snapshot.prices;
  }

  Future<DateTime?> getCachedPricesUpdatedAt() async {
    final snapshot = await getCachedSnapshot();
    return snapshot.updatedAt;
  }

  Future<double> getPriceBrl(String symbol) async {
    final normalized = symbol.trim().toUpperCase();

    if (!_coinGeckoIds.containsKey(normalized)) {
      throw CryptoPriceException('Criptomoeda não suportada: $normalized.');
    }

    final prices = await getPricesBrl();

    return prices[normalized] ?? 0.0;
  }

  bool supports(String symbol) {
    return _coinGeckoIds.containsKey(symbol.trim().toUpperCase());
  }

  // ============================================================
  // NETWORK
  // ============================================================

  Future<Map<String, double>> _fetchCoinGecko(http.Client client) async {
    final ids = _coinGeckoIds.values.join(',');

    final uri = Uri.parse('$_coinGeckoBaseUrl/simple/price').replace(
      queryParameters: <String, String>{'ids': ids, 'vs_currencies': 'brl'},
    );

    final response = await client
        .get(uri, headers: const <String, String>{'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw CryptoPriceException('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const CryptoPriceException('Resposta inválida.');
    }

    final prices = <String, double>{};

    for (final entry in _coinGeckoIds.entries) {
      final coinData = decoded[entry.value];

      if (coinData is! Map) {
        continue;
      }

      final value = _parsePrice(coinData['brl']);

      if (_isValidPrice(value)) {
        prices[entry.key] = value;
      }
    }

    if (prices.isEmpty) {
      throw const CryptoPriceException('Nenhuma cotação válida retornada.');
    }

    return prices;
  }

  Future<Map<String, double>> _fetchCoinPaprika(
    http.Client client, {
    required List<String> symbols,
  }) async {
    final prices = <String, double>{};
    Object? lastError;

    for (final symbol in symbols) {
      final id = _coinPaprikaIds[symbol];

      if (id == null) {
        continue;
      }

      try {
        final uri = Uri.parse(
          '$_coinPaprikaBaseUrl/$id',
        ).replace(queryParameters: const <String, String>{'quotes': 'BRL'});

        final response = await client
            .get(
              uri,
              headers: const <String, String>{'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          lastError = CryptoPriceException(
            '$symbol HTTP ${response.statusCode}',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          lastError = CryptoPriceException('$symbol resposta inválida');
          continue;
        }

        final quotes = decoded['quotes'];

        if (quotes is! Map) {
          continue;
        }

        final brl = quotes['BRL'];

        if (brl is! Map) {
          continue;
        }

        final value = _parsePrice(brl['price']);

        if (_isValidPrice(value)) {
          prices[symbol] = value;
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (prices.isEmpty && lastError != null) {
      throw CryptoPriceException(lastError.toString());
    }

    return prices;
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  Future<void> _refreshSilently() async {
    try {
      await refreshPricesBrl();
    } catch (error) {
      _log(
        '[FINANCE][PRICE] background-refresh=failed '
        'error=$error',
      );
    }
  }

  static void _mergeValid(
    Map<String, double> target,
    Map<String, double> source,
  ) {
    for (final entry in source.entries) {
      if (_isValidPrice(entry.value)) {
        target[entry.key] = entry.value;
      }
    }
  }

  static Map<String, double> _sanitizePrices(Map<String, double> source) {
    final result = <String, double>{};

    for (final symbol in _coinGeckoIds.keys) {
      final value = source[symbol];

      if (_isValidPrice(value)) {
        result[symbol] = value!;
      }
    }

    return result;
  }

  static bool _isValidPrice(double? value) {
    return value != null && value.isFinite && value > 0;
  }

  static double _parsePrice(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      final parsed = value.toDouble();

      return _isValidPrice(parsed) ? parsed : 0.0;
    }

    final parsed = double.tryParse(
      value.toString().trim().replaceAll(',', '.'),
    );

    if (parsed == null) {
      return 0.0;
    }

    return _isValidPrice(parsed) ? parsed : 0.0;
  }

  static void _logProvider({
    required String provider,
    required Map<String, double> prices,
  }) {
    _log(
      '[FINANCE][PRICE] provider=$provider '
      'status=ok symbols=${prices.keys.join(',')}',
    );
  }

  static void _logCache({
    required String source,
    required FinancePriceCacheSnapshot snapshot,
  }) {
    final age = snapshot.age();

    _log(
      '[FINANCE][PRICE] source=$source '
      'ageSeconds=${age?.inSeconds ?? -1} '
      'timestamp=${snapshot.updatedAt?.toIso8601String() ?? 'unknown'} '
      'symbols=${snapshot.prices.keys.join(',')}',
    );
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}

class CryptoPriceException implements Exception {
  const CryptoPriceException(this.message);

  final String message;

  @override
  String toString() => message;
}
