class CryptoBalances {
  final double bitcoin;
  final double ethereum;
  final double solana;
  final double usdt;

  const CryptoBalances({
    this.bitcoin = 0,
    this.ethereum = 0,
    this.solana = 0,
    this.usdt = 0,
  });

  double quantityOf(
    String symbol,
  ) {
    return switch (symbol.toUpperCase()) {
      'BTC' => bitcoin,
      'ETH' => ethereum,
      'SOL' => solana,
      'USDT' => usdt,
      _ => 0,
    };
  }
}
