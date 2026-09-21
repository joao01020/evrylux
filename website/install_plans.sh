#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
HEADER="$ROOT/src/components/Header.astro"

echo
echo "EVRYLUX — instalando página de Planos"
echo "--------------------------------------"

if [ ! -f "$ROOT/src/pages/plans.astro" ]; then
  echo "Erro: src/pages/plans.astro não encontrado."
  echo "Execute este script dentro da pasta website depois de extrair o ZIP."
  exit 1
fi

if [ ! -f "$HEADER" ]; then
  echo "Aviso: src/components/Header.astro não encontrado."
  echo "A página /plans foi instalada, mas o link do menu não pôde ser adicionado."
  exit 0
fi

if grep -q 'href="/plans"' "$HEADER"; then
  echo "✓ Link Planos já existe no Header."
  exit 0
fi

BACKUP="$HEADER.backup-before-plans"
cp "$HEADER" "$BACKUP"
echo "✓ Backup criado: $BACKUP"

python3 - "$HEADER" <<'PY'
from pathlib import Path
import sys, re

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

link = '\n      <a href="/plans">Planos</a>\n'

patterns = [
    r'(?P<block><a[^>]*href="/roadmap"[^>]*>.*?</a>)',
    r'(?P<block><a[^>]*href="/download"[^>]*>.*?</a>)',
    r'(?P<block><a[^>]*href="/contributors"[^>]*>.*?</a>)',
]

for pattern in patterns:
    match = re.search(pattern, text, flags=re.S)
    if match:
        end = match.end("block")
        text = text[:end] + link + text[end:]
        path.write_text(text, encoding="utf-8")
        print("✓ Link Planos adicionado ao Header.")
        break
else:
    print("Aviso: não encontrei Roadmap, Download ou Colaboradores no Header.")
    print('Adicione manualmente: <a href="/plans">Planos</a>')
PY

echo
echo "Instalação concluída."
echo "Abra: http://localhost:4321/plans"
echo
