import 'package:supabase_flutter/supabase_flutter.dart';

import '../runtime/routine_web_telegram_stub.dart';

import '../../reminders/controllers/reminder_controller.dart';

// ============================================================
// IMPLEMENTAÇÕES WEB DIRETAS
// ============================================================
//
// Este arquivo existe exclusivamente para o runtime Web.
//
// Os repositories Web são importados diretamente para evitar que o
// conditional export seja resolvido como Native durante a construção
// das dependências.
//
// Os controllers, por outro lado, continuam usando seus contratos
// públicos/conditional exports.
//
// Como o Dart Analyzer executado no Linux resolve esses contratos para
// as implementações Native, usamos `dynamic` somente na ponte entre
// repository Web e controller.
//
// No build Web:
//   conditional exports -> Web
//
// No Linux:
//   este arquivo não é usado em runtime.
//

import '../../reminders/data/reminder_repository_web.dart' as reminder_web;

import '../controllers/attachments/board_attachment_controller.dart';
import '../controllers/comments/board_comment_controller.dart';
import '../controllers/routine_controller.dart';

import '../data/attachments/board_attachment_repository_web.dart'
    as attachment_web;

import '../data/datasources/comments/board_comment_remote_data_source.dart';
import '../data/datasources/routine_remote_data_source.dart';

import '../data/repositories/comments/board_comment_repository_web.dart'
    as comment_web;

import '../data/repositories/supabase_routine_repository.dart';

// ============================================================
// SUPABASE
// ============================================================

final SupabaseClient _routineWebClient = Supabase.instance.client;

// ============================================================
// ROUTINE
// ============================================================

final RoutineRemoteDataSource _routineWebRemoteDataSource =
    RoutineRemoteDataSource(client: _routineWebClient);

final SupabaseRoutineRepository _routineWebRepository =
    SupabaseRoutineRepository(remoteDataSource: _routineWebRemoteDataSource);

// ============================================================
// COMMENTS
// ============================================================

final BoardCommentRemoteDataSource _routineWebCommentRemote =
    BoardCommentRemoteDataSource(client: _routineWebClient);

final comment_web.BoardCommentRepository _routineWebCommentRepository =
    comment_web.BoardCommentRepository(
      client: _routineWebClient,
      remoteDataSource: _routineWebCommentRemote,
    );

final dynamic _routineWebCommentRepositoryBridge = _routineWebCommentRepository;

final BoardCommentController boardCommentController = BoardCommentController(
  repository: _routineWebCommentRepositoryBridge,
);

// ============================================================
// ATTACHMENTS
// ============================================================

final attachment_web.BoardAttachmentRepository _routineWebAttachmentRepository =
    attachment_web.BoardAttachmentRepository(client: _routineWebClient);

final dynamic _routineWebAttachmentRepositoryBridge =
    _routineWebAttachmentRepository;

final BoardAttachmentController boardAttachmentController =
    BoardAttachmentController(
      repository: _routineWebAttachmentRepositoryBridge,
    );

// ============================================================
// REMINDERS
// ============================================================

final reminder_web.ReminderRepository _routineWebReminderRepository =
    reminder_web.ReminderRepository(client: _routineWebClient);

final dynamic _routineWebReminderRepositoryBridge =
    _routineWebReminderRepository;

final ReminderController reminderController = ReminderController(
  repository: _routineWebReminderRepositoryBridge,
);

// ============================================================
// ROUTINE CONTROLLER
// ============================================================

RoutineController createRoutineControllerForCurrentUser({String? userId}) {
  final injected = userId?.trim();

  final authenticated = _routineWebClient.auth.currentUser?.id.trim();

  final String? resolved = injected != null && injected.isNotEmpty
      ? injected
      : authenticated;

  if (resolved == null || resolved.isEmpty) {
    throw StateError(
      'Não existe identidade válida para inicializar a rotina Web.',
    );
  }

  return RoutineController(repository: _routineWebRepository, userId: resolved);
}

// ============================================================
// TELEGRAM - WEB
// ============================================================
//
// O app nativo fornece telegramConnectionController através de
// app_dependencies.dart.
//
// No Web, expomos uma implementação compatível para impedir que
// app_dependencies e SQLite entrem no bundle.
//
// O fluxo de conexão poderá ser implementado remotamente depois,
// sem carregar nenhuma dependência nativa.

final RoutineWebTelegramConnectionController telegramConnectionController =
    RoutineWebTelegramConnectionController();
