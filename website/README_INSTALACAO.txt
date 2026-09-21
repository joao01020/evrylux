EVRYLUX COLAB — NOTAS RÁPIDAS COMPARTILHADAS

Este pacote adiciona:
- Card "Notas rápidas" no Studio, junto do Roadmap
- Página /colab/studio/notes
- Criar nota
- Editar nota
- Excluir nota
- Fixar/desfixar nota
- Mostrar autor
- Mostrar data relativa
- Seções Fixadas e Recentes
- Integração com Supabase

ARQUIVOS:
src/pages/colab/studio/index.astro
src/pages/colab/studio/notes.astro
src/components/colab/QuickNoteCard.astro
src/components/colab/QuickNoteModal.astro
src/lib/colab-notes.ts
supabase/colab_quick_notes.sql

INSTALAÇÃO:

1. Pare o Astro.

2. Entre no website:

cd ~/Documentos/PlatformIO/Projects/ghost-core/website

3. Extraia:

unzip -o ~/Downloads/EVRYLUX_COLAB_SHARED_NOTES.zip -d .

4. No Supabase:
SQL Editor -> New query

Cole e execute o conteúdo de:

supabase/colab_quick_notes.sql

5. Inicie o Astro:

npm run dev

6. Abra:

http://localhost:4321/colab/studio

Notas:

http://localhost:4321/colab/studio/notes

Nenhuma alteração é necessária em:
- member_profiles
- roadmap
- presence
