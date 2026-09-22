# CHANGELOG — EVRYLUX Brain Production Delete/GC

## Phase 2 — Local purge seguro

### Criado

- `lib/study/brain/vault/compaction/brain_vault_compaction_ledger.dart`
  - ledger local técnico de deletion floors; sem plaintext.
  - motivo: permitir remover `.evobj` sem esquecer localmente a exclusão.
  - risco: corrupção do ledger bloqueia compaction/pull em modo fail-safe.

- `test/study/brain/vault/compaction/brain_vault_compaction_phase2_test.dart`
  - testes de purge, retenção, fila, confirmação remota e idempotência.

- `test/study/brain/sync/brain_cloud_pull_compaction_floor_test.dart`
  - testes contra re-download de tombstone e ressurreição ativa.

- `supabase/migrations/202609220001_harden_brain_object_tombstone_monotonicity.sql`
  - torna tombstone remoto irreversível no modelo atual.
  - cria RPC de confirmação usada pela compaction.
  - não remove registros e preserva RLS/auth.uid().

### Alterado

- `brain_vault_compaction_service.dart`
  - adiciona `compact()` real, dupla revalidação, ledger-before-delete e idempotência.

- `brain_vault_compaction_result.dart`
  - adiciona estado `purged` por entrada e bloqueio por mudança concorrente.

- `brain_vault_storage.dart`
  - adiciona persistência atômica do ledger e `purgeObjectPermanently()` com precondições.
  - `deleteObjectFile()` legado passa a rejeitar uso direto.

- `brain_supabase_e2ee_service.dart`
  - confirmação remota via RPC criado pela migration de Phase 2.
  - se a migration não estiver aplicada, o purge falha fechado.

- `brain_cloud_pull_service.dart`
  - respeita compaction floor e rejeita tentativa ativa de ressurreição.

- `brain_cloud_pull_result.dart`
  - observabilidade técnica para floors ignorados e ressurreições rejeitadas.

- `app_dependencies.dart`
  - liga confirmação remota real à política de compaction.
  - device coverage não bloqueia GC local porque o tombstone Cloud permanece; isso volta a ser requisito para GC remoto.

- documentação em `docs/` atualizada para Phase 2.

## Compatibilidade

- E2EE preservado.
- SyncQueue preservada.
- `deleteObject()` continua produzindo tombstone.
- Nenhum DELETE remoto foi introduzido.
- `legacy_path` não foi reintroduzido.
- Dados existentes continuam legíveis; nenhum dos tombstones atuais é purgado automaticamente.

## Risco operacional principal

`compact()` só deve ser usado depois da migration `202609220001_harden_brain_object_tombstone_monotonicity.sql` estar aplicada. O código confirma isso indiretamente ao depender do RPC criado pela mesma migration; sem ele, `remoteDeletionConfirmed=false` e o purge fica bloqueado.

# Phase 3 — Remote Delete GC

## Criados

- `supabase/migrations/202609220002_brain_remote_delete_gc.sql`
  - deletion floor remoto durável;
  - ACK por Brain device;
  - listagem conservadora de candidatos;
  - GC remoto transacional;
  - hardening do UPSERT contra ressurreição após remoção do tombstone completo.
- `lib/study/brain/sync/models/brain_remote_deletion_floor.dart`
  - modelo técnico de deletion floor e observação de tombstone.
- `lib/study/brain/sync/models/brain_remote_gc.dart`
  - candidato/relatório tipados.
- `lib/study/brain/sync/services/brain_remote_gc_service.dart`
  - `dryRun()` e `collect()` com limites conservadores.
- `test/study/brain/sync/brain_remote_gc_service_test.dart`
- `test/study/brain/sync/brain_cloud_pull_remote_floor_test.dart`

## Alterados

- `brain_remote_object_source.dart`: suporte compatível a deletion floors.
- `brain_supabase_e2ee_service.dart`: floors, ACK batch e RPCs de remote GC.
- `brain_cloud_pull_service.dart`: floors são processados antes dos objetos; ACKs são enviados em lote; estado local antigo é removido quando coberto por floor remoto.
- `brain_cloud_pull_result.dart`: métricas de Phase 3.
- `brain_e2ee_sync_coordinator.dart`: deletion floor conta como estado remoto e evita backfill indevido.
- `brain_vault_storage.dart`: purge com precondição para estado coberto por floor remoto.
- `app_dependencies.dart`: wiring de ACK e `brainRemoteGcService`.
- `brain_vault_compaction_service.dart`: inclui a correção validada pelo usuário para impedir regressão temporal do manifest.

## Compatibilidade e risco

- `BrainRemoteObjectSource.loadDeletionFloors()` possui implementação padrão vazia para não quebrar remotes/fakes existentes.
- Nenhum DELETE remoto é automático. `brainRemoteGcService.collect()` precisa ser invocado explicitamente.
- Default remoto: 180 dias + ACK de todos os devices atualmente authorized.
- Revogados deixam de bloquear; authorized offline continuam bloqueando.
- Floors remotos não são apagados nesta fase. Isso é intencional para proteção permanente contra ressurreição.
