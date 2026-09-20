import 'dart:async';

// ============================================================
// ACCOUNT STARTUP CANCELLED
// ============================================================

/// Exceção usada para invalidar uma inicialização que pertence
/// a uma conta que deixou de ser a conta ativa.
///
/// Não cria identidade local e não substitui autenticação.
class AccountStartupCancelled
    implements
        Exception {
  const AccountStartupCancelled();
}

// ============================================================
// ACCOUNT STARTUP COORDINATOR
// ============================================================

/// Serializa a inicialização privada relacionada à conta atual.
///
/// Responsabilidades:
///
/// - garantir que apenas uma inicialização seja executada por vez;
/// - interromper trabalhos pertencentes a outra conta;
/// - invalidar operações antigas quando a identidade mudar;
/// - serializar operações de `stop`;
/// - permitir nova tentativa após falha;
/// - nunca substituir o estado real de autenticação.
class AccountStartupCoordinator {
  AccountStartupCoordinator({
    required this.currentUserId,
    required this.initialize,
    required this.stop,
    required this.onIdentityChanged,
  });

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  /// Retorna o ID do usuário autenticado atualmente.
  final String? Function() currentUserId;

  /// Inicializa os recursos privados pertencentes ao usuário.
  ///
  /// `check` deve ser executado durante operações longas para
  /// garantir que a conta ainda seja a mesma.
  final Future<
    void
  >
  Function(
    String userId,
    void Function() check,
  )
  initialize;

  /// Interrompe ou drena recursos pertencentes à conta anterior.
  final Future<
    void
  >
  Function()
  stop;

  /// Notifica consumidores sobre a identidade atualmente válida.
  ///
  /// `null` revoga imediatamente qualquer identidade anterior.
  final void Function(
    String? userId,
  )
  onIdentityChanged;

  // ============================================================
  // STATE
  // ============================================================

  String? _desiredUserId;

  String? _readyUserId;

  int _generation = 0;

  Future<
    void
  >
  _tail =
      Future<
        void
      >.value();

  Future<
    void
  >?
  _pending;

  // ============================================================
  // READY USER
  // ============================================================

  String? get readyUserId => _readyUserId;

  // ============================================================
  // NORMALIZE
  // ============================================================

  String? _normalize(
    String? value,
  ) {
    final String? normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // SET USER
  // ============================================================

  void setUser(
    String? userId,
  ) {
    final String? next = _normalize(
      userId,
    );

    if (next ==
        _desiredUserId) {
      return;
    }

    _desiredUserId = next;

    _readyUserId = null;

    _pending = null;

    _generation++;

    // ========================================================
    // REVOGAÇÃO IMEDIATA
    // ========================================================
    //
    // A identidade anterior deixa de ser válida imediatamente.
    //
    // O encerramento físico/drain dos recursos continua sendo
    // serializado pela fila.
    //
    // ========================================================

    onIdentityChanged(
      null,
    );

    _enqueue(
      stop,
    );
  }

  // ============================================================
  // QUEUE
  // ============================================================

  Future<
    void
  >
  _enqueue(
    Future<
      void
    >
    Function()
    action,
  ) {
    final Future<
      void
    >
    result = _tail.then(
      (
        _,
      ) {
        return action();
      },
    );

    // ========================================================
    // IMPORTANTE
    // ========================================================
    //
    // Uma falha anterior nunca deve quebrar permanentemente
    // a fila.
    //
    // Dessa forma logout, troca de conta ou uma nova tentativa
    // ainda podem ser executados.
    //
    // O Future retornado em `result` continua propagando o erro
    // para quem iniciou a operação.
    //
    // ========================================================

    _tail =
        result.then<
          void
        >(
          (
            _,
          ) {},
          onError:
              (
                Object error,
                StackTrace stackTrace,
              ) {
                // O erro é absorvido apenas pela cauda interna da fila.
                //
                // `result` continua contendo o erro original e será
                // propagado normalmente para o chamador.
              },
        );

    return result;
  }

  // ============================================================
  // SETTLE
  // ============================================================

  /// Aguarda tudo que já foi serializado na fila.
  Future<
    void
  >
  settle() {
    return _tail;
  }

  // ============================================================
  // ENSURE
  // ============================================================

  Future<
    void
  >
  ensure(
    String userId,
  ) {
    final String? owner = _normalize(
      userId,
    );

    if (owner ==
        null) {
      return Future<
        void
      >.error(
        StateError(
          'Usuário autenticado obrigatório.',
        ),
      );
    }

    // ========================================================
    // DEFINE A IDENTIDADE DESEJADA
    // ========================================================

    setUser(
      owner,
    );

    // ========================================================
    // JÁ INICIALIZADO
    // ========================================================

    if (_readyUserId ==
            owner &&
        _normalize(
              currentUserId(),
            ) ==
            owner) {
      return Future<
        void
      >.value();
    }

    // ========================================================
    // INICIALIZAÇÃO JÁ EM ANDAMENTO
    // ========================================================

    final Future<
      void
    >?
    existing = _pending;

    if (existing !=
        null) {
      return existing;
    }

    // ========================================================
    // GERAÇÃO
    // ========================================================
    //
    // Cada troca de identidade incrementa `_generation`.
    //
    // Uma operação iniciada em uma geração anterior deixa de
    // ser válida imediatamente.
    //
    // ========================================================

    final int generation = _generation;

    void check() {
      final bool generationChanged =
          generation !=
          _generation;

      final bool ownerChanged =
          _desiredUserId !=
          owner;

      final bool authenticatedUserChanged =
          _normalize(
            currentUserId(),
          ) !=
          owner;

      if (generationChanged ||
          ownerChanged ||
          authenticatedUserChanged) {
        throw const AccountStartupCancelled();
      }
    }

    // ========================================================
    // INITIALIZATION
    // ========================================================

    late final Future<
      void
    >
    pending;

    pending = _enqueue(
      () async {
        // ====================================================
        // DRAIN
        // ====================================================
        //
        // Executamos stop novamente mesmo que algum stop
        // enfileirado anteriormente tenha falhado.
        //
        // Isso garante que a nova inicialização não reutilize
        // recursos parcialmente pertencentes à conta anterior.
        //
        // ====================================================

        await stop();

        check();

        try {
          await initialize(
            owner,
            check,
          );

          check();

          _readyUserId = owner;
        } catch (
          _
        ) {
          // ==================================================
          // INVALIDAR IDENTIDADE
          // ==================================================

          onIdentityChanged(
            null,
          );

          // ==================================================
          // LIMPEZA APÓS FALHA
          // ==================================================
          //
          // Tentamos parar recursos parcialmente inicializados.
          //
          // Se este stop também falhar, preservamos o erro
          // original da inicialização.
          //
          // A próxima tentativa executará stop novamente antes
          // de inicializar.
          //
          // ==================================================

          try {
            await stop();
          } catch (
            _
          ) {
            // Ignoramos apenas esta falha secundária de cleanup.
          }

          rethrow;
        }
      },
    );

    _pending = pending;

    // ========================================================
    // LIMPAR PENDING
    // ========================================================
    //
    // Limpamos somente se `_pending` ainda for exatamente esta
    // tentativa.
    //
    // Isso impede que uma operação antiga apague a referência
    // de uma tentativa mais nova.
    //
    // ========================================================

    unawaited(
      pending.then<
        void
      >(
        (
          _,
        ) {
          if (identical(
            _pending,
            pending,
          )) {
            _pending = null;
          }
        },
        onError:
            (
              Object error,
              StackTrace stackTrace,
            ) {
              if (identical(
                _pending,
                pending,
              )) {
                _pending = null;
              }
            },
      ),
    );

    return pending;
  }
}
