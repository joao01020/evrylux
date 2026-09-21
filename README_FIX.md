# EVRYLUX — correção da narrativa imersiva

Correções:
- cards não ficam mais acumulados/empilhados;
- apenas o card da etapa atual aparece;
- mensagem final só aparece perto do fim da rolagem;
- título principal ficou menor e com mais respiro;
- texto explicativo ganhou mais espaço vertical;
- espaçamento entre conteúdo e barra de progresso foi aumentado;
- cards foram reposicionados para reduzir colisões.

Instalação:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_STORY_SPACING_FIX.zip -d .
```

Teste:

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
npm run build
npm run dev
```
