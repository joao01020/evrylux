# EVRYLUX — Foto de perfil

Este pacote adiciona upload real de foto de perfil usando Supabase Storage.

## O que muda

- O antigo `E` deixa de ser o avatar padrão.
- Sem foto, aparece um avatar genérico cinza.
- O colaborador pode escolher JPG, PNG ou WebP.
- Limite de 5 MB.
- A foto é enviada ao bucket `profile-avatars`.
- `member_profiles.avatar_url` continua sendo usado, então o restante do sistema permanece compatível.
- O dashboard também usa o avatar padrão genérico quando não existe foto.

## Instalar arquivos

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_PROFILE_PHOTO.zip -d .
```

## Configurar Supabase

Abra o SQL Editor e execute todo o conteúdo de:

```text
website/supabase/profile_avatars.sql
```

## Testar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
npm run build
npm run dev
```

Abra:

```text
http://localhost:4321/colab/profile
```
