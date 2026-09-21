# EVRYLUX MFA / AAL2

Pacote para adicionar autenticação em dois fatores (TOTP) ao EVRYLUX Colab usando Supabase Auth.

## Inclui

- `website/src/lib/mfa.ts`
- `website/src/pages/colab/security.astro`
- `website/src/pages/colab/index.astro`
- `website/src/pages/roadmap.astro`
- `website/supabase/mfa_aal2.sql`

## Proteção

A função `public.is_colab_admin()` passa a retornar `true` somente quando:

1. o usuário possui `role = 'admin'`;
2. a sessão atual está em `aal2`.

Como as áreas administrativas já usam essa função/RLS, `/colab/admins`, `/colab/demo`, `/colab/support` e ações administrativas deixam de funcionar em AAL1.

O SQL também adiciona políticas RESTRICTIVE para as tabelas administrativas conhecidas.

## Instalação dos arquivos

Na raiz do repositório:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_MFA_AAL2.zip -d .
```

## Banco de dados

Depois abra o Supabase:

SQL Editor → New query

Cole e execute TODO o conteúdo de:

```text
website/supabase/mfa_aal2.sql
```

## Teste local

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
npm run build
npm run dev
```

Abra:

```text
http://localhost:4321/colab/security
```

## Primeiro uso

1. Faça login.
2. Entre em `/colab/security`.
3. Clique em `Configurar autenticador`.
4. Escaneie o QR Code com Google Authenticator, Microsoft Authenticator, Authy, 1Password etc.
5. Digite o código de 6 dígitos.
6. A sessão deve mostrar `AAL2 ativo`.

## Login seguinte

Depois de sair e entrar novamente, a senha cria uma sessão AAL1.

Para acessar funções administrativas, abra `/colab/security` e informe o código TOTP. Depois disso a sessão passa a AAL2.

## Importante

Não desative RLS.

A interface é apenas uma parte da proteção. A segurança real é reforçada no Supabase através do claim `aal` do JWT e das políticas RLS.
