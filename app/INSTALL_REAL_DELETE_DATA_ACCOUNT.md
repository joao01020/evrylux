# EVRYLUX — Excluir dados / Excluir conta

Este patch transforma as duas ações da Zona de risco em operações reais.

## Arquivos Flutter

- `lib/profile/security/account/account_deletion_service.dart`
- `lib/profile/security/devices/services/account_device_identity_service.dart`
- `lib/app/dependencies/app_dependencies.dart`
- `lib/profile/screens/settings/actions/security_actions.dart`
- arquivos atuais de Sessões e dispositivos incluídos no ZIP para manter o conjunto consistente.

## Servidor

### 1. SQL Editor

Execute todo o conteúdo de:

`supabase/migrations/20260904_account_cleanup.sql`

A função `delete_evrylux_user_data_for(uuid)` é server-only e fica executável apenas por `service_role`.

### 2. Edge Function

Crie/deploy uma Edge Function chamada exatamente:

`account-cleanup`

Código:

`supabase/functions/account-cleanup/index.ts`

No Dashboard do Supabase, use Edge Functions e publique a função com esse nome.

Se futuramente estiver usando Supabase CLI:

```bash
supabase functions deploy account-cleanup
```

## Comportamento

### Excluir meus dados

1. valida a sessão na Edge Function;
2. remove arquivos dos buckets gerenciados pelo EVRYLUX;
3. remove registros remotos do usuário;
4. limpa `user_metadata` do Auth, mantendo o usuário;
5. somente após sucesso remoto remove dados locais, Vault/chave local e identidades locais do Brain;
6. mantém a conta Auth existente.

### Excluir conta

1. executa a mesma limpeza de dados;
2. remove o usuário de `auth.users` via Admin API server-side;
3. somente depois limpa dados e sessão locais.

## Importante

Teste primeiro com uma conta de desenvolvimento. As ações são destrutivas e permanentes.

Backups `.evbrain` que o usuário salvou manualmente fora das pastas gerenciadas pelo aplicativo não são apagados.
