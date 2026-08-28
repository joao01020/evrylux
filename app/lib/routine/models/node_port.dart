enum NodePort {
  top,
  right,
  bottom,
  left;

  NodePort get opposite => switch (this) {
    NodePort.top => NodePort.bottom,
    NodePort.right => NodePort.left,
    NodePort.bottom => NodePort.top,
    NodePort.left => NodePort.right,
  };

  String get label => switch (this) {
    NodePort.top => 'acima',
    NodePort.right => 'à direita',
    NodePort.bottom => 'abaixo',
    NodePort.left => 'à esquerda',
  };

  String get databaseValue => switch (this) {
    NodePort.top => 'top',
    NodePort.right => 'right',
    NodePort.bottom => 'bottom',
    NodePort.left => 'left',
  };

  static NodePort fromDatabase(
    String value,
  ) {
    return switch (value) {
      'top' => NodePort.top,
      'right' => NodePort.right,
      'bottom' => NodePort.bottom,
      'left' => NodePort.left,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Porta inválida',
      ),
    };
  }
}
