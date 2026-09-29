enum CryptoPriceCacheState { empty, fresh, stale, expired }

class CryptoPriceCachePolicy {
  const CryptoPriceCachePolicy._();

  static const Duration freshFor = Duration(seconds: 90);

  static const Duration staleWhileRevalidateFor = Duration(minutes: 15);

  static CryptoPriceCacheState classify({
    required bool hasPrices,
    required DateTime? updatedAt,
    DateTime? now,
  }) {
    if (!hasPrices) {
      return CryptoPriceCacheState.empty;
    }

    if (updatedAt == null) {
      return CryptoPriceCacheState.expired;
    }

    final reference = (now ?? DateTime.now()).toUtc();
    final normalized = updatedAt.toUtc();

    final age = normalized.isAfter(reference)
        ? Duration.zero
        : reference.difference(normalized);

    if (age <= freshFor) {
      return CryptoPriceCacheState.fresh;
    }

    if (age <= staleWhileRevalidateFor) {
      return CryptoPriceCacheState.stale;
    }

    return CryptoPriceCacheState.expired;
  }
}
