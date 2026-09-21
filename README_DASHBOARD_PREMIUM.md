# EVRYLUX — Dashboard Colab Premium

Atualização visual completa do dashboard `/colab`.

Mantido:
- loader animado EVRYLUX;
- sessão e carregamento do perfil;
- avatar;
- badge de administrador;
- cards condicionais de admin;
- links existentes;
- lógica Supabase e autenticação.

Novo visual:
- hero premium no topo;
- bloco de perfil mais limpo;
- resumo com GitHub, disponibilidade e habilidades;
- coluna de acesso rápido moderna;
- ferramentas organizadas por contexto;
- cards menores, mais consistentes e mais elegantes;
- responsividade melhorada.

## Instalar

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core

unzip -o ~/Downloads/EVRYLUX_COLAB_DASHBOARD_PREMIUM.zip -d .
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
http://localhost:4321/colab
```
