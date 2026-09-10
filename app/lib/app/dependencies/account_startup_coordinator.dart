import 'dart:async';

/// Serializa a inicialização privada e invalida trabalhos de outra conta.
/// Não cria identidades locais nem substitui a autenticação.
class AccountStartupCancelled implements Exception {
  const AccountStartupCancelled();
}

class AccountStartupCoordinator {
  AccountStartupCoordinator({
    required this.currentUserId,
    required this.initialize,
    required this.stop,
    required this.onIdentityChanged,
  });

  final String? Function() currentUserId;
  final Future<void> Function(String userId, void Function() check) initialize;
  final Future<void> Function() stop;
  final void Function(String? userId) onIdentityChanged;

  String? _desiredUserId;
  String? _readyUserId;
  int _generation = 0;
  Future<void> _tail = Future<void>.value();
  Future<void>? _pending;

  String? get readyUserId => _readyUserId;

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void setUser(String? userId) {
    final next = _normalize(userId);
    if (next == _desiredUserId) return;
    _desiredUserId = next;
    _readyUserId = null;
    _pending = null;
    ++_generation;
    // Revoga o envio imediatamente; a parada/drain é serializada abaixo.
    onIdentityChanged(null);
    _enqueue(stop);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    // Uma falha anterior não pode impedir logout ou uma nova tentativa.
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> settle() => _tail;

  Future<void> ensure(String userId) {
    final owner = _normalize(userId);
    if (owner == null) {
      return Future<void>.error(StateError('Usuário autenticado obrigatório.'));
    }
    setUser(owner);
    if (_readyUserId == owner && _normalize(currentUserId()) == owner) {
      return Future<void>.value();
    }
    final existing = _pending;
    if (existing != null) return existing;
    final generation = _generation;
    void check() {
      if (generation != _generation ||
          _desiredUserId != owner ||
          _normalize(currentUserId()) != owner) {
        throw const AccountStartupCancelled();
      }
    }

    late final Future<void> pending;
    pending = _enqueue(() async {
      // Retry the drain even if an earlier queued stop failed.
      await stop();
      check();
      try {
        await initialize(owner, check);
        check();
        _readyUserId = owner;
      } catch (_) {
        onIdentityChanged(null);
        try {
          await stop();
        } catch (_) {
          // A próxima tentativa também exige um stop bem-sucedido.
        }
        rethrow;
      }
    });
    _pending = pending;
    // Limpa apenas a tentativa que terminou; permite retry após falha.
    unawaited(
      pending.then<void>(
        (_) {
          if (identical(_pending, pending)) _pending = null;
        },
        onError: (Object _, StackTrace __) {
          if (identical(_pending, pending)) _pending = null;
        },
      ),
    );
    return pending;
  }
}
