# EVRYLUX Owner Permissions — V5

Agora o fluxo de adicionar administrador funciona assim:

1. Digite o e-mail.
2. Clique em `Consultar`.
3. O sistema busca a conta no Supabase Auth.
4. Mostra nome, e-mail, avatar, papel atual e permissões já existentes.
5. Você marca/desmarca as permissões desejadas.
6. Clica em `Adicionar administrador`.
7. O usuário é promovido e as permissões escolhidas são salvas.

Se a conta já for admin, o mesmo fluxo permite revisar e atualizar as permissões.

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_OWNER_PERMISSIONS_V5_PREVIEW.zip -d .
```

## Atualizar SQL

Depois da instalação:

```bash
cat website/supabase/admin_owner_permissions.sql
```

Copie o SQL completo e execute no Supabase SQL Editor.

## Testar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
rm -rf .astro
npm run build
npm run dev
```

Abra:

```text
http://localhost:4321/colab/admins
```
