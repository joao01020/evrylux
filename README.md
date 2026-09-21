# EVRYLUX

EVRYLUX é um projeto open source voltado à organização de conhecimento, evolução
pessoal e acompanhamento de diferentes áreas da vida em uma única experiência.

O projeto está sendo desenvolvido como um ecossistema modular. A ideia central é
permitir que conhecimento, finanças, treino, rotina e outras áreas possam ser
acompanhadas de forma estruturada, visual e progressiva, mantendo uma
experiência simples para o usuário.

> **Status:** em desenvolvimento ativo.

---

## Visão

O EVRYLUX nasceu da ideia de transformar informações soltas em algo que continue
evoluindo com o usuário.

Em vez de funcionar apenas como um bloco de notas, o objetivo é criar uma
estrutura onde seja possível registrar conceitos, perguntas, revisões, conexões,
progresso e contexto ao longo do tempo.

A proposta é que o sistema ajude o usuário a enxergar:

- o que aprendeu;
- o que ainda não entendeu;
- o que precisa revisar;
- como diferentes conhecimentos se conectam;
- como seu progresso evolui com o tempo;
- como diferentes áreas da vida podem ser acompanhadas em um mesmo ecossistema.

---

# Ecossistema EVRYLUX

O EVRYLUX está sendo organizado em diferentes áreas.

## Brain

O **EVRYLUX Brain** é a área de conhecimento do projeto.

Ele foi pensado para transformar anotações em conhecimento estruturado.

Entre os conceitos trabalhados atualmente estão:

- conceitos;
- perguntas;
- revisões;
- busca;
- histórico;
- áreas de conhecimento;
- conexões entre ideias;
- mapa visual do conhecimento;
- organização automática;
- offline-first;
- sincronização entre dispositivos;
- proteção dos dados do usuário.

### Conceitos

Um conceito representa algo aprendido pelo usuário.

Exemplo:

```text
Título:
Estado em Flutter

O que você aprendeu?
Estado representa informações que podem mudar durante a execução
da interface e provocar uma nova renderização.

Detalhes opcionais:
- exemplo;
- ponto de atenção;
- fonte.
```

### Perguntas

Perguntas representam aquilo que ainda precisa ser entendido, investigado ou
retomado.

Exemplo:

```text
Como o Flutter decide quais widgets precisam ser reconstruídos?
```

A intenção é manter dúvidas importantes visíveis dentro do contexto do
conhecimento do usuário.

### Revisões

O sistema de revisão permite retomar conteúdos importantes e reforçar
conhecimentos ao longo do tempo.

### Mapa do conhecimento

O Brain também possui uma proposta de visualização das relações entre conceitos,
perguntas e áreas.

A intenção é permitir que o usuário enxergue conhecimento como uma estrutura
conectada, e não apenas como uma lista de notas.

---

## Financeiro

A área financeira foi pensada para acompanhar metas e evolução financeira.

Entre as ideias previstas:

- meta financeira;
- valor atual;
- progresso visual;
- valor restante;
- histórico;
- ritmo de economia;
- estimativa de tempo para atingir uma meta.

Exemplo:

```text
Meta:
US$ 10.000

Atual:
US$ 2.800

Progresso:
28%

Restante:
US$ 7.200
```

---

## Treino

A área de treino tem como objetivo acompanhar consistência e evolução física.

Entre os recursos planejados:

- registro de treino;
- mapa semanal;
- histórico mensal;
- frequência;
- rotina;
- acompanhamento de progresso.

---

## Rotina

A área de rotina foi pensada para organização pessoal e planejamento.

Entre as ideias exploradas:

- lousas;
- quadros;
- notas;
- mapas mentais;
- planejamento;
- lembretes;
- integração com serviços externos, como Telegram.

---

# Site público

O projeto possui um site público desenvolvido com **Astro**.

O site apresenta:

- produto;
- colaboradores;
- download;
- planos;
- suporte;
- roadmap;
- licença;
- ecossistema EVRYLUX;
- acesso à área interna de colaboradores.

Rotas principais:

```text
/
├── /contributors
├── /download
├── /explore
├── /plans
├── /support
├── /roadmap
├── /license
└── /login
```

---

# EVRYLUX Colab

O projeto também possui uma área interna chamada **EVRYLUX Colab**.

Ela foi criada para organizar o trabalho dos colaboradores do projeto.

Rotas atuais:

```text
/colab
├── /profile
├── /admins
├── /demo
├── /support
└── /studio
    ├── /roadmap
    └── /notes
```

---

## Dashboard

O dashboard interno reúne:

- perfil do colaborador;
- GitHub;
- disponibilidade;
- habilidades;
- acesso rápido ao Studio;
- acesso ao roadmap interno;
- suporte;
- fila de interessados no demo;
- administração;
- colaboradores.

Alguns recursos são exibidos apenas para administradores.

---

## Perfis de colaboradores

Cada colaborador pode possuir um perfil com informações como:

```text
display_name
github_login
bio
avatar_url
area
skills
availability
```

A página pública de colaboradores busca valorizar participação e contribuições
sem criar uma hierarquia artificial entre pessoas.

---

# Studio

O **Studio** é a central de trabalho interno do EVRYLUX.

A intenção é concentrar ferramentas usadas para organizar o desenvolvimento do
projeto.

Atualmente o Studio inclui principalmente o roadmap interno.

---

## Roadmap interno

O roadmap interno permite organizar trabalho em diferentes estágios.

Entre os dados suportados pelo modelo estão:

```text
stage
status
priority
assignee
created_by
due_date
notes
progress
```

Os itens podem ser organizados em estágios como:

```text
Agora
Próximo
Depois
Concluído
```

ou estruturas equivalentes utilizadas na interface.

---

# Roadmap público

O EVRYLUX também possui um roadmap público.

Ele é visível para qualquer pessoa, mas os controles de administração são
exclusivos de usuários autenticados com papel de administrador.

Colunas atuais:

```text
Disponível / em uso
Em desenvolvimento
Planejado
```

A edição do roadmap público é protegida tanto visualmente quanto através das
políticas do banco de dados.

---

# Sistema de administradores

O projeto possui uma tabela de papéis administrativos:

```text
public.colab_user_roles
```

Um usuário pode possuir, por exemplo:

```text
role = admin
```

A verificação administrativa é realizada através de uma função como:

```sql
public.is_colab_admin()
```

Os recursos administrativos incluem, entre outros:

- roadmap público;
- fila de demo;
- suporte;
- gerenciamento de administradores.

---

# Demo / Early Explorers

O site possui uma página de download com uma fila para usuários interessados em
testar o EVRYLUX.

O fluxo permite registrar:

- nome;
- e-mail;
- sistema operacional;
- área de interesse;
- disponibilidade para enviar feedback;
- interesse em testar versões iniciais.

Plataformas apresentadas:

```text
Linux
Windows
macOS
```

Os primeiros usuários podem receber prioridade e possíveis vantagens futuras por
contribuírem com testes e relatos de bugs.

O projeto evita prometer antecipadamente benefícios específicos ou permanentes
que ainda não foram definidos.

---

# Suporte em tempo real

O EVRYLUX possui uma estrutura de suporte entre usuários e administradores.

O suporte público permite iniciar uma conversa sem exigir uma conta.

Características trabalhadas:

- mensagens de suporte;
- resposta de administradores;
- atualização em tempo real;
- notificações administrativas;
- histórico;
- possibilidade de fornecer e-mail;
- solicitação de e-mail caso uma resposta demore.

A implementação utiliza Supabase e Realtime.

---

# Histórico do projeto

Está prevista uma área interna para registrar marcos e decisões importantes do
projeto.

A proposta é separar:

```text
Roadmap
= o que pretendemos fazer

Histórico
= o que realmente aconteceu
```

Exemplos de registros:

```text
Marco
Decisão
Mudança
Release
Infraestrutura
Design
Bug importante
```

Isso permite manter memória de produto além do histórico técnico de commits do
Git.

---

# Arquitetura

O EVRYLUX utiliza atualmente uma combinação de tecnologias para frontend, dados,
autenticação e desenvolvimento do aplicativo.

## Website

- Astro
- TypeScript
- HTML
- CSS
- JavaScript

## Aplicativo

- Flutter
- Dart

## Backend / dados

- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Realtime
- Row Level Security

## Desenvolvimento

- Git
- GitHub
- Linux
- VS Code
- Docker
- Supabase CLI

---

# Supabase

O EVRYLUX utiliza Supabase para diferentes partes da plataforma.

Entre as tabelas e estruturas utilizadas ou exploradas no projeto estão:

```text
member_profiles
colab_user_roles
colab_roadmap_items
demo_waitlist
support_tickets
support_messages
brain_concepts
brain_notes
brain_reviews
brain_objects
brain_devices
brain_device_key_envelopes
app_updates
board_attachments
```

A estrutura pode evoluir ao longo do desenvolvimento.

---

# Segurança e privacidade

O EVRYLUX está sendo projetado com foco em privacidade.

Entre as diretrizes de arquitetura exploradas:

- offline-first;
- criptografia ponta a ponta;
- Vault local;
- proteção de chaves;
- sincronização segura;
- Row Level Security;
- menor exposição possível de dados;
- separação entre permissões públicas, autenticadas e administrativas.

> Nem todos os componentes de segurança descritos estão necessariamente
> finalizados. O projeto está em desenvolvimento ativo.

---

# Variáveis de ambiente

O website utiliza variáveis públicas para integração com Supabase.

Crie um arquivo:

```text
website/.env
```

com:

```env
PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Nunca coloque chaves secretas do Supabase no frontend.

Não utilize no navegador:

```text
service_role
SUPABASE_SECRET_KEY
```

---

# Executando o website

Entre na pasta:

```bash
cd website
```

Instale as dependências:

```bash
npm install
```

Execute em desenvolvimento:

```bash
npm run dev
```

O servidor local normalmente ficará disponível em:

```text
http://localhost:4321
```

Para gerar a versão de produção:

```bash
npm run build
```

O Astro gera os arquivos estáticos em:

```text
website/dist/
```

---

# Build atual

O website é configurado como saída estática.

Exemplo de build:

```text
output: static
mode: static
```

Rotas como login, Colab, suporte e roadmap são geradas estaticamente e utilizam
lógica no navegador para integração com Supabase.

---

# Deploy

O site está preparado para deploy em **Cloudflare Pages**.

Configuração:

```text
Framework preset:
Astro

Build command:
npm run build

Build output directory:
dist

Root directory:
website
```

A branch utilizada durante o desenvolvimento atual é:

```text
dev-stable
```

Variáveis necessárias no ambiente do Cloudflare:

```text
PUBLIC_SUPABASE_URL
PUBLIC_SUPABASE_PUBLISHABLE_KEY
```

O fluxo de deploy pode funcionar automaticamente:

```text
Git push
↓
GitHub
↓
Cloudflare Pages
↓
Build Astro
↓
Deploy
```

---

# Estrutura resumida do repositório

A estrutura do projeto pode variar durante o desenvolvimento, mas
conceitualmente inclui:

```text
ghost-core/
├── LICENSE
├── README.md
├── website/
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── layouts/
│   │   ├── lib/
│   │   ├── pages/
│   │   └── styles/
│   ├── package.json
│   └── astro.config.*
│
├── app/
│   ├── lib/
│   ├── assets/
│   └── ...
│
├── supabase/
│   ├── migrations/
│   ├── backup/
│   └── ...
│
└── ...
```

---

# Aplicativo Flutter

O aplicativo EVRYLUX está sendo desenvolvido em Flutter com foco em desktop e
evolução futura para outras plataformas.

A estrutura do Brain já passou por diferentes iterações de interface, incluindo:

- dashboard;
- criação de conceitos;
- criação de perguntas;
- revisão;
- busca;
- mapa visual;
- armazenamento local;
- sincronização;
- modais de criação;
- progresso de salvamento;
- minimização de processos longos.

A experiência está sendo refinada continuamente.

---

# Offline-first

Offline-first é uma diretriz importante do EVRYLUX.

A intenção é permitir que o usuário continue trabalhando mesmo sem conexão
constante com a internet.

O objetivo arquitetural é:

```text
dados locais
↓
uso offline
↓
sincronização quando disponível
↓
convergência entre dispositivos
```

---

# E2EE e Vault

O projeto também explora criptografia ponta a ponta e uma arquitetura de Vault
para dados sensíveis.

Entre os componentes já considerados na modelagem estão dispositivos e envelopes
de chaves.

Exemplos:

```text
brain_devices
brain_device_key_envelopes
```

Essas áreas ainda podem sofrer mudanças enquanto a arquitetura amadurece.

---

# Planos

O projeto possui uma proposta inicial de planos.

## Free

```text
US$ 0
1 GB de armazenamento sincronizado
```

## Essencial

```text
US$ 9 / mês
10 GB de armazenamento sincronizado
```

## Pro

```text
US$ 29 / mês
50 GB de armazenamento sincronizado
```

A proposta atual é que os planos compartilhem os principais módulos do
ecossistema, diferenciando inicialmente principalmente a capacidade de
armazenamento sincronizado.

> Os preços, limites e benefícios podem mudar antes de um lançamento comercial
> definitivo.

---

# Open source

O EVRYLUX é um projeto open source.

A intenção é permitir:

- estudo;
- contribuição;
- modificação;
- redistribuição;
- uso comercial nos termos da licença;
- colaboração pública;
- evolução coletiva do projeto.

---

# Licença

O EVRYLUX é distribuído sob a:

**GNU Affero General Public License v3.0 — AGPL-3.0**

Consulte:

```text
LICENSE
```

para o texto completo.

Resumo:

- uso comercial permitido;
- modificação permitida;
- redistribuição permitida;
- acesso ao código-fonte conforme os termos da licença;
- versões modificadas disponibilizadas através de rede estão sujeitas às
  obrigações da AGPL.

Este README não substitui o texto legal da licença.

---

# Marca EVRYLUX

A licença do código-fonte e os direitos relacionados à marca são assuntos
distintos.

A AGPL-3.0 cobre o software conforme seus termos.

O nome, logotipo, identidade visual e demais elementos de marca EVRYLUX não são
automaticamente licenciados da mesma forma que o código.

---

# Contribuições

Contribuições são bem-vindas.

Um fluxo comum:

```bash
git clone https://github.com/joao01020/ghost-core.git
cd ghost-core
git checkout -b minha-contribuicao
```

Faça suas alterações e depois:

```bash
git add .
git commit -m "Descrição da alteração"
git push origin minha-contribuicao
```

Em seguida, abra um Pull Request no GitHub.

Ao contribuir para o projeto, considere que o código integrado ao EVRYLUX será
distribuído sob a licença adotada pelo projeto.

---

# Filosofia de colaboração

O projeto busca valorizar contribuição real em vez de criar títulos artificiais.

A página de colaboradores pode destacar participação com base em atividade,
contribuições e histórico no projeto.

A intenção é evitar uma estrutura de apresentação baseada em categorias como:

```text
fundador
core
membro secundário
```

e priorizar uma visão de colaboração baseada no que cada pessoa efetivamente
constrói.

---

# Repositório

GitHub:

```text
https://github.com/joao01020/ghost-core
```

---

# Desenvolvimento

O EVRYLUX está em desenvolvimento ativo.

Isso significa que:

- estruturas podem mudar;
- APIs podem mudar;
- interfaces podem mudar;
- migrações podem ser necessárias;
- recursos podem ser adicionados, removidos ou reformulados;
- documentação será atualizada conforme o projeto amadurecer.

Não considere interfaces internas atuais como APIs estáveis.

---

# Objetivo de longo prazo

O objetivo do EVRYLUX é criar uma plataforma onde o usuário consiga acompanhar
sua evolução de forma contínua.

A ideia é que o sistema deixe de ser apenas um conjunto de ferramentas separadas
e se torne uma estrutura capaz de conectar:

```text
Conhecimento
+
Perguntas
+
Revisões
+
Finanças
+
Treino
+
Rotina
+
Histórico
+
Contexto
```

em uma experiência única.

---

## EVRYLUX

**Conhecimento que continua evoluindo.**
