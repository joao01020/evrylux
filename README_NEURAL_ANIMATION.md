# EVRYLUX — Animação Neural do Cérebro

Este pacote substitui o mapa simples da home por uma rede neural viva e elegante.

## Inclui

- pulsos percorrendo as conexões;
- nós respirando suavemente;
- nó central com ondas de ativação;
- múltiplos sinais em diferentes ramificações;
- linhas pontilhadas em movimento;
- halos orgânicos de fundo;
- pequena reação ao movimento do mouse;
- suporte a `prefers-reduced-motion`;
- comportamento responsivo.

## Arquivos

- `website/src/components/home/NeuralBrainAnimation.astro`
- `website/src/pages/index.astro`

## Instalação

Na raiz do repositório:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_NEURAL_BRAIN_ANIMATION.zip -d .
```

## Executar

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
git add website/src/components/home/NeuralBrainAnimation.astro website/src/pages/index.astro
git commit -m "feat: adiciona animacao neural interativa ao Cerebro"
git push origin dev-stable
```
