#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/app/widgets/web_global_header_shell.dart"

echo "=== HEADER REAGE À AUTENTICAÇÃO ==="
grep -n \
  "_authSubscription\\|onAuthStateChange\\|_handleAuthStateChange\\|_authenticated" \
  "$FILE"

echo
echo "=== HEADER NÃO DEPENDE DE PERFIL COMPLETO ==="
if grep -nE \
  "profileComplete|isProfileComplete|profile != null.*Header|profile == null.*Header" \
  "$FILE"; then
  echo "ERRO: header ainda parece condicionado ao perfil."
  exit 1
else
  echo "OK: header depende da sessão autenticada, não de perfil completo."
fi

echo
echo "=== ANALYZE ==="
flutter analyze "$FILE"

echo
echo "OK: header global acompanha login/logout de qualquer conta autenticada."
