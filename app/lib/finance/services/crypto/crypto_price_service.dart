import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/cache/finance_cache_store.dart';

class CryptoPriceService {
  const CryptoPriceService({
    http.Client? client,
    this.cacheStore = const FinanceCacheStore(),
  }) : _client = client;

  final FinanceCacheStore cacheStore;

  // ============================================================
  // CLIENT
  // ============================================================

  final http.Client? _client;

  // ============================================================
  // API
  // ============================================================

  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  // ============================================================
  // IDS DA COINGECKO
  // ============================================================
  //
  // A CoinGecko usa IDs, e não símbolos.
  //
  // BTC  -> bitcoin
  // ETH  -> ethereum
  // SOL  -> solana
  // USDT -> tether
  //
  // ============================================================

  static const Map<
    String,
    String
  >
  _coinIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'USDT': 'tether',
  };

  // ============================================================
  // GET ALL PRICES
  // ============================================================
  //
  // Retorno:
  //
  // {
  //   'BTC': 620000.00,
  //   'ETH': 24000.00,
  //   'SOL': 820.00,
  //   'USDT': 5.45,
  // }
  //
  // ============================================================

  Future<
    Map<
      String,
      double
    >
  >
  refreshPricesBrl() async {
    final client =
        _client ??
        http.Client();

    final shouldCloseClient =
        _client ==
        null;

    try {
      final ids = _coinIds.values.join(
        ',',
      );

      final uri =
          Uri.parse(
            '$_baseUrl/simple/price',
          ).replace(
            queryParameters: {
              'ids': ids,
              'vs_currencies': 'brl',
            },
          );

      final response = await client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

      if (response.statusCode !=
          200) {
        throw CryptoPriceException(
          'Erro ao buscar cotações. '
          'HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded
          is! Map<
            String,
            dynamic
          >) {
        throw const CryptoPriceException(
          'Resposta inválida da API de cotações.',
        );
      }

      final prices =
          <
            String,
            double
          >{};

      for (final entry in _coinIds.entries) {
        final symbol = entry.key;

        final coinId = entry.value;

        final coinData = decoded[coinId];

        if (coinData
            is! Map) {
          prices[symbol] = 0;

          continue;
        }

        final rawPrice = coinData['brl'];

        prices[symbol] = _parsePrice(
          rawPrice,
        );
      }

      await cacheStore.savePrices(
        prices,
      );

      return prices;
    } on CryptoPriceException {
      rethrow;
    } on FormatException catch (
      error
    ) {
      throw CryptoPriceException(
        'Não foi possível interpretar '
        'a resposta da API: $error',
      );
    } catch (
      error
    ) {
      throw CryptoPriceException(
        'Não foi possível buscar '
        'as cotações: $error',
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  // ============================================================
  // GET CACHED PRICES
  // ============================================================

  Future<Map<String, double>> getCachedPricesBrl() {
    return cacheStore.loadPrices();
  }

  // ============================================================
  // GET ALL PRICES
  // ============================================================
  //
  // Caminho compatível:
  // - usa cache quando existir;
  // - consulta rede somente quando ainda não há cache.
  //
  // Para refresh explícito use refreshPricesBrl().
  //
  // ============================================================

  Future<Map<String, double>> getPricesBrl() async {
    final cached = await getCachedPricesBrl();

    if (cached.isNotEmpty) {
      return cached;
    }

    return refreshPricesBrl();
  }

  // ============================================================
  // GET PRICE BY SYMBOL
  // ============================================================

  Future<
    double
  >
  getPriceBrl(
    String symbol,
  ) async {
    final normalizedSymbol = symbol.trim().toUpperCase();

    if (!_coinIds.containsKey(
      normalizedSymbol,
    )) {
      throw CryptoPriceException(
        'Criptomoeda não suportada: '
        '$normalizedSymbol.',
      );
    }

    final prices = await getPricesBrl();

    return prices[normalizedSymbol] ??
        0;
  }

  // ============================================================
  // SUPPORTED SYMBOLS
  // ============================================================

  bool supports(
    String symbol,
  ) {
    return _coinIds.containsKey(
      symbol.trim().toUpperCase(),
    );
  }

  // ============================================================
  // PARSE PRICE
  // ============================================================

  static double _parsePrice(
    dynamic value,
  ) {
    if (value ==
        null) {
      return 0;
    }

    if (value
        is num) {
      final result = value.toDouble();

      if (!result.isFinite ||
          result <
              0) {
        return 0;
      }

      return result;
    }

    final parsed = double.tryParse(
      value.toString().trim().replaceAll(
        ',',
        '.',
      ),
    );

    if (parsed ==
            null ||
        !parsed.isFinite ||
        parsed <
            0) {
      return 0;
    }

    return parsed;
  }
}

// ============================================================
// EXCEPTION
// ============================================================

class CryptoPriceException
    implements
        Exception {
  const CryptoPriceException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}
