# EVRYLUX Web Compatibility

Esta camada adiciona uma entrada Web isolada sem alterar o bootstrap desktop existente.

## Arquitetura

- `lib/main.dart`: permanece responsável pelo desktop.
- `lib/main_web.dart`: entrada Flutter Web.
- `lib/web_app/`: UI e integração Web do Brain.
- `brain_objects`: continua sendo a fonte remota E2EE.
- O formato `BrainVaultObject`, serializer, XChaCha20-Poly1305, `BrainSyncPayload` e RPC `upsert_brain_object_e2ee` são os mesmos do desktop.

## Segurança / novo navegador

O navegador é tratado como um novo dispositivo:

1. Login Supabase.
2. Descoberta/seleção do `vault_id`.
3. Geração local X25519 e registro via `register_brain_device`.
4. O navegador fica pendente e mostra o fingerprint.
5. Um dispositivo EVRYLUX já autorizado aprova o novo dispositivo.
6. O navegador consome o envelope com `claim_brain_device_envelope`.
7. A Master Key é desembrulhada localmente e persistida pelo `flutter_secure_storage` Web.
8. Conhecimentos são cifrados no navegador e enviados para `brain_objects`.

Use HTTPS em produção. O armazenamento seguro Web depende das garantias do navegador/origem e não é equivalente ao Keychain/Secret Service nativo.

## Build

```bash
./scripts/build_web.sh
```

Saída:

```text
build/web/
```

Essa pasta pode ser publicada no Cloudflare Pages.
