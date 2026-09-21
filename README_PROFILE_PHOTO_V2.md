# EVRYLUX — Foto de perfil V2

Esta atualização mantém o upload de foto de perfil e troca o avatar padrão antigo por uma imagem mais elegante.

## O que mudou

- sem foto de perfil, aparece `/branding/default-profile-avatar.png`;
- removido o avatar padrão antigo desenhado por SVG;
- continua possível escolher JPG, PNG ou WebP;
- limite de 5 MB;
- upload continua usando o bucket `profile-avatars`;
- `member_profiles.avatar_url` continua sendo o campo usado pelo sistema;
- dashboard e página de perfil usam o mesmo avatar padrão.

## Instalação

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_PROFILE_PHOTO_V2.zip -d .
```

## Supabase

Se você já executou `website/supabase/profile_avatars.sql` anteriormente, não precisa executar novamente.

Se ainda não executou, abra o SQL Editor do Supabase e rode o conteúdo desse arquivo.

## Teste

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
npm run build
npm run dev
```

Abra:

```text
http://localhost:4321/colab/profile
```
