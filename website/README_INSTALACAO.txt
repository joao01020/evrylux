EVRYLUX — SUPORTE EM TEMPO REAL

O pacote adiciona:

PÚBLICO
- nova aba "Suporte" no Header
- nova página /support
- usuário começa conversa sem cadastro
- mensagens chegam ao painel administrativo
- resposta do administrador aparece em tempo real
- se não houver resposta administrativa após 1 minuto:
  aparece um campo pedindo e-mail
- o usuário pode continuar a conversa mesmo sem informar e-mail
- a conversa é restaurada no mesmo navegador usando um token local

ADMIN
- nova página /colab/support
- somente administradores conseguem acessar
- lista de atendimentos
- histórico da conversa
- responder em tempo real
- marcar atendimento como Aberto / Encerrado
- e-mail aparece quando o usuário fornecer
- notificação no Header para novas mensagens enquanto o admin está logado

SEGURANÇA
- público NÃO recebe SELECT direto das tabelas
- o histórico público é acessado por um token aleatório de 256 bits
- RLS protege tickets e mensagens
- apenas admin pode ler diretamente as tabelas
- respostas administrativas exigem public.is_colab_admin()

REQUISITO
O sistema de administradores precisa estar instalado, incluindo:

public.is_colab_admin()

INSTALAÇÃO

1. Entre no website:

cd ~/Documentos/PlatformIO/Projects/ghost-core/website

2. Extraia:

unzip -o ~/Downloads/EVRYLUX_SUPPORT_REALTIME.zip -d .

3. No Supabase:

SQL Editor -> New query

Cole e execute TODO o conteúdo:

supabase/support_realtime.sql

4. Se o Astro já estiver rodando:
Ctrl + Shift + R

Ou reinicie:

npx astro dev stop
npm run dev

TESTAR USUÁRIO

http://localhost:4321/support

TESTAR ADMINISTRADOR

http://localhost:4321/colab/support

TESTE COMPLETO

1. Abra /support em uma janela anônima.
2. Envie uma mensagem.
3. Na sua sessão de administrador, deve aparecer a notificação "S" no Header.
4. Abra /colab/support.
5. Selecione a conversa e responda.
6. A resposta deve aparecer na janela do usuário sem recarregar.
7. Para testar o pedido de e-mail, envie uma mensagem e aguarde 60 segundos sem responder.

ARQUIVOS

src/components/Header.astro
src/lib/support.ts
src/pages/support.astro
src/pages/colab/support.astro
supabase/support_realtime.sql
README_INSTALACAO.txt
