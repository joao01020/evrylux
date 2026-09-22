# Supabase Auth — proteção real contra brute force

O login `signInWithPassword()` acontece no **Supabase Auth (GoTrue)** antes do PostgreSQL.
Por isso, um `CREATE POLICY` ou uma tabela SQL não consegue impedir diretamente uma
tentativa de senha errada.

A proteção real contra brute force deve existir no **Supabase Auth**.

## Configure no Dashboard

Abra seu projeto Supabase e vá em:

**Authentication → Rate Limits**

Revise os limites disponíveis para autenticação. Os nomes podem variar conforme a versão
do Dashboard, mas procure controles equivalentes a:

- login / token endpoint;
- cadastro;
- recuperação de senha;
- envio de e-mail;
- OTP / MFA;
- refresh de sessão.

Use limites conservadores para o portal do EVRYLUX, principalmente porque o Colab não é
um login de grande volume.

## Configurações de Auth que valem revisar

Em **Authentication → Providers / Settings**:

- confirmação de e-mail;
- senha mínima adequada;
- proteção contra senhas comprometidas, se disponível;
- MFA/TOTP para contas administrativas;
- redirect URLs somente dos domínios realmente usados;
- Site URL correta;
- remover redirects antigos/de desenvolvimento em produção.

## MFA/AAL2

A migration `20260921_security_hardening.sql` exige AAL2 dentro do banco nas ações
administrativas sensíveis:

- definir owner;
- adicionar admin;
- alterar permissões;
- remover admin;
- visualizar auditoria.

Isso significa que esconder um botão no frontend não é suficiente. A própria RPC rejeita
a operação se o JWT não estiver em `aal2`.

## O que NÃO fazer

Não coloque `service_role` no website, no JavaScript do navegador ou em `.env` público.

No Astro/Vite, qualquer variável exposta ao cliente deve ser tratada como pública.
A chave `anon` / publishable é feita para o cliente; `service_role` não é.

## Teste

1. Entre sem completar MFA.
2. Tente executar uma ação administrativa sensível.
3. A RPC deve retornar erro de AAL2.
4. Complete o TOTP.
5. Tente novamente.
6. A operação deve prosseguir apenas se a permissão também for válida.

Autenticação forte e autorização são verificações diferentes:
- AAL2 = força da sessão.
- permissão = autorização para executar a ação.
