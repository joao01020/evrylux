# EVRYLUX — Immersive Scroll Story

Este pacote adiciona à página inicial uma seção imersiva controlada pela rolagem.

## O que acontece na nova seção

A página fica temporariamente em uma cena "sticky" enquanto a rolagem controla a narrativa:

1. Uma ideia aparece.
2. A ideia entra no Cérebro.
3. Ela se transforma em um conceito.
4. Novas conexões surgem.
5. Uma pergunta abre uma nova direção.
6. Revisões e relações formam um mapa vivo.

A experiência inclui:

- rede neural animada em SVG;
- pulsos percorrendo conexões;
- nós surgindo progressivamente;
- cards de Conceito, Conexão, Pergunta e Revisão;
- profundidade em camadas;
- movimento 3D muito leve;
- reação ao mouse;
- progresso da narrativa ligado ao scroll;
- `position: sticky`;
- suporte a `prefers-reduced-motion`;
- fallback simplificado para telas menores.

## Arquivos incluídos

```text
website/
└── src/
    ├── components/
    │   └── home/
    │       ├── NeuralBrainAnimation.astro
    │       └── ImmersiveKnowledgeStory.astro
    └── pages/
        └── index.astro
```

O componente `NeuralBrainAnimation.astro` também está incluído para o pacote ser autocontido.

## Instalação

Execute na raiz do repositório:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_IMMERSIVE_SCROLL_STORY.zip -d .
```

## Executar localmente

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
npm run build
npm run dev
```

Abra:

```text
http://localhost:4321
```

## Commit

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core

git add \
  website/src/components/home/NeuralBrainAnimation.astro \
  website/src/components/home/ImmersiveKnowledgeStory.astro \
  website/src/pages/index.astro

git commit -m "feat: adiciona narrativa imersiva por scroll na home"
git push origin dev-stable
```
