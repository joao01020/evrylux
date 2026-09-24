import 'dart:async';

import 'package:flutter/material.dart';

import '../models/brain_ai_response.dart';

// ============================================================
// EVRYLUX CÉREBRO — AI RESULT
// ============================================================
//
// Experiência visual da resposta da IA.
//
// Fluxo:
//
// aguardando backend
//      ↓
// "Consultando seu Cérebro..."
//      ↓
// resposta chega
//      ↓
// headline aparece
//      ↓
// summary é escrito palavra por palavra
//      ↓
// sugestões aparecem suavemente
//
// IMPORTANTE:
//
// Essa animação acontece SOMENTE no Flutter.
//
// Não fazemos chamadas adicionais para:
// - Supabase;
// - Groq;
// - Cérebro;
// - Vault.
//
// Portanto o efeito de escrita não aumenta o custo da IA.
//
// ============================================================

// ============================================================
// LOADING
// ============================================================

class BrainAiLoadingCard
    extends
        StatefulWidget {
  const BrainAiLoadingCard({
    super.key,
  });

  @override
  State<
    BrainAiLoadingCard
  >
  createState() {
    return _BrainAiLoadingCardState();
  }
}

class _BrainAiLoadingCardState
    extends
        State<
          BrainAiLoadingCard
        > {
  Timer? _dotTimer;

  int _dotCount = 1;

  @override
  void initState() {
    super.initState();

    _dotTimer = Timer.periodic(
      const Duration(
        milliseconds: 420,
      ),
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _dotCount++;

            if (_dotCount >
                3) {
              _dotCount = 1;
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _dotTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    final dots = List.filled(
      _dotCount,
      '.',
    ).join();

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ======================================================
          // ÍCONE
          // ======================================================
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ======================================================
          // TEXTO
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVRYLUX',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  child: Text(
                    'Consultando seu Cérebro$dots',
                    key: ValueKey(
                      _dotCount,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESULTADO
// ============================================================

class BrainAiResultCard
    extends
        StatefulWidget {
  const BrainAiResultCard({
    required this.response,
    super.key,
  });

  final BrainAiResponse response;

  @override
  State<
    BrainAiResultCard
  >
  createState() {
    return _BrainAiResultCardState();
  }
}

class _BrainAiResultCardState
    extends
        State<
          BrainAiResultCard
        > {
  // ============================================================
  // TYPEWRITER
  // ============================================================

  Timer? _typingTimer;

  Timer? _cursorTimer;

  List<
    String
  >
  _summaryWords = const [];

  int _visibleWordCount = 0;

  bool _cursorVisible = true;

  bool _typingFinished = false;

  // ============================================================
  // VELOCIDADE
  // ============================================================
  //
  // Palavra por palavra é mais natural que caractere por caractere
  // e causa muito menos rebuilds.
  //
  // ============================================================

  static const Duration _wordInterval = Duration(
    milliseconds: 48,
  );

  static const Duration _cursorInterval = Duration(
    milliseconds: 480,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _prepareAnimation();

    _startCursor();

    _startTyping();
  }

  // ============================================================
  // NOVA RESPOSTA
  // ============================================================
  //
  // BrainAiResultCard pode continuar montado enquanto outra
  // pergunta é respondida.
  //
  // Se a resposta mudar, reiniciamos a escrita.
  //
  // ============================================================

  @override
  void didUpdateWidget(
    covariant BrainAiResultCard oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final oldResponse = oldWidget.response;

    final newResponse = widget.response;

    final oldSuggestions = oldResponse.suggestions
        .map(
          (
            item,
          ) => '${item.title}\u0000${item.reason}',
        )
        .join(
          '\u0001',
        );

    final newSuggestions = newResponse.suggestions
        .map(
          (
            item,
          ) => '${item.title}\u0000${item.reason}',
        )
        .join(
          '\u0001',
        );

    final changed =
        oldResponse.headline !=
            newResponse.headline ||
        oldResponse.summary !=
            newResponse.summary ||
        oldSuggestions !=
            newSuggestions;

    if (!changed) {
      return;
    }

    _typingTimer?.cancel();
    _cursorTimer?.cancel();

    _prepareAnimation();

    _startCursor();
    _startTyping();
  }

  // ============================================================
  // PREPARAR
  // ============================================================

  void _prepareAnimation() {
    final summary = widget.response.summary
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    _summaryWords = summary.isEmpty
        ? const []
        : summary.split(
            ' ',
          );

    _visibleWordCount = 0;

    _typingFinished = _summaryWords.isEmpty;

    _cursorVisible = true;
  }

  // ============================================================
  // CURSOR
  // ============================================================

  void _startCursor() {
    _cursorTimer?.cancel();

    _cursorTimer = Timer.periodic(
      _cursorInterval,
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        if (_typingFinished) {
          if (_cursorVisible) {
            setState(
              () {
                _cursorVisible = false;
              },
            );
          }

          return;
        }

        setState(
          () {
            _cursorVisible = !_cursorVisible;
          },
        );
      },
    );
  }

  // ============================================================
  // ESCREVER
  // ============================================================

  void _startTyping() {
    _typingTimer?.cancel();

    if (_summaryWords.isEmpty) {
      if (mounted) {
        setState(
          () {
            _typingFinished = true;
            _cursorVisible = false;
          },
        );
      }

      return;
    }

    // Pequeno atraso para a headline aparecer antes da resposta.
    Future<
      void
    >.delayed(
      const Duration(
        milliseconds: 180,
      ),
      () {
        if (!mounted) {
          return;
        }

        _typingTimer = Timer.periodic(
          _wordInterval,
          (
            timer,
          ) {
            if (!mounted) {
              timer.cancel();

              return;
            }

            if (_visibleWordCount >=
                _summaryWords.length) {
              timer.cancel();

              setState(
                () {
                  _typingFinished = true;
                  _cursorVisible = false;
                },
              );

              return;
            }

            setState(
              () {
                _visibleWordCount++;
                _cursorVisible = true;
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _typingTimer?.cancel();

    _cursorTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // TEXTO VISÍVEL
  // ============================================================

  String get _visibleSummary {
    if (_summaryWords.isEmpty) {
      return '';
    }

    final safeCount = _visibleWordCount.clamp(
      0,
      _summaryWords.length,
    );

    return _summaryWords
        .take(
          safeCount,
        )
        .join(
          ' ',
        );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 260,
      ),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        17,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: 0.74,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // IDENTIDADE
          // ======================================================
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVRYLUX',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),

                    Text(
                      'Com base no seu Cérebro',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          // ======================================================
          // HEADLINE
          // ======================================================
          AnimatedOpacity(
            duration: const Duration(
              milliseconds: 300,
            ),
            opacity: 1,
            child: Text(
              widget.response.headline.trim().isEmpty
                  ? 'Com base no que você já aprendeu'
                  : widget.response.headline.trim(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.30,
              ),
            ),
          ),

          // ======================================================
          // RESPOSTA TYPEWRITER
          // ======================================================
          if (widget.response.summary.trim().isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            _buildTypingText(
              context,
            ),
          ],

          // ======================================================
          // SUGESTÕES
          // ======================================================
          //
          // Só aparecem quando a resposta principal terminou.
          //
          // Isso dá sensação de:
          //
          // resposta
          //    ↓
          // conclusão
          //    ↓
          // próximos caminhos
          //
          // ======================================================
          AnimatedSize(
            duration: const Duration(
              milliseconds: 300,
            ),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child:
                _typingFinished &&
                    widget.response.suggestions.isNotEmpty
                ? _buildSuggestions(
                    context,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXTO SENDO ESCRITO
  // ============================================================

  Widget _buildTypingText(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _visibleSummary,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: colorScheme.onSurface,
            ),
          ),

          // ======================================================
          // CURSOR
          // ======================================================
          if (!_typingFinished)
            TextSpan(
              text: _cursorVisible
                  ? ' ▌'
                  : '  ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUGESTÕES
  // ============================================================

  Widget _buildSuggestions(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // DIVISOR
          // ======================================================
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(
              alpha: 0.35,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // ======================================================
          // TÍTULO
          // ======================================================
          Row(
            children: [
              Icon(
                Icons.explore_outlined,
                size: 17,
                color: colorScheme.primary,
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                'Próximos caminhos',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // ======================================================
          // ITENS
          // ======================================================
          for (
            var index = 0;
            index <
                widget.response.suggestions.length;
            index++
          )
            _buildSuggestionItem(
              context,
              index,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUGESTÃO INDIVIDUAL
  // ============================================================

  Widget _buildSuggestionItem(
    BuildContext context,
    int index,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    final suggestion = widget.response.suggestions[index];

    return TweenAnimationBuilder<
      double
    >(
      tween:
          Tween<
            double
          >(
            begin: 0,
            end: 1,
          ),
      duration: Duration(
        milliseconds:
            260 +
            (index *
                90),
      ),
      curve: Curves.easeOutCubic,
      builder:
          (
            context,
            value,
            child,
          ) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(
                  0,
                  7 *
                      (1 -
                          value),
                ),
                child: child,
              ),
            );
          },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.25,
          ),
          borderRadius: BorderRadius.circular(
            13,
          ),
          border: Border.all(
            color: theme.dividerColor.withValues(
              alpha: 0.30,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (suggestion.reason.trim().isNotEmpty) ...[
                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      suggestion.reason.trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
