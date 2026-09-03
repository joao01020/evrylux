# EVRYLUX CÉREBRO — Fase 06 — Supabase E2EE

## Objetivo

Sincronizar o Vault do Cérebro sem enviar conteúdo lógico em plaintext.

Arquitetura:

```text
Vault local
↓
BrainVaultObject
↓
BrainSyncPayload
↓
SyncQueue
↓
SyncService
↓
BrainSupabaseE2eeService
↓
brain_objects
```

No download:

```text
brain_objects
↓
BrainSyncPayload
↓
validação estrutural
↓
validação AEAD + binding
↓
comparação object_version
↓
Vault local
```

## Invariantes

Nunca enviar para a SyncQueue E2EE ou Supabase:

```text
Master Key
question
answer
title
content
description
topic
source_note_path
source_note_title
```

A fila aceita somente `BrainVaultObject` já criptografado.

Exclusões são tombstones. Não usar hard delete remoto para objetos do Brain.

## Tabela

A migration:

```text
supabase/migrations/20260903_brain_objects_e2ee.sql
```

cria:

```text
brain_objects
```

com chave:

```text
user_id + vault_id + object_id
```

e RPC monotônico:

```text
upsert_brain_object_e2ee
```

Uma versão antiga não substitui uma versão remota mais nova.

## Local / Cloud

LOCAL:

```text
não cria novos itens brain_e2ee_object
não faz pull
```

CLOUD:

```text
Vault continua sendo a verdade local
objetos criptografados entram na fila
envio remoto exige autenticação
```

A fila pode ser preenchida enquanto o dispositivo está offline. A identidade do usuário é resolvida apenas no envio remoto.

## Tombstones

Um delete local produz:

```text
BrainVaultObject.deleted
```

e esse objeto é enviado usando:

```text
SyncOperation.update
```

Isso é proposital. O tombstone precisa manter:

```text
object_id
object_version
deleted_at
```

## Testes

```bash
flutter test \
test/study/brain/sync/brain_sync_payload_test.dart

flutter test \
test/study/brain/sync/brain_sync_queue_service_test.dart

flutter test \
test/study/brain/sync/brain_cloud_pull_service_test.dart
```

Todos:

```bash
flutter test test/study/brain/sync
```

Regressão:

```bash
flutter test test/study/brain
```

## Antes de marcar a Fase 06 como concluída

```text
[ ] migration SQL aplicada no Supabase
[ ] testes locais verdes
[ ] app_dependencies integrado
[ ] ReviewRepository integrado ao queue E2EE
[ ] criar review em Cloud gera brain_e2ee_object
[ ] SyncQueue não contém pergunta/resposta
[ ] row brain_objects criada
[ ] row contém ciphertext
[ ] fechar/reabrir mantém Vault
[ ] pull remoto validado
[ ] tombstone remoto validado
[ ] modo Local não envia nada
```
