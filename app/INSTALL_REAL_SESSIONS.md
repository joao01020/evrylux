# EVRYLUX — Sessões e dispositivos reais

Este pacote substitui o modal mockado por uma implementação baseada em dados reais do Supabase.

## O que foi criado

- `public.user_devices`
- RPC `register_user_device`
- RPC `touch_user_device`
- RPC `revoke_user_device`
- RPC `disconnect_current_user_device`
- identidade local persistente da instalação via `flutter_secure_storage`
- vínculo de cada registro com o `session_id` real do JWT Supabase
- heartbeat a cada 1 minuto
- lista real de sessões/dispositivos no modal
- contador real na tela Segurança
- botão `Encerrar` para outra sessão
- logout local automático no dispositivo revogado quando ele voltar a se comunicar
- encerramento do registro antes do logout normal do EVRYLUX

## Importante

Os dispositivos de conta são separados dos dispositivos autorizados do Brain/E2EE.
A segurança do Brain não foi alterada.

## 1. Aplicar o SQL no Supabase

Como o projeto não depende de Supabase CLI para esta instalação, abra:

Supabase Dashboard -> SQL Editor -> New query

Copie todo o conteúdo de:

`supabase/migrations/20260904_account_devices.sql`

e execute.

Depois confirme que existem estas quatro funções:

- `register_user_device`
- `touch_user_device`
- `revoke_user_device`
- `disconnect_current_user_device`

E a tabela:

- `user_devices`

## 2. Instalar os arquivos Flutter

Na raiz do app:

```bash
cd /home/joao/Documentos/PlatformIO/Projects/ghost-core/app
unzip -o "/home/joao/Downloads/evrylux_real_sessions_devices_v1.zip" -d .
```

## 3. Atualizar dependências e analisar

Nenhuma dependência nova foi adicionada. O projeto já possui `uuid` e `flutter_secure_storage`.

Rode:

```bash
flutter pub get
flutter analyze
```

Depois:

```bash
flutter run -d linux
```

## 4. Teste real com dois dispositivos/sessões

1. Abra o EVRYLUX no computador A e faça login.
2. Abra no computador B e faça login com a mesma conta.
3. Em Segurança -> Sessões e dispositivos -> Gerenciar, os dois registros devem aparecer.
4. No computador A, clique em `Encerrar` no computador B.
5. O computador B será marcado como revogado.
6. Quando B fizer o próximo heartbeat (até aproximadamente 1 minuto), ele executará `signOut(scope: local)` e sairá apenas daquela sessão.
7. Um novo login no computador B cria uma nova sessão real do Supabase e volta a ser permitido.

## Observação de segurança

A revogação do EVRYLUX é aplicada pelo heartbeat do aplicativo. O access token Supabase já emitido pode continuar válido até expirar, comportamento normal de JWT. O app alvo encerra a sessão local assim que detectar a revogação.
