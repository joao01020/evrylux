# EVRYLUX OWNER PERMISSIONS — V3

Esta versão corrige de forma ampla os erros PostgreSQL `42P13 cannot change return type of existing function`.

Antes de recriar as RPCs, o SQL remove todas as assinaturas antigas usadas pelo novo sistema de proprietário e permissões.

Não apaga usuários, perfis ou papéis existentes.

# Correção de compatibilidade SQL

Esta versão corrige o erro PostgreSQL `42P13 cannot change return type of existing function` removendo as RPCs antigas `list_colab_admins()` e `list_colab_admin_audit(integer)` antes de recriá-las com o novo `RETURNS TABLE`.

# EVRYLUX — Owner + permissões administrativas

Este pacote cria um modelo administrativo com menor privilégio:

- um único **Proprietário**;
- proprietário com acesso total;
- demais administradores começam sem permissões;
- proprietário escolhe manualmente cada permissão;
- administrador comum não pode remover o proprietário;
- somente o proprietário altera permissões;
- todas as alterações ficam registradas em auditoria;
- AAL2 continua separado das permissões.

## Arquivos

```text
website/src/lib/admin-permissions.ts
website/src/lib/admin-permission-guard.ts
website/src/pages/colab/admins.astro
website/supabase/admin_owner_permissions.sql
```

## 1. Instalar

Na raiz do repositório:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core

unzip -o ~/Downloads/EVRYLUX_OWNER_PERMISSIONS.zip -d .
```

## 2. Executar SQL no Supabase

Mostre o SQL no terminal:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
cat website/supabase/admin_owner_permissions.sql
```

Copie todo o conteúdo e execute em:

```text
Supabase
→ SQL Editor
→ New query
→ Run
```

## 3. Definir o proprietário pela primeira vez

A migration NÃO grava um e-mail nem UUID fixo.

Ela permite que a primeira conta que:

1. esteja autenticada;
2. já possua `role = 'admin'` em `colab_user_roles`;
3. acesse `/colab/admins`;

clique em:

```text
Tornar esta conta proprietária
```

Depois disso não é possível existir um segundo proprietário.

## 4. Testar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website

npm run build
npm run dev
```

Abra:

```text
http://localhost:4321/colab/admins
```

## 5. Como funciona

### Proprietário

Possui todas as permissões automaticamente:

```text
view_demo
manage_demo
view_support
reply_support
edit_roadmap
manage_admins
view_audit_logs
manage_notifications
manage_site_content
manage_security
```

### Novo administrador

Ao adicionar uma conta:

```text
permissions = []
```

Nada é liberado até o proprietário marcar e salvar.

## 6. IMPORTANTE: autorização real

A tela `/colab/admins` já usa as novas permissões.

Para que `/colab/demo`, `/colab/support`, edição do roadmap etc. também sejam
protegidos por permissões granulares, use:

```ts
import {
  requireAdminPermission,
} from '../../lib/admin-permission-guard';

const allowed =
  await requireAdminPermission(
    'view_demo',
    {
      requireAal2: true,
    },
  );

if (!allowed) {
  // a função redireciona automaticamente.
}
```

Mapeamento sugerido:

```text
/colab/demo
  leitura      -> view_demo
  alterações   -> manage_demo

/colab/support
  leitura      -> view_support
  responder    -> reply_support

/roadmap
  edição       -> edit_roadmap

/colab/admins
  adicionar/remover -> manage_admins
  permissões        -> proprietário

auditoria
  -> view_audit_logs
```

A regra deve existir no banco/RLS ou em RPCs para ações sensíveis. Esconder
botões no frontend não é autorização suficiente.

## 7. Commit

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core

git add \
  website/src/lib/admin-permissions.ts \
  website/src/lib/admin-permission-guard.ts \
  website/src/pages/colab/admins.astro \
  website/supabase/admin_owner_permissions.sql

git commit -m "feat: adiciona owner e permissoes administrativas granulares"

git push origin dev-stable
```
