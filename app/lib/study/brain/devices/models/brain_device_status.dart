enum BrainDeviceStatus {
  pending,
  authorized,
  revoked;

  static BrainDeviceStatus fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return BrainDeviceStatus.pending;
      case 'authorized':
        return BrainDeviceStatus.authorized;
      case 'revoked':
        return BrainDeviceStatus.revoked;
      default:
        throw FormatException('Status de dispositivo inválido: $value');
    }
  }
}
