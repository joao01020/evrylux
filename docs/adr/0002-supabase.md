# ADR 0002 — Supabase como backend

- Status: Aceito
- Data: 2026-09-23

## Contexto

O projeto necessita de uma plataforma de backend capaz de oferecer:

- banco de dados relacional;
- PostgreSQL;
- autenticação;
- autorização;
- Row Level Security;
- migrations;
- APIs;
- storage;
- funções backend;
- integração com Flutter;
- desenvolvimento local;
- ambientes separados de desenvolvimento e produção.

Construir toda essa infraestrutura internamente aumentaria o custo inicial de
desenvolvimento, manutenção, segurança e operação.

O projeto também precisa preservar uma arquitetura compatível com:

- offline-first;
- sincronização;
- múltiplos usuários;
- múltiplos dispositivos;
- E2EE quando aplicável;
- evolução futura da infraestrutura.

---

## Decisão

Utilizar Supabase como plataforma principal de backend.

Componentes principais:

```text
Supabase
├── PostgreSQL
├── Auth
├── RLS
├── Storage
├── Functions
└── APIs
```

O Supabase será responsável pela infraestrutura remota principal, enquanto a
aplicação Flutter continuará responsável pela experiência local, regras de
aplicação e comportamento offline-first.

---

## Papel do Supabase

O Supabase deverá fornecer, conforme necessário:

### PostgreSQL

Responsável por:

- persistência remota;
- relacionamentos;
- constraints;
- índices;
- consultas;
- integridade estrutural;
- suporte às políticas RLS.

### Auth

Responsável por:

- autenticação;
- identificação do usuário;
- sessões;
- tokens;
- associação entre identidade e dados.

### Row Level Security

Responsável por aplicar autorização próxima aos dados.

RLS deve impedir que um usuário acesse dados que não pertencem a ele, mesmo que
o aplicativo cliente tente realizar uma requisição indevida.

### Storage

Utilizado quando o projeto precisar armazenar arquivos, anexos ou objetos
externos ao banco relacional.

Buckets e objetos privados devem possuir políticas adequadas.

### Functions

Utilizadas quando uma operação não deve ser executada diretamente pelo cliente.

Exemplos:

- operações privilegiadas;
- integração com serviços externos;
- processamento confiável no backend;
- webhooks;
- billing;
- validações que exigem segredo;
- tarefas administrativas controladas.

---

## Motivos

A escolha foi baseada principalmente em:

- PostgreSQL padrão;
- suporte nativo a RLS;
- integração adequada com Flutter;
- autenticação integrada;
- migrations versionáveis;
- APIs geradas sobre o banco;
- desenvolvimento local;
- Supabase CLI;
- redução de infraestrutura inicial;
- possibilidade de utilizar SQL e recursos PostgreSQL convencionais;
- proximidade entre autorização e dados.

---

## Fronteira de confiança

O aplicativo Flutter não deve ser considerado uma fronteira confiável de
segurança.

Fluxo conceitual:

```text
Flutter Client
      ↓
Supabase Auth
      ↓
RLS / Policies / Backend Validation
      ↓
PostgreSQL
```

O cliente pode ser modificado, inspecionado ou executado fora das condições
esperadas.

Portanto:

```text
"o botão está escondido"
```

não significa:

```text
"o usuário não possui acesso"
```

A autorização real deve acontecer no backend.

---

## Chave pública do cliente

A aplicação pode utilizar uma chave pública destinada ao cliente, como:

```text
SUPABASE_PUBLISHABLE_KEY
```

Essa chave permite que o cliente se conecte ao projeto Supabase conforme as
permissões disponibilizadas.

Ela não substitui:

- autenticação;
- autorização;
- RLS;
- policies;
- validações backend.

A arquitetura não deve depender de esconder essa chave para proteger dados.

---

## Service role

Service role keys possuem privilégios elevados.

Elas nunca devem estar presentes em:

- Flutter;
- JavaScript distribuído ao usuário;
- repositório Git;
- `.env.example`;
- documentação pública;
- logs;
- builds desktop;
- builds mobile;
- arquivos distribuídos ao cliente.

Fluxo proibido:

```text
Flutter
   ↓
service_role
   ↓
Supabase
```

Operações que exigem privilégios administrativos devem passar por infraestrutura
backend confiável.

Exemplo:

```text
Flutter
   ↓
Function / Backend confiável
   ↓
service role protegida
   ↓
Supabase
```

---

## Autenticação

Supabase Auth será utilizado para autenticar usuários quando aplicável.

A autenticação responde principalmente:

```text
Quem é o usuário?
```

Ela não deve ser confundida com autorização.

Um usuário autenticado ainda precisa possuir permissão para acessar determinado
recurso.

---

## Autorização

A autorização responde:

```text
Este usuário pode realizar esta operação neste recurso?
```

Ela deve ser aplicada no backend.

Dependendo da operação, utilizar:

- RLS;
- policies;
- constraints;
- Functions;
- validações adicionais.

---

## Row Level Security

Tabelas contendo dados privados por usuário devem utilizar RLS quando aplicável.

Operações devem ser avaliadas individualmente:

```text
SELECT
INSERT
UPDATE
DELETE
```

Exemplo conceitual:

```text
Usuário A
   ↓
registro pertencente ao usuário A
   ↓
permitido


Usuário B
   ↓
registro pertencente ao usuário A
   ↓
bloqueado
```

Filtros no Flutter não substituem RLS.

---

## Ownership

O ownership de registros deve ser validado no backend.

Evite confiar cegamente em campos enviados pelo cliente como:

```text
user_id
owner_id
created_by
```

quando esses campos definem autorização.

Sempre que possível, derive ownership de uma identidade autenticada ou valide a
relação através de policies confiáveis.

---

## Migrations

Mudanças de schema devem ser versionadas através de migrations.

Diretório esperado:

```text
supabase/migrations/
```

Regras:

- não alterar silenciosamente migration já aplicada em produção;
- criar nova migration para correções;
- revisar SQL;
- testar localmente;
- validar RLS;
- revisar constraints;
- revisar índices;
- avaliar impacto em dados existentes;
- considerar rollback ou migration corretiva.

---

## Desenvolvimento local

O Supabase CLI pode ser utilizado para executar infraestrutura local através de
Docker.

Fluxo:

```text
Migration
   ↓
Supabase local
   ↓
Testes
   ↓
DEV compartilhado
   ↓
Review
   ↓
Produção
```

Mudanças críticas devem ser testadas antes de chegar ao ambiente de produção.

---

## Ambientes

O projeto deve separar ambientes sempre que possível.

Estrutura esperada:

```text
development
staging
production
```

No mínimo, desenvolvimento e produção devem permanecer separados.

### Development

Utilizado para:

- desenvolvimento;
- testes;
- migrations;
- contas fictícias;
- experimentação controlada.

### Production

Utilizado para:

- usuários reais;
- dados reais;
- versão publicada do aplicativo.

Credenciais, dados e configurações de produção não devem ser utilizados durante
desenvolvimento normal.

---

## Banco DEV compartilhado

O ambiente DEV remoto pode ser compartilhado entre colaboradores autorizados.

Ele deve ser tratado como:

```text
ambiente de desenvolvimento
```

e não como armazenamento permanente de produção.

Utilize preferencialmente:

- dados fictícios;
- contas de teste;
- arquivos de teste.

Evite:

- dados pessoais reais;
- secrets de produção;
- dumps de produção;
- contas reais sem necessidade.

---

## Offline-first

A escolha do Supabase não altera a decisão arquitetural de offline-first.

O fluxo da aplicação permanece:

```text
Ação do usuário
      ↓
Persistência local
      ↓
UI
      ↓
Sync
      ↓
Supabase
```

O Supabase não deve ser chamado diretamente a cada interação quando isso
tornaria o funcionamento offline impossível.

Consulte:

```text
docs/adr/0001-offline-first.md
```

---

## Sincronização

Repositories ou serviços de sync devem intermediar o acesso remoto sempre que
possível.

Evite:

```text
Widget
   ↓
Supabase diretamente
```

Prefira:

```text
Widget
   ↓
Controller
   ↓
Repository
   ↓
Sync / Remote Data Source
   ↓
Supabase
```

Isso reduz acoplamento e melhora:

- testabilidade;
- offline-first;
- manutenção;
- tratamento de erro;
- substituição futura de infraestrutura.

---

## Criptografia

Quando o projeto utilizar E2EE, dados sensíveis devem ser criptografados no
cliente antes do envio remoto.

Fluxo conceitual:

```text
Plaintext
   ↓
Encryption
   ↓
Ciphertext
   ↓
Supabase
```

O backend não deve receber chaves privadas do usuário quando o modelo de
segurança exigir E2EE real.

Consulte:

```text
docs/adr/0003-encryption.md
docs/SECURITY_ARCHITECTURE.md
```

---

## Storage

O Supabase Storage pode ser utilizado para arquivos e anexos.

Antes de utilizar um bucket, definir:

- público ou privado;
- ownership;
- policies;
- limite de tamanho;
- tipos de arquivo;
- nomes de objetos;
- estratégia de exclusão;
- quota;
- relação com banco;
- criptografia quando necessária.

Buckets privados não devem depender apenas de URLs difíceis de adivinhar.

---

## Functions

Supabase Functions devem ser utilizadas quando a operação exigir uma fronteira
backend confiável.

Exemplos:

- billing;
- integração com provedores externos;
- webhooks;
- chamadas que dependam de secrets;
- operações administrativas;
- lógica que não pode confiar no cliente.

Secrets dessas funções devem permanecer no ambiente backend.

---

## APIs

As APIs disponibilizadas pelo Supabase devem ser tratadas como interfaces de
acesso ao backend.

O fato de uma API estar acessível não significa que todas as operações devem ser
permitidas.

Policies e autorização continuam obrigatórias.

---

## Tratamento de erros

Erros vindos do Supabase devem ser convertidos em estados compreensíveis para a
aplicação.

Evite expor diretamente ao usuário:

- SQL;
- stack traces;
- tokens;
- detalhes internos de policy;
- mensagens sensíveis do backend.

Logs de desenvolvimento podem possuir mais detalhes, desde que não incluam
secrets ou dados sensíveis desnecessários.

---

## Logging

Nunca registrar:

- access token;
- refresh token;
- senha;
- service role key;
- database password;
- Authorization header;
- conteúdo sensível em plaintext;
- secrets de Functions.

---

## Testes

A integração com Supabase deve possuir testes para áreas críticas.

Prioridades:

- autenticação;
- autorização;
- RLS;
- isolamento entre usuários;
- migrations;
- sync;
- Storage;
- Functions críticas;
- comportamento com sessão expirada;
- comportamento sem conexão.

Para RLS, utilizar pelo menos:

```text
Usuário A
Usuário B
Usuário anônimo
```

e validar que cada identidade possui apenas os acessos esperados.

---

## Dependência da plataforma

Utilizar Supabase cria dependência operacional da plataforma e de seus serviços.

Essa dependência é aceita devido aos benefícios atuais.

Para reduzir acoplamento desnecessário:

- UI não deve depender diretamente do SDK sempre que possível;
- repositories devem abstrair acesso a dados;
- regras de negócio devem permanecer fora do SDK;
- migrations devem permanecer versionadas;
- SQL deve ser documentado;
- dados devem utilizar formatos portáveis quando possível.

O objetivo não é tornar uma futura migração trivial, mas evitar dependência
desnecessária em todas as camadas.

---

## Consequências positivas

- desenvolvimento mais rápido;
- redução de infraestrutura própria;
- PostgreSQL padrão;
- autenticação integrada;
- RLS próximo dos dados;
- APIs prontas;
- migrations versionáveis;
- desenvolvimento local;
- Storage integrado;
- Functions disponíveis;
- menor esforço operacional inicial.

---

## Consequências negativas

- dependência da plataforma;
- necessidade de compreender RLS corretamente;
- risco de configuração incorreta de policies;
- necessidade de disciplina com migrations;
- custos podem crescer com escala;
- indisponibilidade do serviço pode afetar sync e funcionalidades online;
- algumas funcionalidades podem criar acoplamento específico ao Supabase;
- operações administrativas exigem cuidado adicional com secrets.

---

## Riscos principais

Os maiores riscos relacionados a essa decisão incluem:

### RLS incorreta

Pode permitir acesso indevido ou bloquear acesso legítimo.

Mitigação:

- testes;
- revisão;
- deny-by-default;
- isolamento entre usuários.

### Service role exposta

Pode fornecer privilégios elevados indevidos.

Mitigação:

- nunca enviar para cliente;
- manter apenas em backend confiável;
- rotacionar imediatamente se houver exposição.

### Migration incorreta

Pode causar indisponibilidade ou perda de dados.

Mitigação:

- DEV;
- Supabase local;
- revisão;
- backup quando necessário;
- migrations incrementais.

### Acoplamento

Pode dificultar mudanças futuras de infraestrutura.

Mitigação:

- repositories;
- data sources;
- separação de camadas;
- ADRs.

---

## Alternativas consideradas

### Backend próprio

Criar uma API e infraestrutura própria ofereceria maior controle sobre:

- runtime;
- autenticação;
- autorização;
- deploy;
- observabilidade;
- regras de backend.

Foi rejeitado como opção inicial devido a:

- maior custo operacional;
- maior superfície de segurança;
- necessidade de infraestrutura própria;
- maior tempo de desenvolvimento;
- maior esforço de manutenção.

Pode ser reconsiderado futuramente para componentes específicos.

### Firebase

Possui boa integração com aplicações cliente e serviços maduros.

Foi rejeitado porque o projeto deseja:

- PostgreSQL;
- modelo relacional;
- SQL;
- RLS próximo ao banco;
- migrations SQL;
- arquitetura mais alinhada ao modelo atual.

### API própria sobre PostgreSQL

Também seria possível manter PostgreSQL próprio e construir uma API dedicada.

Foi rejeitado inicialmente devido ao custo adicional de:

- autenticação;
- autorização;
- deploy;
- manutenção;
- scaling;
- observabilidade;
- APIs;
- storage.

---

## Quando reconsiderar esta decisão

Esta decisão pode ser revisada se surgirem problemas relevantes relacionados a:

- custo;
- escala;
- disponibilidade;
- requisitos regulatórios;
- limitações técnicas;
- segurança;
- necessidade de infraestrutura própria;
- dependência excessiva da plataforma.

Uma mudança dessa magnitude deve gerar um novo ADR.

---

## Regras

- Supabase é o backend remoto principal.
- PostgreSQL é a base principal de persistência remota.
- RLS deve proteger dados privados quando aplicável.
- Autenticação não substitui autorização.
- Publishable key não substitui RLS.
- Service role nunca deve estar no cliente.
- Mudanças de schema devem utilizar migrations.
- Desenvolvimento e produção devem permanecer separados.
- O aplicativo deve continuar respeitando offline-first.
- UI não deve depender diretamente do Supabase sem necessidade.
- Secrets administrativos devem permanecer no backend.
- Operações privilegiadas devem passar por uma fronteira confiável.

---

## Resultado

Supabase passa a ser a plataforma principal de backend do projeto.

A decisão fornece:

```text
PostgreSQL
+
Auth
+
RLS
+
Storage
+
Functions
+
APIs
```

sem exigir infraestrutura própria completa nesta fase do produto.

Ao mesmo tempo, a aplicação deve manter separação suficiente entre:

```text
UI
Application Logic
Repositories
Data Sources
Supabase
```

para preservar testabilidade, offline-first, segurança e capacidade de evolução
futura.

O Supabase é uma decisão de infraestrutura.

Ele não deve definir toda a arquitetura da aplicação.
