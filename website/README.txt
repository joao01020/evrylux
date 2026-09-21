EVRYLUX Colab — Studio + Online agora

Arquivos incluídos:
- src/components/colab/ColabNav.astro
- src/lib/colab-presence.ts
- src/pages/colab/studio.astro

Como instalar:
1. Extraia o ZIP dentro da pasta `website`.
2. Permita sobrescrever `src/components/colab/ColabNav.astro`.
3. Reinicie o Astro com `npm run dev`.
4. Acesse `/colab/studio`.

O recurso usa Supabase Realtime Presence e a tabela existente `member_profiles`.
Nenhuma nova tabela SQL é necessária para "Online agora".
