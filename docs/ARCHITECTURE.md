# Arquitetura do Projeto

## 1. Objetivo

Este documento descreve a arquitetura técnica do projeto, seus principais
componentes, responsabilidades, fronteiras, fluxo de dados e decisões
estruturais.

O objetivo é facilitar:

- manutenção;
- onboarding;
- revisão de código;
- evolução da arquitetura;
- análise de impacto;
- segurança;
- testes;
- releases;
- tomada de decisões técnicas.

Este documento descreve princípios arquiteturais.

Decisões específicas devem ser registradas em ADRs quando necessário.

---

## 2. Visão geral

O projeto utiliza uma arquitetura em camadas, separando:

- interface;
- gerenciamento de estado;
- lógica de aplicação;
- acesso a dados;
- persistência local;
- sincronização;
- criptografia;
- backend.

Visão simplificada:

```text
Usuário
   │
   ▼
Flutter UI
   │
   ▼
Controllers / State
   │
   ▼
Application / Domain Logic
   │
   ▼
Repositories
   │
   ├──────── Local Storage
   │
   ├──────── Encryption
   │
   └──────── Remote Data Source
                    │
                    ▼
                 Supabase
                    │
                    ▼
                PostgreSQL
```

A interface não deve depender diretamente da implementação do backend.

---

## 3. Objetivos arquiteturais

A arquitetura deve favorecer:

- funcionamento offline;
- recuperação após falha de rede;
- isolamento de responsabilidades;
- testabilidade;
- segurança;
- sincronização resiliente;
- evolução incremental;
- suporte a múltiplas plataformas.

Evite aumentar complexidade sem necessidade concreta.

---

## 4. Estrutura principal

```text
evrylux/
├── app/
├── website/
├── supabase/
├── scripts/
├── docs/
└── .github/
```

---

## 5. `app/`

Aplicação principal Flutter.

Responsável por:

- UI;
- navegação;
- estado;
- regras de aplicação;
- persistência local;
- sincronização;
- criptografia no cliente;
- integração com backend.

Estrutura interna pode evoluir conforme o projeto.

A separação conceitual deve permanecer clara mesmo que os diretórios físicos
sejam diferentes.

---

## 6. `website/`

Aplicação ou páginas web relacionadas ao projeto.

Mudanças no website devem permanecer separadas do aplicativo Flutter quando não
houver dependência real.

Isso facilita:

- revisão;
- deploy;
- ownership;
- testes;
- rollback.

---

## 7. `supabase/`

Infraestrutura relacionada ao backend.

Exemplo:

```text
supabase/
├── migrations/
├── functions/
├── seed.sql
└── config.toml
```

Responsável por:

- schema PostgreSQL;
- migrations;
- RLS;
- funções backend;
- configuração local;
- componentes relacionados ao Supabase.

---

## 8. `scripts/`

Scripts auxiliares para:

- desenvolvimento;
- build;
- automação;
- manutenção;
- diagnóstico.

Scripts não devem possuir credenciais fixas.

---

## 9. `docs/`

Documentação técnica e operacional.

Exemplos:

```text
docs/
├── ARCHITECTURE.md
├── DEVELOPMENT.md
├── TESTING.md
├── RELEASE.md
├── SECURITY_ARCHITECTURE.md
└── adr/
```

---

## 10. Arquitetura da aplicação Flutter

Fluxo recomendado:

```text
Widget
   ↓
Controller / State
   ↓
Application Logic
   ↓
Repository
   ↓
Data Source
```

Cada camada deve possuir responsabilidade clara.

---

## 11. UI

A camada de UI deve:

- exibir estado;
- receber eventos;
- apresentar feedback;
- delegar ações;
- evitar regras complexas;
- evitar acesso direto ao banco;
- evitar acesso direto ao backend quando puder utilizar abstrações existentes.

Widgets não devem se tornar responsáveis por persistência ou sync.

---

## 12. Controllers / State

Controllers coordenam ações de aplicação.

Exemplos:

- carregar;
- criar;
- atualizar;
- excluir;
- buscar;
- sincronizar;
- controlar estados de loading;
- representar erros.

Controllers devem evitar conhecimento desnecessário sobre detalhes de
armazenamento.

---

## 13. Application / Domain Logic

Regras independentes de UI devem permanecer fora dos widgets.

Exemplos:

- validações;
- regras de conflito;
- transformação de dados;
- priorização de sync;
- decisões de negócio.

Isso facilita testes unitários.

---

## 14. Repositories

Repositories fornecem uma interface estável entre a aplicação e as fontes de
dados.

Exemplo:

```dart
abstract class BrainRepository {
  Future<List<BrainConcept>> getConcepts();

  Future<void> saveConcept(BrainConcept concept);

  Future<void> deleteConcept(String id);
}
```

Uma implementação pode combinar:

```text
Repository
├── local database
├── cache
├── encryption
└── remote backend
```

A camada acima não deve precisar conhecer esses detalhes.

---

## 15. Data Sources

Data sources representam mecanismos concretos de armazenamento ou comunicação.

Exemplos:

- SQLite;
- arquivos;
- secure storage;
- Supabase;
- APIs;
- storage remoto.

Regras de aplicação não devem ficar espalhadas pelos data sources.

---

## 16. Offline-first

O aplicativo adota comportamento offline-first.

Princípio:

```text
Ação do usuário
      ↓
Validação
      ↓
Persistência local
      ↓
UI atualizada
      ↓
Mudança marcada para sync
      ↓
Sync remoto quando possível
```

O backend remoto não deve ser requisito para interações básicas que possam
funcionar localmente.

Consulte:

```text
docs/adr/0001-offline-first.md
```

---

## 17. Fonte de verdade

Em uma arquitetura offline-first, o conceito de fonte de verdade precisa ser
explícito.

Para experiência imediata da UI, os dados locais normalmente representam o
estado disponível para leitura.

O backend representa o estado sincronizado entre dispositivos.

Isso implica que:

```text
Local
≠ simples cache descartável
```

O armazenamento local pode conter mudanças ainda não enviadas ao servidor.

Portanto, limpar dados locais sem considerar sync pode causar perda de
informação.

---

## 18. Persistência local

A camada local deve permitir:

- leitura rápida;
- criação offline;
- edição offline;
- exclusão offline;
- persistência entre reinicializações;
- metadata necessária ao sync.

Quando necessário, registros devem possuir metadata como:

```text
id
created_at
updated_at
deleted_at
sync_state
version
```

Os nomes reais podem variar conforme o modelo.

---

## 19. Sincronização

Fluxo conceitual:

```text
Local mutation
      │
      ▼
Local database
      │
      ├── pending
      │
      ▼
Sync engine
      │
      ▼
Remote backend
```

O sync deve considerar:

- criação;
- atualização;
- exclusão;
- retry;
- conectividade;
- duplicação;
- tombstones;
- conflito;
- idempotência.

---

## 20. Idempotência

Sempre que possível:

```text
executar a mesma operação novamente
```

não deve gerar:

```text
duplicação
corrupção
efeitos inesperados
```

Isso é especialmente importante porque redes falham e operações podem ser
reenviadas.

---

## 21. Conflitos

Conflitos podem ocorrer quando:

```text
Dispositivo A
   ↓
edita registro

Dispositivo B
   ↓
edita o mesmo registro
```

antes de ambos sincronizarem.

A política de conflito deve ser explícita.

Não descarte silenciosamente mudanças sem uma regra definida.

---

## 22. Tombstones

Exclusões sincronizáveis podem utilizar tombstones.

Exemplo:

```text
registro ativo
     ↓
usuário exclui
     ↓
deleted_at definido
     ↓
sync envia exclusão
     ↓
outros dispositivos recebem
```

O tombstone não deve manter conteúdo sensível desnecessariamente.

---

## 23. Supabase

Supabase é utilizado como backend.

Componentes possíveis:

- PostgreSQL;
- Auth;
- RLS;
- Storage;
- Functions.

Consulte:

```text
docs/adr/0002-supabase.md
```

---

## 24. Fronteira de segurança

O aplicativo cliente não deve ser considerado confiável para decisões críticas.

Fluxo:

```text
Flutter Client
      ↓
requisição
      ↓
Auth
      ↓
RLS / autorização
      ↓
Database
```

Uma verificação feita somente na interface não protege o backend.

Consulte:

```text
docs/SECURITY_ARCHITECTURE.md
```

---

## 25. Row Level Security

Dados privados por usuário devem utilizar RLS quando aplicável.

A política deve ser avaliada para:

```text
SELECT
INSERT
UPDATE
DELETE
```

Não dependa apenas de filtros no Flutter.

---

## 26. Criptografia

Dados classificados como E2EE devem ser criptografados no cliente antes do envio
remoto.

Fluxo:

```text
plaintext
   ↓
encrypt
   ↓
ciphertext
   ↓
sync
   ↓
backend
```

Consulte:

```text
docs/adr/0003-encryption.md
docs/SECURITY_ARCHITECTURE.md
```

---

## 27. Chaves

Chaves não devem:

- ficar hardcoded;
- aparecer em logs;
- ser commitadas;
- ser enviadas sem proteção adequada.

A arquitetura deve permitir evolução futura do formato criptográfico.

---

## 28. Banco de dados

Mudanças de schema devem ocorrer por migrations.

Regras:

1. não editar migration já aplicada em produção;
2. criar nova migration;
3. revisar impacto;
4. testar;
5. revisar RLS;
6. considerar compatibilidade;
7. considerar rollback.

Exemplo:

```text
supabase/migrations/
202609230001_add_task_notifications.sql
```

---

## 29. IDs

Entidades sincronizadas devem possuir identificadores estáveis.

Evite depender exclusivamente de IDs temporários locais que precisem ser
substituídos após o sync.

IDs estáveis facilitam:

- offline;
- deduplicação;
- referências;
- conflitos;
- sincronização.

---

## 30. Timestamps

Timestamps podem auxiliar sincronização, mas não devem ser utilizados de forma
ingênua.

Considere:

- diferença de relógio entre dispositivos;
- timestamps gerados no servidor;
- resolução;
- ordenação;
- conflito.

Quando necessário, utilize versão ou metadata adicional.

---

## 31. Tratamento de erros

Erros podem ser classificados como:

- validação;
- rede;
- autenticação;
- autorização;
- persistência;
- sync;
- criptografia;
- erro inesperado.

A UI deve receber informação suficiente para oferecer feedback sem expor
detalhes sensíveis.

---

## 32. Logging

Logs devem ajudar no diagnóstico sem expor dados.

Nunca registrar:

- senha;
- access token;
- refresh token;
- chave criptográfica;
- `.env`;
- Authorization header;
- plaintext sensível;
- dados pessoais desnecessários.

---

## 33. Dependências

Antes de adicionar uma dependência, avalie:

- necessidade;
- manutenção;
- licença;
- segurança;
- compatibilidade;
- impacto no tamanho;
- suporte a plataformas;
- custo de manutenção futura.

Dependências abandonadas devem ser evitadas.

---

## 34. Testabilidade

A arquitetura deve permitir testar regras importantes sem abrir a interface.

Priorize testes em:

- repositories;
- controllers;
- sync;
- auth;
- autorização;
- criptografia;
- regras de negócio;
- migrations.

Consulte:

```text
docs/TESTING.md
```

---

## 35. Plataformas

Flutter permite múltiplas plataformas, mas nem todo plugin possui comportamento
idêntico em:

```text
Linux
macOS
Windows
Android
iOS
Web
```

Funcionalidades dependentes de plataforma devem possuir:

- abstração adequada;
- fallback quando necessário;
- tratamento de indisponibilidade;
- testes nas plataformas suportadas.

---

## 36. Decisões arquiteturais

Decisões relevantes devem ser registradas em:

```text
docs/adr/
```

ADR significa Architecture Decision Record.

Estrutura recomendada:

```text
Contexto
Decisão
Consequências
Alternativas
```

ADRs atuais:

```text
0001-offline-first.md
0002-supabase.md
0003-encryption.md
```

---

## 37. Quando criar um novo ADR

Considere um ADR quando decidir:

- novo banco;
- nova estratégia de sync;
- novo mecanismo de autenticação;
- nova arquitetura de criptografia;
- grande mudança de estado;
- novo serviço externo central;
- mudança significativa de persistência.

Não é necessário criar ADR para cada pequena implementação.

---

## 38. Regra de evolução

Antes de introduzir nova camada, framework, serviço ou dependência, responda:

1. qual problema concreto ela resolve?
2. a arquitetura atual realmente não resolve?
3. aumenta ou reduz complexidade?
4. como será testada?
5. como será mantida?
6. qual impacto de segurança?
7. qual impacto em offline-first?
8. qual impacto em sync?
9. qual impacto nas plataformas suportadas?

Arquitetura deve responder às necessidades reais do produto.

Não adicione abstrações apenas porque parecem arquiteturalmente sofisticadas.

---

## 39. Documentos relacionados

Consulte também:

```text
docs/DEVELOPMENT.md
docs/TESTING.md
docs/RELEASE.md
docs/SECURITY_ARCHITECTURE.md
docs/adr/0001-offline-first.md
docs/adr/0002-supabase.md
docs/adr/0003-encryption.md
```

Esses documentos devem permanecer consistentes entre si.
