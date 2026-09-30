#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== ROTINA USA O MESMO CALENDÁRIO DO ESTUDAR ==="
grep -n \
  "StudyCalendar\\|_routineCalendarContentDates" \
  lib/routine/screen/routine_screen.dart

echo
echo "=== ROTINA NÃO USA MAIS O CALENDÁRIO ANTIGO ==="
if grep -n \
  "RoutineCalendarPanel" \
  lib/routine/screen/routine_screen.dart; then
  echo "ERRO: RoutineScreen ainda referencia RoutineCalendarPanel."
  exit 1
else
  echo "OK: RoutineCalendarPanel removido do fluxo da tela."
fi

echo
echo "=== STUDYCALENDAR CONTINUA COMPATÍVEL ==="
grep -n \
  "onPreviousWeek\\|onNextWeek\\|compact" \
  lib/widgets/generic/study_calendar.dart

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/widgets/generic/study_calendar.dart \
  lib/routine/screen/routine_screen.dart

echo
echo "OK: Rotina e Estudar compartilham o mesmo calendário."
