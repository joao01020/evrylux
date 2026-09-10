import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:EVRYLUX/app/dependencies/account_startup_coordinator.dart';

void main() {
  test('sem sessão não inicializa o Vault', () async {
    String? current;
    var calls = 0;
    final coordinator = AccountStartupCoordinator(
      currentUserId: () => current,
      initialize: (user, check) async {
        calls++;
      },
      stop: () async {},
      onIdentityChanged: (_) {},
    );
    coordinator.setUser(null);
    await coordinator.settle();
    expect(calls, 0);
    await expectLater(
      coordinator.ensure('a'),
      throwsA(isA<AccountStartupCancelled>()),
    );
    expect(calls, 0);
  });

  test('login repetido compartilha a inicialização', () async {
    String? current = 'a';
    var calls = 0;
    final entered = Completer<void>();
    final release = Completer<void>();
    final coordinator = AccountStartupCoordinator(
      currentUserId: () => current,
      initialize: (user, check) async {
        calls++;
        entered.complete();
        await release.future;
        check();
      },
      stop: () async {},
      onIdentityChanged: (_) {},
    );
    final first = coordinator.ensure('a');
    final second = coordinator.ensure('a');
    expect(identical(first, second), isTrue);
    await entered.future;
    release.complete();
    await Future.wait([first, second]);
    expect(calls, 1);
    await coordinator.ensure('a');
    expect(calls, 1);
  });

  test('troca de conta invalida o trabalho anterior', () async {
    String? current = 'a';
    final entered = Completer<void>();
    final release = Completer<void>();
    final started = <String>[];
    final coordinator = AccountStartupCoordinator(
      currentUserId: () => current,
      initialize: (user, check) async {
        started.add(user);
        if (user == 'a') {
          entered.complete();
          await release.future;
        }
        check();
      },
      stop: () async {},
      onIdentityChanged: (_) {},
    );
    final first = coordinator.ensure('a');
    await entered.future;
    current = 'b';
    coordinator.setUser('b');
    final second = coordinator.ensure('b');
    final cancelled = expectLater(
      first,
      throwsA(isA<AccountStartupCancelled>()),
    );
    release.complete();
    await cancelled;
    await second;
    expect(started, ['a', 'b']);
    expect(coordinator.readyUserId, 'b');
  });

  test('falha de stop bloqueia inicialização e permite retry', () async {
    String? current = 'a';
    var failStop = true;
    var calls = 0;
    final coordinator = AccountStartupCoordinator(
      currentUserId: () => current,
      initialize: (user, check) async {
        calls++;
      },
      stop: () async {
        if (failStop) throw StateError('drain failed');
      },
      onIdentityChanged: (_) {},
    );
    await expectLater(coordinator.ensure('a'), throwsStateError);
    expect(calls, 0);
    failStop = false;
    await coordinator.ensure('a');
    expect(calls, 1);
  });

  test('falha de inicialização revoga sync e permite retry', () async {
    String? current = 'a';
    var calls = 0;
    final changes = <String?>[];
    final coordinator = AccountStartupCoordinator(
      currentUserId: () => current,
      initialize: (user, check) async {
        calls++;
        if (calls == 1) throw StateError('vault unavailable');
      },
      stop: () async {},
      onIdentityChanged: changes.add,
    );
    await expectLater(coordinator.ensure('a'), throwsStateError);
    expect(changes.last, isNull);
    await coordinator.ensure('a');
    expect(calls, 2);
    expect(coordinator.readyUserId, 'a');
  });
}
