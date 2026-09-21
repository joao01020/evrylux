# EVRYLUX Owner Permissions — V4 CSS FIX

Correção visual da página `/colab/admins`.

## Problema corrigido

Os cards de administrador e as entradas de auditoria são criados pelo JavaScript
com `innerHTML`. O Astro aplicava escopo automático ao `<style>`, mas os elementos
criados depois pelo navegador não recebiam o atributo de escopo do Astro.

Resultado: o HTML aparecia praticamente sem estilo, como no print:
- avatar sem círculo;
- badges "Proprietário" e "Você" sem formato;
- nome/e-mail soltos;
- bloco "Controle total" sem card;
- auditoria sem layout.

## Correção

O CSS da página passou para:

```astro
<style is:global>
```

Assim os elementos criados dinamicamente recebem os estilos corretamente.

Nenhuma regra de owner, permissões, Supabase ou auditoria foi removida.

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core
unzip -o ~/Downloads/EVRYLUX_OWNER_PERMISSIONS_V4_CSS_FIX.zip -d .
```

## Testar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/website
rm -rf .astro
npm run build
npm run dev
```

Depois faça `Ctrl + Shift + R` no navegador.
