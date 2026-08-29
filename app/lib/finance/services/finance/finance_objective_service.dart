import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// FINANCE OBJECTIVE
// ============================================================
//
// Modelo simples usado pelo Service.
//
// Depois podemos mover esta classe para:
//
// lib/finance/models/finance_objective.dart
//
// sem alterar a lógica do Service.
// ============================================================

class FinanceObjective {
  const FinanceObjective({
    required this.name,
    required this.targetValue,
  });

  final String name;

  final double targetValue;

  // ==========================================================
  // EMPTY / DEFAULT
  // ==========================================================

  factory FinanceObjective.empty() {
    return const FinanceObjective(
      name: 'Objetivo financeiro',
      targetValue: 0,
    );
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory FinanceObjective.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final rawName = map['name']?.toString().trim();

    final rawTargetValue = map['target_value'];

    final targetValue =
        rawTargetValue
            is num
        ? rawTargetValue.toDouble()
        : double.tryParse(
                rawTargetValue?.toString() ??
                    '',
              ) ??
              0;

    return FinanceObjective(
      name:
          rawName ==
                  null ||
              rawName.isEmpty
          ? 'Objetivo financeiro'
          : rawName,
      targetValue: targetValue,
    );
  }

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'name': name.trim(),
      'target_value': targetValue,
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  FinanceObjective copyWith({
    String? name,
    double? targetValue,
  }) {
    return FinanceObjective(
      name:
          name ??
          this.name,
      targetValue:
          targetValue ??
          this.targetValue,
    );
  }
}

// ============================================================
// FINANCE OBJECTIVE SERVICE
// ============================================================
//
// Responsabilidade:
//
// - carregar objetivo financeiro;
// - criar objetivo;
// - atualizar objetivo;
// - salvar nome;
// - salvar valor;
// - remover objetivo;
// - conversar diretamente com o Supabase.
//
// NÃO deve:
//
// - abrir dialogs;
// - acessar BuildContext;
// - chamar setState;
// - conhecer widgets;
// - formatar moeda;
// - controlar UI.
//
// Fluxo:
//
// FinanceScreen
//      ↓
// FinanceScreenActions
//      ↓
// FinanceScreenController
//      ↓
// FinanceObjectiveService
//      ↓
// Supabase
//
// ============================================================

class FinanceObjectiveService {
  // ==========================================================
  // TABLE
  // ==========================================================

  static const String _table = 'finance_objectives';

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  FinanceObjectiveService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  // ==========================================================
  // USER ID
  // ==========================================================

  String? get currentUserId {
    final id = currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
  }

  // ==========================================================
  // AUTHENTICATED
  // ==========================================================

  bool get isAuthenticated {
    return currentUserId !=
        null;
  }

  // ==========================================================
  // REQUIRE USER ID
  // ==========================================================

  String _requireUserId() {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  Future<
    FinanceObjective?
  >
  load() async {
    final userId = currentUserId;

    if (userId ==
        null) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Load cancelado: usuário não autenticado.',
      );

      return null;
    }

    try {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Carregando objetivo.',
      );

      final response = await _supabase
          .from(
            _table,
          )
          .select(
            '''
                name,
                target_value
                ''',
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle();

      if (response ==
          null) {
        debugPrint(
          '[FINANCE OBJECTIVE SERVICE] '
          'Nenhum objetivo encontrado.',
        );

        return null;
      }

      final objective = FinanceObjective.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Objetivo carregado: '
        '${objective.name} | '
        '${objective.targetValue}',
      );

      return objective;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Erro ao carregar objetivo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // SAVE
  // ==========================================================
  //
  // Usa UPSERT.
  //
  // Como user_id é UNIQUE / PRIMARY KEY:
  //
  // se não existe:
  // INSERT
  //
  // se já existe:
  // UPDATE
  //
  // ==========================================================

  Future<
    FinanceObjective
  >
  save({
    required String name,
    required double targetValue,
  }) async {
    final userId = _requireUserId();

    final normalizedName = _normalizeName(
      name,
    );

    final normalizedTargetValue = _normalizeTargetValue(
      targetValue,
    );

    try {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Salvando objetivo.',
      );

      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Nome: $normalizedName',
      );

      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Valor: $normalizedTargetValue',
      );

      final response = await _supabase
          .from(
            _table,
          )
          .upsert(
            {
              'user_id': userId,
              'name': normalizedName,
              'target_value': normalizedTargetValue,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'user_id',
          )
          .select(
            '''
                name,
                target_value
                ''',
          )
          .single();

      final objective = FinanceObjective.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Objetivo salvo com sucesso.',
      );

      return objective;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Erro ao salvar objetivo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // UPDATE NAME
  // ==========================================================

  Future<
    FinanceObjective
  >
  updateName(
    String name,
  ) async {
    final userId = _requireUserId();

    final normalizedName = _normalizeName(
      name,
    );

    try {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Atualizando nome do objetivo.',
      );

      final response = await _supabase
          .from(
            _table,
          )
          .update(
            {
              'name': normalizedName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'user_id',
            userId,
          )
          .select(
            '''
                name,
                target_value
                ''',
          )
          .maybeSingle();

      // ======================================================
      // OBJETIVO AINDA NÃO EXISTE
      // ======================================================

      if (response ==
          null) {
        return save(
          name: normalizedName,
          targetValue: 0,
        );
      }

      return FinanceObjective.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Erro ao atualizar nome: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // UPDATE VALUE
  // ==========================================================

  Future<
    FinanceObjective
  >
  updateValue(
    double targetValue,
  ) async {
    final userId = _requireUserId();

    final normalizedTargetValue = _normalizeTargetValue(
      targetValue,
    );

    try {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Atualizando valor do objetivo.',
      );

      final response = await _supabase
          .from(
            _table,
          )
          .update(
            {
              'target_value': normalizedTargetValue,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'user_id',
            userId,
          )
          .select(
            '''
                name,
                target_value
                ''',
          )
          .maybeSingle();

      // ======================================================
      // OBJETIVO AINDA NÃO EXISTE
      // ======================================================

      if (response ==
          null) {
        return save(
          name: 'Objetivo financeiro',
          targetValue: normalizedTargetValue,
        );
      }

      return FinanceObjective.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Erro ao atualizar valor: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<
    void
  >
  delete() async {
    final userId = _requireUserId();

    try {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Removendo objetivo.',
      );

      await _supabase
          .from(
            _table,
          )
          .delete()
          .eq(
            'user_id',
            userId,
          );

      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Objetivo removido.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Erro ao remover objetivo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // EXISTS
  // ==========================================================

  Future<
    bool
  >
  exists() async {
    final userId = currentUserId;

    if (userId ==
        null) {
      return false;
    }

    try {
      final response = await _supabase
          .from(
            _table,
          )
          .select(
            'user_id',
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle();

      return response !=
          null;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE OBJECTIVE SERVICE] '
        'Erro ao verificar objetivo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // NORMALIZE NAME
  // ==========================================================

  String _normalizeName(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'O nome do objetivo não pode ficar vazio.',
      );
    }

    if (normalized.length >
        60) {
      throw ArgumentError(
        'O nome do objetivo pode ter no máximo 60 caracteres.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // NORMALIZE TARGET VALUE
  // ==========================================================

  double _normalizeTargetValue(
    double value,
  ) {
    if (value.isNaN ||
        value.isInfinite) {
      throw ArgumentError(
        'O valor do objetivo é inválido.',
      );
    }

    if (value <
        0) {
      throw ArgumentError(
        'O valor do objetivo não pode ser negativo.',
      );
    }

    return value;
  }
}
