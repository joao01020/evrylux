# EVRYLUX CÉREBRO — Fase 7: Dispositivos autorizados

Esta fase adiciona identidade por instalação, autorização explícita de novos dispositivos e transferência E2EE da Master Key.

## Fluxo

```text
A autorizado -> B pending -> comparar fingerprint -> A cifra Master Key para public key de B -> Supabase guarda envelope -> B abre envelope -> importa Master Key no secure storage existente
```

## Invariantes

- private key X25519: somente secure storage local;
- segredo de autorização do dispositivo: somente secure storage local;
- servidor armazena apenas SHA-256 desse segredo;
- Master Key nunca vai em plaintext para Supabase;
- segundo dispositivo começa pending;
- somente dispositivo autorizado aprova/revoga;
- primeiro dispositivo de um Vault é bootstrapado como authorized;
- comparação de fingerprint é obrigatória antes de aprovar;
- revogação bloqueia novas autorizações, mas não apaga chaves já copiadas;
- rotação completa da Master Key continua sendo uma etapa posterior.

## Integração com a Master Key existente

Use `BrainDeviceMasterKeyPort`. Ele existe para NÃO duplicar o BrainKeyService nem criar outro storage de Master Key.

A integração deve fornecer:

```text
exportMasterKey(vaultId)
importMasterKey(vaultId,keyVersion,masterKeyBytes)
```

usando o BrainKeyService/BrainPlatformKeyStorage já existente.

## Migração

Aplicar:

```text
supabase/migrations/20260903_brain_authorized_devices.sql
```

## Testes

```bash
flutter test test/study/brain/devices
```
