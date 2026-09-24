# Integração

## Objetivo

Quando o usuário digitar algo como:

```text
O que eu já aprendi sobre ESP32?
```

o Brain deve detectar a intenção, usar a busca local para recuperar conteúdo relevante e enviar somente um contexto compacto para a IA.

Busca comum continua funcionando normalmente.

## 1. Copiar os arquivos

Copie:

```text
lib/study/brain/ai/
```

para:

```text
app/lib/study/brain/ai/
```

## 2. Imports em `brain_screen.dart`

```dart
import '../ai/models/brain_ai_intent.dart';
import '../ai/models/brain_ai_response.dart';
import '../ai/services/brain_ai_context_builder.dart';
import '../ai/services/brain_ai_intent_detector.dart';
import '../ai/services/brain_ai_orchestrator.dart';
import '../ai/services/brain_ai_client.dart';
import '../ai/widgets/brain_ai_result_card.dart';
```

## 3. Estado

Dentro de `_BrainScreenState`:

```dart
static const BrainAiIntentDetector _brainAiIntentDetector =
    BrainAiIntentDetector();

late final BrainAiOrchestrator _brainAiOrchestrator;

bool _brainAiLoading = false;
BrainAiResponse? _brainAiResponse;
String? _brainAiError;
```

No `initState`:

```dart
_brainAiOrchestrator = BrainAiOrchestrator(
  intentDetector: const BrainAiIntentDetector(),
  contextBuilder: const BrainAiContextBuilder(),
  client: BrainAiDisabledClient(),
);
```

Depois substitua `BrainAiDisabledClient` pelo client do backend.

## 4. Não chamar IA em `onChanged`

A digitação continua local.

Use a IA em `onSubmitted`:

```dart
onSubmitted: (value) async {
  await _runBrainSmartQuery(value);
},
```

## 5. Método de execução

Adicione à extensão de busca:

```dart
Future<void> _runBrainSmartQuery(String rawQuery) async {
  final intent = _BrainScreenState._brainAiIntentDetector.detect(rawQuery);

  if (!intent.usesAi) {
    _setBrainSearchActivity(
      rawQuery,
      hold: const Duration(milliseconds: 1600),
    );
    return;
  }

  _mutateState(() {
    _brainAiLoading = true;
    _brainAiResponse = null;
    _brainAiError = null;
  });

  try {
    final response = await _brainAiOrchestrator.run(
      rawQuery: rawQuery,
      notes: _controller.notes,
      searchResponse: _searchResponse,
    );

    if (!mounted) return;

    _mutateState(() {
      _brainAiResponse = response;
      _brainAiLoading = false;
    });
  } catch (_) {
    if (!mounted) return;

    _mutateState(() {
      _brainAiLoading = false;
      _brainAiError = 'Não foi possível analisar seu Brain agora.';
    });
  }
}
```

## 6. UI

Na região dos resultados:

```dart
if (_brainAiLoading)
  const BrainAiLoadingCard()
else if (_brainAiResponse != null)
  BrainAiResultCard(response: _brainAiResponse!)
else
  _buildSearchResults(context)
```

## 7. Backend

Recomendado:

```text
Flutter
→ endpoint backend / Supabase Function
→ provedor de IA
```

Nunca coloque uma chave secreta do provedor dentro do Flutter.

Contrato sugerido:

```json
{
  "intent": "study_gaps",
  "topic": "ESP32",
  "query": "o que falta eu aprender sobre ESP32?",
  "knowledge": [
    {
      "id": "c1",
      "title": "SPI",
      "summary": "Aprendi MOSI, MISO, SCLK e CS."
    }
  ]
}
```

Resposta:

```json
{
  "headline": "Com base no que você já aprendeu sobre ESP32...",
  "summary": "Você já estudou comunicação e GPIO.",
  "suggestions": [
    {
      "title": "FreeRTOS",
      "reason": "Ajuda a avançar para multitarefa."
    }
  ]
}
```
