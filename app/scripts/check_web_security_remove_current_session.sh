#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/profile/screens/web_profile_settings_page.dart"

echo "=== VERIFICANDO REMOÇÃO ==="

if grep -n "Sessão Web atual" "$FILE"; then
  echo "ERRO: bloco 'Sessão Web atual' ainda existe."
  exit 1
fi

if grep -n "Esta sessão usa o login atual do Supabase" "$FILE"; then
  echo "ERRO: texto explicativo ainda existe."
  exit 1
fi

echo "OK: bloco removido."

echo
echo "=== SEGURANÇA PRESERVADA ==="
grep -n "E-mail da conta\\|Altere sua senha de acesso" "$FILE"

echo
echo "=== ANALYZE ==="
flutter analyze "$FILE"

echo
echo "OK: configuração Web de Segurança validada."
