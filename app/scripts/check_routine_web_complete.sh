#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== ROTINA NA HOME WEB ==="
grep -n "Rotina\\|RoutineScreen" lib/welcome/welcome_screen_web.dart

echo
echo "=== RUNTIME WEB ==="
grep -n "createRoutineControllerForCurrentUser\\|boardCommentController\\|boardAttachmentController\\|reminderController" \
  lib/routine/runtime/routine_web_dependencies.dart

echo
echo "=== SEM DART:IO NOS ARQUIVOS WEB ==="
if grep -RIn "dart:io" \
  lib/routine/runtime/*_web.dart \
  lib/routine/data/attachments/*_web.dart \
  lib/routine/data/repositories/comments/*_web.dart \
  lib/reminders/data/*_web.dart \
  lib/routine/widgets/attachments/dialogs/*_web.dart \
  lib/routine/widgets/blocks/*_web.dart; then
  echo "ERRO: dart:io encontrado no runtime Web."
  exit 1
fi

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/welcome/welcome_screen_web.dart \
  lib/routine/screen/routine_screen.dart \
  lib/routine/runtime/routine_web_dependencies.dart \
  lib/routine/runtime/routine_window_api_web.dart \
  lib/routine/data/attachments/board_attachment_repository_web.dart \
  lib/routine/data/repositories/comments/board_comment_repository_web.dart \
  lib/reminders/data/reminder_repository_web.dart \
  lib/routine/widgets/attachments/dialogs/document_import_dialog_web.dart \
  lib/routine/widgets/blocks/photo_block_web.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: Rotina Web compilou."
echo
echo "Depois do build, publique novamente a pasta:"
echo "  $ROOT/build/web"
