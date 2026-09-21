# EVRYLUX — Troca de senha no perfil

Adiciona a seção **Alterar senha** em `/colab/profile`.

Fluxo:

1. usuário informa a senha atual;
2. informa a nova senha;
3. confirma a nova senha;
4. o sistema reautentica com `signInWithPassword`;
5. somente se a senha atual estiver correta chama `updateUser`;
6. senha é alterada.

Não requer nova tabela nem migration SQL.

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_PROFILE_PASSWORD.zip -d .
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
