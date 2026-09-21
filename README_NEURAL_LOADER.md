# EVRYLUX Neural Loader

Loading sem texto, baseado na identidade visual do EVRYLUX.

O componente combina:
- logo EVRYLUX no centro;
- nós inspirados em neurônios;
- linhas pontilhadas de conexão;
- pulsos viajando entre os nós;
- respiração suave do núcleo;
- pequeno brilho/estrela da identidade visual;
- suporte a `prefers-reduced-motion`.

## Arquivos

```text
website/src/components/ui/EvryluxNeuralLoader.astro
website/public/branding/evrylux-loader-logo.png
website/src/pages/loader-demo.astro
```

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_NEURAL_LOADER.zip -d .
```

## Executar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
npm run build
npm run dev
```

Teste em:

```text
http://localhost:4321/loader-demo
```

## Usar em uma página

Importe:

```astro
---
import EvryluxNeuralLoader from '../../components/ui/EvryluxNeuralLoader.astro';
---
```

Substitua:

```astro
<div id="profile-loading">
  Carregando perfil...
</div>
```

por:

```astro
<EvryluxNeuralLoader
  id="profile-loading"
  size="md"
/>
```

A lógica que você já usa para esconder o loading pode continuar igual:

```ts
loading?.classList.add('member-hidden');
content?.classList.remove('member-hidden');
```

## Loading de tela inteira

```astro
<EvryluxNeuralLoader
  id="page-loading"
  size="lg"
  fullscreen
/>
```

## Tamanhos

```astro
<EvryluxNeuralLoader size="sm" />
<EvryluxNeuralLoader size="md" />
<EvryluxNeuralLoader size="lg" />
```

## Remover a página de demonstração depois

```bash
rm website/src/pages/loader-demo.astro
```
