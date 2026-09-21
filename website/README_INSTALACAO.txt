EVRYLUX — FILA DO DEMO + EARLY EXPLORERS

O pacote adiciona:

PÚBLICO
- Página Download atualizada
- Linux / Windows / macOS clicáveis
- Ao clicar, o sistema já fica selecionado
- Formulário rápido:
  Nome completo
  E-mail
  Sistema (automático)
  Área que mais quer testar
  Checkbox para ajudar com feedback e bugs
- Inscrição Early Explorer
- Mensagem de prioridade e vantagens especiais de lançamento
- Confirmação após entrar na fila

ADMINISTRADOR
- Notificação no Header somente para administradores
- Badge com quantidade de novas inscrições
- Ao clicar, abre:
  /colab/demo
- Tela com:
  Total de inscritos
  Quantos querem reportar feedback/bugs
  Contagem Linux
  Contagem Windows/macOS
  Lista de usuários
  E-mail
  Sistema
  Interesse
  Early Explorer
  Status: Aguardando / Convidado / Testando
- Ao abrir a fila, as notificações atuais são marcadas como lidas.

BANCO
- tabela public.demo_waitlist
- RLS:
  público só pode INSERIR
  somente administradores podem LER/ATUALIZAR
- e-mails da fila não ficam públicos

REQUISITO
Este pacote pressupõe que o sistema de administradores já está instalado,
incluindo a função Supabase:

public.is_colab_admin()

INSTALAÇÃO

1. Entre no site:

cd ~/Documentos/PlatformIO/Projects/ghost-core/website

2. Extraia:

unzip -o ~/Downloads/EVRYLUX_DEMO_WAITLIST.zip -d .

3. Abra o Supabase:
SQL Editor -> New query

Cole e execute TODO o conteúdo de:

supabase/demo_waitlist.sql

4. Se o Astro já estiver rodando, basta atualizar o navegador.

Se quiser reiniciar:

npx astro dev stop
npm run dev

TESTAR PÚBLICO

http://localhost:4321/download

TESTAR ADMIN

Entre com sua conta de administrador e abra:

http://localhost:4321/colab/demo

Quando um novo usuário preencher o formulário, o administrador verá
um indicador de notificação no Header.

OBSERVAÇÃO

"Vantagens especiais" foi deixado propositalmente sem prometer
gratuidade vitalícia, desconto específico ou quantidade fechada.
Isso permite decidir a recompensa real mais perto do lançamento.
