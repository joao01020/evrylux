#!/usr/bin/env python3
"""Compose and sign a single cross-platform release manifest."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from build_release import read_private, sign_manifest, source_version

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--key', required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--data-schema', type=int, required=True)
    parser.add_argument('--out', required=True)
    parser.add_argument('assets', nargs='+')
    args = parser.parse_args()
    assets = [json.loads(Path(path).read_text()) for path in args.assets]
    identities = [(a['platform'], a['architecture']) for a in assets]
    if len(set(identities)) != len(identities):
        raise RuntimeError('Pacotes duplicados para a mesma plataforma/arquitetura.')
    manifest = {
        'schema': 1, 'appId': 'evrylux', 'channel': 'stable',
        'version': args.version,
        'publishedAt': datetime.now(timezone.utc).isoformat(),
        'minDataSchema': args.data_schema,
        'maxDataSchema': args.data_schema,
        'dataSchema': args.data_schema,
        'assets': assets,
    }
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(sign_manifest(manifest, read_private(args.key)), indent=2) + '\n')
    print('Manifesto assinado:', out)

if __name__ == '__main__':
    main()
