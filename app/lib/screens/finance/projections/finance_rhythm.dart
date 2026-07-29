import '../models/finance_model.dart';

class FinanceRhythm {
  final FinanceModel model;

  const FinanceRhythm(
    this.model,
  );

  // =========================================================
  // METAS CONFIGURADAS
  // =========================================================

  /// Meta mensal mínima configurada pelo usuário.
  double get minimum {
    if (model.minimumGoal <
        0) {
      return 0;
    }

    return model.minimumGoal;
  }

  /// Meta mensal média configurada pelo usuário.
  double get medium {
    if (model.mediumGoal <
        0) {
      return 0;
    }

    return model.mediumGoal;
  }

  /// Meta mensal máxima configurada pelo usuário.
  double get maximum {
    if (model.maximumGoal <
        0) {
      return 0;
    }

    return model.maximumGoal;
  }

  /// Verifica se pelo menos uma meta foi configurada.
  bool get hasConfiguredGoals {
    return minimum >
            0 ||
        medium >
            0 ||
        maximum >
            0;
  }

  /// Verifica se as metas estão em uma ordem válida.
  ///
  /// Esperado:
  ///
  /// mínimo <= médio <= máximo
  bool get hasValidGoalOrder {
    if (!hasConfiguredGoals) {
      return false;
    }

    return minimum <=
            medium &&
        medium <=
            maximum;
  }

  // =========================================================
  // DETECÇÃO DO RITMO
  // =========================================================

  /// Descobre automaticamente o ritmo de um aporte.
  ///
  /// Exemplos:
  ///
  /// Metas:
  /// mínimo = 300
  /// médio = 700
  /// máximo = 1500
  ///
  /// Aporte de 200:
  /// Tranquilo
  ///
  /// Aporte de 500:
  /// Normal
  ///
  /// Aporte de 1000:
  /// Forte
  ///
  /// Aporte acima de 1500:
  /// Personalizado
  String detect(
    double contribution,
  ) {
    if (contribution <=
        0) {
      return 'Sem aporte';
    }

    if (!hasConfiguredGoals) {
      return 'Personalizado';
    }

    final safeMinimum = minimum;

    final safeMedium =
        medium >
            0
        ? medium
        : safeMinimum;

    final safeMaximum =
        maximum >
            0
        ? maximum
        : safeMedium;

    if (safeMinimum >
            0 &&
        contribution <=
            safeMinimum) {
      return 'Tranquilo';
    }

    if (safeMedium >
            0 &&
        contribution <=
            safeMedium) {
      return 'Normal';
    }

    if (safeMaximum >
            0 &&
        contribution <=
            safeMaximum) {
      return 'Forte';
    }

    return 'Personalizado';
  }

  // =========================================================
  // PESO DO APORTE
  // =========================================================

  /// Calcula o peso do aporte.
  ///
  /// O resultado fica sempre entre 0 e 1.
  ///
  /// Faixas:
  ///
  /// Sem aporte:
  /// 0
  ///
  /// Ritmo tranquilo:
  /// 0 até 0.33
  ///
  /// Ritmo normal:
  /// 0.33 até 0.67
  ///
  /// Ritmo forte:
  /// 0.67 até 1
  ///
  /// Acima da meta máxima:
  /// 1
  double weight(
    double contribution,
  ) {
    if (contribution <=
        0) {
      return 0;
    }

    if (!hasConfiguredGoals) {
      return 0;
    }

    final safeMinimum = minimum;

    final safeMedium =
        medium >
            0
        ? medium
        : safeMinimum;

    final safeMaximum =
        maximum >
            0
        ? maximum
        : safeMedium;

    if (safeMaximum <=
        0) {
      return 0;
    }

    // -----------------------------------------------------
    // APORTE ATÉ A META MÍNIMA
    // -----------------------------------------------------

    if (safeMinimum >
            0 &&
        contribution <=
            safeMinimum) {
      final ratio =
          contribution /
          safeMinimum;

      return (ratio *
              0.33)
          .clamp(
            0.0,
            0.33,
          )
          .toDouble();
    }

    // -----------------------------------------------------
    // APORTE ENTRE A META MÍNIMA E A META MÉDIA
    // -----------------------------------------------------

    if (safeMedium >
            safeMinimum &&
        contribution <=
            safeMedium) {
      final interval =
          safeMedium -
          safeMinimum;

      final ratio =
          (contribution -
              safeMinimum) /
          interval;

      return (0.33 +
              ratio *
                  0.34)
          .clamp(
            0.33,
            0.67,
          )
          .toDouble();
    }

    // Caso mínimo e médio sejam iguais.
    if (safeMedium ==
            safeMinimum &&
        contribution <=
            safeMedium) {
      return 0.67;
    }

    // -----------------------------------------------------
    // APORTE ENTRE A META MÉDIA E A META MÁXIMA
    // -----------------------------------------------------

    if (safeMaximum >
            safeMedium &&
        contribution <=
            safeMaximum) {
      final interval =
          safeMaximum -
          safeMedium;

      final ratio =
          (contribution -
              safeMedium) /
          interval;

      return (0.67 +
              ratio *
                  0.33)
          .clamp(
            0.67,
            1.0,
          )
          .toDouble();
    }

    // Caso médio e máximo sejam iguais.
    if (safeMaximum ==
            safeMedium &&
        contribution <=
            safeMaximum) {
      return 1;
    }

    // Acima da meta máxima.
    return 1;
  }

  /// Peso em porcentagem.
  ///
  /// Retorna de 0 até 100.
  double weightPercentage(
    double contribution,
  ) {
    return weight(
          contribution,
        ) *
        100;
  }

  // =========================================================
  // PROXIMIDADE DAS METAS
  // =========================================================

  /// Distância entre o aporte e a meta mínima.
  double distanceFromMinimum(
    double contribution,
  ) {
    return (contribution -
            minimum)
        .abs();
  }

  /// Distância entre o aporte e a meta média.
  double distanceFromMedium(
    double contribution,
  ) {
    return (contribution -
            medium)
        .abs();
  }

  /// Distância entre o aporte e a meta máxima.
  double distanceFromMaximum(
    double contribution,
  ) {
    return (contribution -
            maximum)
        .abs();
  }

  /// Descobre qual meta configurada está mais próxima
  /// do valor aportado.
  ///
  /// Essa função pode ser usada em telas que prefiram
  /// classificar pelo valor mais próximo, em vez de usar
  /// as faixas do método [detect].
  String detectClosest(
    double contribution,
  ) {
    if (contribution <=
        0) {
      return 'Sem aporte';
    }

    if (!hasConfiguredGoals) {
      return 'Personalizado';
    }

    final distances =
        <
          String,
          double
        >{};

    if (minimum >
        0) {
      distances['Tranquilo'] = distanceFromMinimum(
        contribution,
      );
    }

    if (medium >
        0) {
      distances['Normal'] = distanceFromMedium(
        contribution,
      );
    }

    if (maximum >
        0) {
      distances['Forte'] = distanceFromMaximum(
        contribution,
      );
    }

    if (distances.isEmpty) {
      return 'Personalizado';
    }

    String closestRhythm = distances.keys.first;

    double closestDistance = distances.values.first;

    for (final entry in distances.entries) {
      if (entry.value <
          closestDistance) {
        closestDistance = entry.value;

        closestRhythm = entry.key;
      }
    }

    if (maximum >
            0 &&
        contribution >
            maximum) {
      return 'Personalizado';
    }

    return closestRhythm;
  }

  // =========================================================
  // NÍVEL DO RITMO
  // =========================================================

  /// Retorna um nível numérico para o ritmo.
  ///
  /// 0 = sem aporte
  /// 1 = tranquilo
  /// 2 = normal
  /// 3 = forte
  /// 4 = personalizado
  int level(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return 1;

      case 'Normal':
        return 2;

      case 'Forte':
        return 3;

      case 'Personalizado':
        return 4;

      default:
        return 0;
    }
  }

  // =========================================================
  // IDENTIDADE VISUAL
  // =========================================================

  /// Emoji correspondente ao ritmo.
  String emoji(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return '🟢';

      case 'Normal':
        return '🔵';

      case 'Forte':
        return '🟣';

      case 'Personalizado':
        return '🟠';

      default:
        return '⚪';
    }
  }

  /// Nome de cor que pode ser interpretado pela interface.
  ///
  /// Este arquivo não importa Flutter, mantendo a lógica
  /// financeira independente da camada visual.
  String colorName(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return 'green';

      case 'Normal':
        return 'blue';

      case 'Forte':
        return 'purple';

      case 'Personalizado':
        return 'orange';

      default:
        return 'grey';
    }
  }

  /// Nome completo para exibição.
  String title(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return 'Ritmo tranquilo';

      case 'Normal':
        return 'Ritmo normal';

      case 'Forte':
        return 'Ritmo forte';

      case 'Personalizado':
        return 'Ritmo personalizado';

      default:
        return 'Sem aporte';
    }
  }

  /// Nome completo acompanhado do emoji.
  String titleWithEmoji(
    double contribution,
  ) {
    return '${emoji(contribution)} ${title(contribution)}';
  }

  // =========================================================
  // MENSAGENS
  // =========================================================

  /// Mensagem principal do ritmo.
  String feedback(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return 'Você continua avançando. Cada aporte mantém seu objetivo vivo e fortalece sua constância.';

      case 'Normal':
        return 'Excelente ritmo! Você está construindo seu patrimônio com equilíbrio e consistência.';

      case 'Forte':
        return 'Ótimo trabalho! Esse aporte acelera bastante o caminho até seu objetivo.';

      case 'Personalizado':
        return 'Você superou seu ritmo forte. Esse aporte aproxima ainda mais sua liberdade financeira.';

      default:
        return 'Registre seu primeiro aporte para iniciar sua evolução financeira.';
    }
  }

  /// Mensagem curta para cards menores.
  String shortFeedback(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return 'Você manteve seu caminho ativo.';

      case 'Normal':
        return 'Você avançou com equilíbrio.';

      case 'Forte':
        return 'Você acelerou seu objetivo.';

      case 'Personalizado':
        return 'Você superou sua meta máxima.';

      default:
        return 'Nenhum aporte registrado.';
    }
  }

  /// Descrição do impacto do ritmo.
  String description(
    double contribution,
  ) {
    switch (detect(
      contribution,
    )) {
      case 'Tranquilo':
        return 'Um ritmo leve, criado para manter a constância mesmo nos meses mais difíceis.';

      case 'Normal':
        return 'Um ritmo equilibrado entre conforto financeiro e velocidade de crescimento.';

      case 'Forte':
        return 'Um ritmo acelerado para aproximar mais rapidamente o objetivo final.';

      case 'Personalizado':
        return 'Um ritmo acima da meta máxima planejada pelo usuário.';

      default:
        return 'Registre um aporte para identificar seu ritmo.';
    }
  }

  // =========================================================
  // VALORES PARA EXIBIÇÃO
  // =========================================================

  /// Retorna o valor configurado para determinado ritmo.
  double valueForRhythm(
    String rhythmName,
  ) {
    switch (rhythmName) {
      case 'Tranquilo':
        return minimum;

      case 'Normal':
        return medium;

      case 'Forte':
        return maximum;

      default:
        return 0;
    }
  }

  /// Retorna a meta correspondente ao aporte detectado.
  double goalForContribution(
    double contribution,
  ) {
    final detected = detect(
      contribution,
    );

    if (detected ==
        'Personalizado') {
      return contribution;
    }

    return valueForRhythm(
      detected,
    );
  }

  /// Quanto falta para o aporte alcançar a próxima meta.
  double amountUntilNextRhythm(
    double contribution,
  ) {
    if (contribution <=
        0) {
      if (minimum >
          0) {
        return minimum;
      }

      return 0;
    }

    final detected = detect(
      contribution,
    );

    switch (detected) {
      case 'Tranquilo':
        if (medium <=
            contribution) {
          return 0;
        }

        return medium -
            contribution;

      case 'Normal':
        if (maximum <=
            contribution) {
          return 0;
        }

        return maximum -
            contribution;

      case 'Forte':
      case 'Personalizado':
      default:
        return 0;
    }
  }

  /// Texto informando quanto falta para o próximo ritmo.
  ///
  /// O valor é retornado sem formatação monetária para
  /// manter este arquivo independente da interface.
  String nextRhythmMessage(
    double contribution,
  ) {
    final detected = detect(
      contribution,
    );

    final missing = amountUntilNextRhythm(
      contribution,
    );

    if (detected ==
            'Personalizado' ||
        detected ==
            'Forte') {
      return 'Você alcançou o ritmo mais forte.';
    }

    if (detected ==
        'Sem aporte') {
      return 'Registre um aporte para começar.';
    }

    if (missing <=
        0) {
      return 'Você está pronto para o próximo ritmo.';
    }

    if (detected ==
        'Tranquilo') {
      return 'Faltam ${missing.toStringAsFixed(2)} para alcançar o ritmo normal.';
    }

    return 'Faltam ${missing.toStringAsFixed(2)} para alcançar o ritmo forte.';
  }
}
