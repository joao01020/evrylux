import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../painters/brain_paths.dart';
import 'brain_connection.dart';

@immutable
class BrainTopicState {
  const BrainTopicState({
    required this.semanticKey,
    required this.label,
    required this.branchIndex,
    required this.knowledgeCount,
  });

  final String semanticKey;
  final String label;
  final int branchIndex;
  final int knowledgeCount;

  int get level {
    return BrainGrowthPlanner.levelForKnowledgeCount(knowledgeCount);
  }

  BrainTopicState copyWith({
    String? semanticKey,
    String? label,
    int? branchIndex,
    int? knowledgeCount,
  }) {
    return BrainTopicState(
      semanticKey: semanticKey ?? this.semanticKey,
      label: label ?? this.label,
      branchIndex: branchIndex ?? this.branchIndex,
      knowledgeCount: knowledgeCount ?? this.knowledgeCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'semantic_key': semanticKey,
      'label': label,
      'branch_index': branchIndex,
      'knowledge_count': knowledgeCount,
    };
  }

  factory BrainTopicState.fromMap(Map<String, dynamic> map) {
    return BrainTopicState(
      semanticKey: map['semantic_key'] as String? ?? '',
      label: map['label'] as String? ?? '',
      branchIndex: (map['branch_index'] as num?)?.toInt() ?? 0,
      knowledgeCount: (map['knowledge_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class BrainGrowthState {
  const BrainGrowthState({required this.topics});

  final List<BrainTopicState> topics;

  const BrainGrowthState.empty() : topics = const <BrainTopicState>[];

  BrainGrowthState copyWith({List<BrainTopicState>? topics}) {
    return BrainGrowthState(topics: topics ?? this.topics);
  }

  BrainTopicState? findBySemanticKey(String semanticKey) {
    for (final topic in topics) {
      if (topic.semanticKey == semanticKey) {
        return topic;
      }
    }

    return null;
  }

  BrainTopicState? findByBranchIndex(int branchIndex) {
    for (final topic in topics) {
      if (topic.branchIndex == branchIndex) {
        return topic;
      }
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'topics': topics.map((topic) => topic.toMap()).toList(),
    };
  }

  factory BrainGrowthState.fromMap(Map<String, dynamic> map) {
    final rawTopics = (map['topics'] as List<dynamic>? ?? const <dynamic>[]);

    return BrainGrowthState(
      topics: rawTopics
          .whereType<Map>()
          .map((raw) => BrainTopicState.fromMap(Map<String, dynamic>.from(raw)))
          .toList(growable: false),
    );
  }
}

class BrainGrowthResult {
  const BrainGrowthResult({
    required this.state,
    required this.updatedTopic,
    required this.createdNewBranch,
    required this.previousLevel,
    required this.currentLevel,
  });

  final BrainGrowthState state;
  final BrainTopicState updatedTopic;
  final bool createdNewBranch;
  final int previousLevel;
  final int currentLevel;

  bool get levelChanged {
    return currentLevel != previousLevel;
  }
}

class BrainGrowthPlanner {
  const BrainGrowthPlanner._();

  static final math.Random _random = math.Random();

  static const List<int> growthMilestones = <int>[1, 3, 6, 10, 15];

  static int levelForKnowledgeCount(int count) {
    if (count <= 0) {
      return 0;
    }

    if (count < 3) {
      return 1;
    }

    if (count < 6) {
      return 2;
    }

    if (count < 10) {
      return 3;
    }

    if (count < 15) {
      return 4;
    }

    return 5;
  }

  // ============================================================
  // REGISTER KNOWLEDGE
  // ============================================================

  static BrainGrowthResult registerKnowledge({
    required BrainGrowthState current,
    required String semanticKey,
    required String label,
  }) {
    final safeKey = semanticKey.trim();

    final safeLabel = label.trim().isEmpty ? safeKey : label.trim();

    if (safeKey.isEmpty) {
      throw ArgumentError('semanticKey não pode ser vazio.');
    }

    // ========================================================
    // MESMO ASSUNTO
    // ========================================================

    final existing = current.findBySemanticKey(safeKey);

    if (existing != null) {
      final previousLevel = existing.level;

      final updated = existing.copyWith(
        knowledgeCount: existing.knowledgeCount + 1,
      );

      final nextTopics = current.topics
          .map((topic) {
            if (topic.semanticKey == safeKey) {
              return updated;
            }

            return topic;
          })
          .toList(growable: false);

      final nextState = current.copyWith(topics: nextTopics);

      return BrainGrowthResult(
        state: nextState,
        updatedTopic: updated,
        createdNewBranch: false,
        previousLevel: previousLevel,
        currentLevel: updated.level,
      );
    }

    // ========================================================
    // ASSUNTO NOVO
    // ========================================================
    //
    // Escolhe ALEATORIAMENTE um slot ainda livre.
    //
    // Como branchIndex é persistido no BrainGrowthState,
    // a posição fica aleatória somente no nascimento.
    //
    // Depois o assunto permanece naquele mesmo lugar.
    //
    // ========================================================

    final freeBranchIndex = _randomFreeBranchIndex(current);

    if (freeBranchIndex == null) {
      final fallback = _weakestTopic(current);

      if (fallback == null) {
        throw StateError('Não foi possível alocar um ramo visual.');
      }

      final previousLevel = fallback.level;

      final updated = fallback.copyWith(
        knowledgeCount: fallback.knowledgeCount + 1,
      );

      final nextTopics = current.topics
          .map((topic) {
            if (topic.semanticKey == fallback.semanticKey) {
              return updated;
            }

            return topic;
          })
          .toList(growable: false);

      final nextState = current.copyWith(topics: nextTopics);

      return BrainGrowthResult(
        state: nextState,
        updatedTopic: updated,
        createdNewBranch: false,
        previousLevel: previousLevel,
        currentLevel: updated.level,
      );
    }

    final created = BrainTopicState(
      semanticKey: safeKey,
      label: safeLabel,
      branchIndex: freeBranchIndex,
      knowledgeCount: 1,
    );

    final nextState = current.copyWith(
      topics: <BrainTopicState>[...current.topics, created],
    );

    return BrainGrowthResult(
      state: nextState,
      updatedTopic: created,
      createdNewBranch: true,
      previousLevel: 0,
      currentLevel: created.level,
    );
  }

  // ============================================================
  // RANDOM FREE SLOT
  // ============================================================

  static int? _randomFreeBranchIndex(BrainGrowthState current) {
    final used = current.topics.map((topic) => topic.branchIndex).toSet();

    final free = List<int>.generate(
      BrainPaths.mainBranchCount,
      (index) => index,
    ).where((index) => !used.contains(index)).toList();

    if (free.isEmpty) {
      return null;
    }

    return free[_random.nextInt(free.length)];
  }

  // ============================================================
  // WEAKEST
  // ============================================================

  static BrainTopicState? _weakestTopic(BrainGrowthState current) {
    if (current.topics.isEmpty) {
      return null;
    }

    final ordered = <BrainTopicState>[...current.topics]
      ..sort((a, b) {
        return a.knowledgeCount.compareTo(b.knowledgeCount);
      });

    return ordered.first;
  }

  // ============================================================
  // VISIBLE CONNECTIONS
  // ============================================================

  static List<BrainConnectionDefinition> buildVisibleConnections(
    BrainGrowthState state,
  ) {
    final result = <BrainConnectionDefinition>[];

    final orderedTopics = <BrainTopicState>[...state.topics]
      ..sort((a, b) {
        return a.branchIndex.compareTo(b.branchIndex);
      });

    for (final topic in orderedTopics) {
      result.addAll(
        BrainPaths.connectionsForBranch(
          branchIndex: topic.branchIndex,
          level: topic.level,
        ),
      );
    }

    return result;
  }

  static int visibleSegmentCount(BrainGrowthState state) {
    var total = 0;

    for (final topic in state.topics) {
      total += topic.level;
    }

    return total;
  }

  static BrainTopicState? topicForBranch(
    BrainGrowthState state,
    int branchIndex,
  ) {
    return state.findByBranchIndex(branchIndex);
  }
}
