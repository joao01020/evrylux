import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/cache/finance_cache_store.dart';

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
  // REFRESH
  // ============================================================
  //
  // Estratégia resiliente:
  //
  // 1. Carrega primeiro o último cache válido.
  // 2. Tenta CoinGecko.
  // 3. Completa o que faltar pelo CoinPaprika.
  // 4. Nunca substitui preço válido em cache por zero.
  // 5. Se a rede falhar, devolve o último cache válido.
  //
  // Assim uma falha temporária de API não transforma
  // o Patrimônio do usuário em R$ 0,00.
  //
  // ============================================================

  Future<Map<String, double>> refreshPricesBrl() async {
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    final cached = _sanitizePrices(await cacheStore.loadPrices());

    final merged = <String, double>{...cached};

    Object? coinGeckoError;
    Object? coinPaprikaError;

    try {
      final coinGecko = await _fetchCoinGecko(client);

      _mergeValid(merged, coinGecko);
    } catch (error) {
      coinGeckoError = error;
    }

    final missingSymbols = _coinGeckoIds.keys
        .where((symbol) => !_isValidPrice(merged[symbol]))
        .toList(growable: false);

    if (missingSymbols.isNotEmpty) {
      try {
        final coinPaprika = await _fetchCoinPaprika(
          client,
          symbols: missingSymbols,
        );

        _mergeValid(merged, coinPaprika);
      } catch (error) {
        coinPaprikaError = error;
      }
    }

    final valid = _sanitizePrices(merged);

    if (valid.isNotEmpty) {
      // Só persiste valores realmente utilizáveis.
      // Nunca salva mapa zerado por cima do último cache válido.
      await cacheStore.savePrices(valid);

      return valid;
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

  // ============================================================
  // COINGECKO
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

  // ============================================================
  // COINPAPRIKA FALLBACK
  // ============================================================

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
  // CACHE
  // ============================================================

  Future<Map<String, double>> getCachedPricesBrl() async {
    return _sanitizePrices(await cacheStore.loadPrices());
  }

  Future<Map<String, double>> getPricesBrl() async {
    final cached = await getCachedPricesBrl();

    if (cached.isNotEmpty) {
      return cached;
    }

    return refreshPricesBrl();
  }

  Future<double> getPriceBrl(String symbol) async {
    final normalizedSymbol = symbol.trim().toUpperCase();

    if (!_coinGeckoIds.containsKey(normalizedSymbol)) {
      throw CryptoPriceException(
        'Criptomoeda não suportada: $normalizedSymbol.',
      );
    }

    final prices = await getPricesBrl();

    return prices[normalizedSymbol] ?? 0.0;
  }

  bool supports(String symbol) {
    return _coinGeckoIds.containsKey(symbol.trim().toUpperCase());
  }

  // ============================================================
  // HELPERS
  // ============================================================

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
}

class CryptoPriceException implements Exception {
  const CryptoPriceException(this.message);

  final String message;

  @override
  String toString() => message;
}
