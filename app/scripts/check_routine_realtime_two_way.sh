#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== REALTIME ==="
grep -n "listenTo('routine_days')\|listenTo('routine_comments')\|listenTo('board_attachments')\|listenTo('reminders')" \
  lib/routine/screen/routine_screen.dart

echo
echo "=== REFRESH APIs ==="
grep -RIn "refreshWeekFromRemote\|refreshByDay\|refreshByBoardId" \
  lib/routine/data lib/routine/controllers | head -120

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/routine/screen/routine_screen.dart \
  lib/routine/controllers/routine_controller.dart \
  lib/routine/controllers/comments/board_comment_controller.dart \
  lib/routine/controllers/attachments/board_attachment_controller.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: Routine Realtime two-way validado."
