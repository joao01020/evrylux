# EVRYLUX — Página de Documentação

Este pacote cria:

```text
/docs
```

e adiciona uma nova aba **Documentação** no Header público.

Também inclui:

```text
docs/EVRYLUX.md
```

como versão em Markdown para manter a documentação dentro do Git.

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core

unzip -o ~/Downloads/EVRYLUX_DOCUMENTACAO_SITE.zip -d .
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
http://localhost:4321/docs
```

## O que foi criado

```text
website/
├── src/
│   ├── components/
│   │   └── Header.astro
│   └── pages/
│       └── docs/
│           └── index.astro
│
docs/
└── EVRYLUX.md
```

A página possui:

- menu lateral;
- busca rápida;
- atalho `/` para focar a busca;
- navegação por âncoras;
- destaque da seção atual;
- layout responsivo;
- conteúdo sobre propósito, ecossistema, Cérebro, segurança, arquitetura,
  EVRYLUX Colab, desenvolvimento, deploy, open source e licença.

## Commit

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core

git add \
  website/src/components/Header.astro \
  website/src/pages/docs/index.astro \
  docs/EVRYLUX.md

git commit -m "feat: adiciona documentacao oficial do EVRYLUX"

git push origin dev-stable
```
