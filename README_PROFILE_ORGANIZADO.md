# EVRYLUX — Perfil organizado

Atualização visual completa da página `/colab/profile`.

Mantido:
- edição de nome, GitHub, bio, área, disponibilidade e skills;
- upload e remoção de foto;
- prévia do perfil;
- troca de senha exigindo senha atual;
- indicador de força da senha;
- integração existente com Supabase.

Novo layout:
- resumo do perfil no topo;
- informações agrupadas em seções;
- foto de perfil como seção própria;
- botão Salvar perfil em rodapé organizado;
- segurança em coluna lateral;
- card de dica de segurança;
- responsividade melhorada.

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_PROFILE_ORGANIZADO.zip -d .
```

## Testar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
rm -rf .astro
npm run build
npm run dev
```

Abra:

```text
http://localhost:4321/colab/profile
```
