import 'package:flutter/foundation.dart';

import '../models/brain_growth_planner.dart';

// ============================================================
// EVENT TYPE
// ============================================================

enum BrainVisualEventType {
  // ==========================================================
  // LEGADO / CONTAGEM GLOBAL
  // ==========================================================
  knowledgeAdded,
  knowledgeCountChanged,

  // ==========================================================
  // NOVA ARQUITETURA SEMÂNTICA
  // ==========================================================
  semanticGrowthChanged,

  // ==========================================================
  // INTERAÇÃO
  // ==========================================================
  searchingChanged,
  searchResolved,

  // ==========================================================
  // INTRO
  // ==========================================================
  replayBirth,
}

// ============================================================
// EVENT
// ============================================================

@immutable
class BrainVisualEvent {
  const BrainVisualEvent({
    required this.type,
    required this.revision,
    this.growthResult,
    this.matchedBranchIndex,
  });

  final BrainVisualEventType type;

  final int revision;

  /// Preenchido quando o evento representa crescimento
  /// semântico de uma ramificação.
  final BrainGrowthResult? growthResult;

  /// Ramo associado a um resultado de pesquisa localizado.
  final int? matchedBranchIndex;
}

// ============================================================
// CONTROLLER
// ============================================================

class BrainVisualController extends ChangeNotifier {
  BrainVisualController({
    required int knowledgeCount,
    required bool introSeen,
    BrainGrowthState? growthState,
  }) : _knowledgeCount = knowledgeCount < 0 ? 0 : knowledgeCount,
       _introSeen = introSeen,
       _growthState = growthState ?? const BrainGrowthState.empty();

  // ============================================================
  // CONTAGEM GLOBAL
  // ============================================================
  //
  // Mantida por compatibilidade com BrainScreen e partes
  // antigas da visualização.
  //
  // Ela NÃO decide mais onde uma ramificação nasce.
  //
  // ============================================================

  int _knowledgeCount;

  // ============================================================
  // INTRO
  // ============================================================

  bool _introSeen;

  // ============================================================
  // SEARCH
  // ============================================================

  bool _isSearching = false;

  int? _matchedBranchIndex;

  // ============================================================
  // SEMANTIC GROWTH
  // ============================================================

  BrainGrowthState _growthState;

  BrainGrowthResult? _lastGrowthResult;

  // ============================================================
  // EVENT
  // ============================================================

  int _revision = 0;

  BrainVisualEvent? _event;

  // ============================================================
  // GETTERS
  // ============================================================

  int get knowledgeCount {
    return _knowledgeCount;
  }

  bool get introSeen {
    return _introSeen;
  }

  bool get isSearching {
    return _isSearching;
  }

  int? get matchedBranchIndex {
    return _matchedBranchIndex;
  }

  BrainGrowthState get growthState {
    return _growthState;
  }

  BrainGrowthResult? get lastGrowthResult {
    return _lastGrowthResult;
  }

  BrainVisualEvent? get event {
    return _event;
  }

  // ============================================================
  // TOPICS
  // ============================================================

  List<BrainTopicState> get topics {
    return List<BrainTopicState>.unmodifiable(_growthState.topics);
  }

  int get topicCount {
    return _growthState.topics.length;
  }

  // ============================================================
  // EVENT EMITTER
  // ============================================================

  void _emit(
    BrainVisualEventType type, {
    BrainGrowthResult? growthResult,
    int? matchedBranchIndex,
  }) {
    _revision += 1;

    _event = BrainVisualEvent(
      type: type,
      revision: _revision,
      growthResult: growthResult,
      matchedBranchIndex: matchedBranchIndex,
    );

    notifyListeners();
  }

  // ============================================================
  // RESTORE GROWTH STATE
  // ============================================================
  //
  // Usado quando BrainScreen abre.
  //
  // BrainVisualStateStorage carrega o estado salvo e entrega
  // aqui.
  //
  // Não gera animação porque estamos apenas restaurando algo
  // que já existia.
  //
  // ============================================================

  void restoreGrowthState(BrainGrowthState state) {
    _growthState = state;

    _lastGrowthResult = null;

    _emit(BrainVisualEventType.knowledgeCountChanged);
  }

  // ============================================================
  // REGISTER SEMANTIC KNOWLEDGE
  // ============================================================
  //
  // ESTE É O MÉTODO PRINCIPAL DA NOVA ARQUITETURA.
  //
  // Exemplo:
  //
  // semanticKey = cluster identificado semanticamente
  //
  // "programacao_cpp"
  //
  // Se já existir:
  //
  // branch_0 nível 1
  //        ↓
  // branch_0 nível 2
  //
  // Se for assunto novo:
  //
  // cria outro branchIndex.
  //
  // ============================================================

  BrainGrowthResult registerSemanticKnowledge({
    required String semanticKey,
    required String label,
  }) {
    final normalizedKey = semanticKey.trim();

    final normalizedLabel = label.trim();

    if (normalizedKey.isEmpty) {
      throw ArgumentError('semanticKey não pode ser vazio.');
    }

    final result = BrainGrowthPlanner.registerKnowledge(
      current: _growthState,
      semanticKey: normalizedKey,
      label: normalizedLabel,
    );

    _growthState = result.state;

    _lastGrowthResult = result;

    _knowledgeCount += 1;

    _emit(BrainVisualEventType.semanticGrowthChanged, growthResult: result);

    return result;
  }

  // ============================================================
  // APPLY GROWTH STATE
  // ============================================================
  //
  // Útil futuramente quando a busca semântica ou clustering
  // recalcular completamente os grupos.
  //
  // Não executa "novo conhecimento".
  //
  // Apenas substitui o mapa atual.
  //
  // ============================================================

  void applyGrowthState(BrainGrowthState state, {bool notify = true}) {
    _growthState = state;

    _lastGrowthResult = null;

    if (notify) {
      _emit(BrainVisualEventType.knowledgeCountChanged);
    }
  }

  // ============================================================
  // TOPIC BY SEMANTIC KEY
  // ============================================================

  BrainTopicState? topicBySemanticKey(String semanticKey) {
    return _growthState.findBySemanticKey(semanticKey.trim());
  }

  // ============================================================
  // TOPIC BY BRANCH
  // ============================================================

  BrainTopicState? topicByBranchIndex(int branchIndex) {
    return _growthState.findByBranchIndex(branchIndex);
  }

  // ============================================================
  // VISIBLE SEGMENTS
  // ============================================================

  int get visibleSegmentCount {
    return BrainGrowthPlanner.visibleSegmentCount(_growthState);
  }

  // ============================================================
  // SET KNOWLEDGE COUNT
  // ============================================================
  //
  // LEGADO.
  //
  // Atualiza somente o contador global.
  //
  // NÃO cria novas ramificações.
  //
  // ============================================================

  void setKnowledgeCount(int value) {
    final normalized = value < 0 ? 0 : value;

    if (normalized == _knowledgeCount) {
      return;
    }

    _knowledgeCount = normalized;

    _emit(BrainVisualEventType.knowledgeCountChanged);
  }

  // ============================================================
  // REGISTER KNOWLEDGE ADDED
  // ============================================================
  //
  // LEGADO.
  //
  // NÃO deve ser usado para decidir crescimento semântico.
  //
  // O caminho novo é:
  //
  // registerSemanticKnowledge()
  //
  // ============================================================

  Future<void> registerKnowledgeAdded({int amount = 1}) async {
    if (amount <= 0) {
      return;
    }

    _knowledgeCount += amount;

    _emit(BrainVisualEventType.knowledgeAdded);
  }

  // ============================================================
  // ANIMATE KNOWLEDGE TARGET
  // ============================================================
  //
  // LEGADO.
  //
  // Mantido temporariamente para não quebrar BrainScreen.
  //
  // ============================================================

  void animateKnowledgeTarget(int value) {
    final normalized = value < 0 ? 0 : value;

    if (normalized < _knowledgeCount) {
      _knowledgeCount = normalized;

      _emit(BrainVisualEventType.knowledgeCountChanged);

      return;
    }

    _knowledgeCount = normalized;

    _emit(BrainVisualEventType.knowledgeAdded);
  }

  // ============================================================
  // SEARCHING
  // ============================================================

  void setSearching(bool value) {
    if (value) {
      _matchedBranchIndex = null;
    }

    if (_isSearching == value) {
      if (value) {
        _emit(BrainVisualEventType.searchingChanged);
      }

      return;
    }

    _isSearching = value;

    _emit(BrainVisualEventType.searchingChanged);
  }

  // ============================================================
  // SEARCH RESOLVED
  // ============================================================
  //
  // Finaliza a pesquisa com um ramo alvo.
  //
  // O EvolvingBrain usa este evento para:
  //
  // 1. parar os pulsos distribuídos;
  // 2. executar um pulso final mais forte;
  // 3. acender temporariamente a região encontrada.
  //
  // ============================================================

  void resolveSearch({required int branchIndex}) {
    if (branchIndex < 0) {
      return;
    }

    _isSearching = false;

    _matchedBranchIndex = branchIndex;

    debugPrint('[BRAIN VISUAL] searchResolved branch=$branchIndex');

    _emit(BrainVisualEventType.searchResolved, matchedBranchIndex: branchIndex);
  }

  // ============================================================
  // CLEAR SEARCH MATCH
  // ============================================================

  void clearSearchMatch() {
    if (_matchedBranchIndex == null) {
      return;
    }

    _matchedBranchIndex = null;

    notifyListeners();
  }

  // ============================================================
  // INTRO SEEN
  // ============================================================

  void markIntroSeen() {
    if (_introSeen) {
      return;
    }

    _introSeen = true;
  }

  // ============================================================
  // REPLAY BIRTH
  // ============================================================

  Future<void> replayBirth() async {
    _introSeen = false;

    _emit(BrainVisualEventType.replayBirth);
  }

  // ============================================================
  // RESET GROWTH
  // ============================================================
  //
  // Principalmente para desenvolvimento/testes.
  //
  // Não mexe no conhecimento real do Vault.
  //
  // ============================================================

  void resetGrowthState() {
    _growthState = const BrainGrowthState.empty();

    _lastGrowthResult = null;

    _knowledgeCount = 0;

    _matchedBranchIndex = null;

    _isSearching = false;

    _emit(BrainVisualEventType.knowledgeCountChanged);
  }
}
