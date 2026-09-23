# ADR 0001 — Offline-first

- Status: Aceito
- Data: 2026-09-23

## Contexto

O aplicativo precisa permanecer utilizável mesmo quando a conexão com a internet
estiver indisponível, lenta ou instável.

Uma arquitetura dependente de requisições remotas para cada interação causaria:

- lentidão;
- perda de fluidez;
- falhas em ambientes offline;
- maior dependência do backend;
- risco de interrupção da experiência durante oscilações de rede.

O projeto também precisa permitir que mudanças realizadas localmente sejam
sincronizadas posteriormente com o backend.

---

## Decisão

Adotar uma arquitetura offline-first.

O armazenamento local será tratado como parte essencial do fluxo da aplicação e
não apenas como cache temporário.

Fluxo principal:

```text
Ação do usuário
      ↓
Validação
      ↓
Persistência local
      ↓
Atualização da UI
      ↓
Fila / estado de sync
      ↓
Sincronização remota
      ↓
Backend
```

Sempre que possível, uma operação básica deve concluir localmente antes de
depender da disponibilidade da rede.

O backend continua sendo responsável pelo estado remoto compartilhado entre
dispositivos, autenticação, autorização e persistência remota.

---

## Fonte de verdade

Para a experiência imediata do usuário, o estado local representa a fonte
disponível para leitura e interação.

O backend representa o estado remoto sincronizado.

Isso significa que o armazenamento local não pode ser tratado como descartável
enquanto existirem mudanças ainda não sincronizadas.

Exemplo:

```text
Local
├── dados sincronizados
└── mudanças pendentes

Backend
└── último estado remoto conhecido
```

A aplicação deve preservar mudanças locais até que o sync seja concluído com
segurança.

---

## Consequências positivas

- resposta rápida;
- funcionamento offline;
- maior resiliência;
- menor percepção de latência;
- possibilidade de sincronização posterior;
- menor dependência de disponibilidade contínua do backend;
- melhor experiência em conexões instáveis.

---

## Consequências negativas

A decisão aumenta a complexidade relacionada a:

- conflitos;
- tombstones;
- retry;
- deduplicação;
- integridade;
- migrations locais;
- sincronização entre dispositivos;
- versionamento de registros;
- tratamento de operações parcialmente concluídas.

Essa complexidade é aceita como consequência necessária para atender o
comportamento desejado do produto.

---

## Sincronização

Operações locais que precisam chegar ao backend devem possuir estado suficiente
para permitir sincronização posterior.

Exemplo conceitual:

```text
pending
   ↓
syncing
   ↓
synced
```

Quando necessário, também podem existir estados de erro ou retry.

A implementação exata pode variar conforme o tipo de dado.

---

## Idempotência

Sempre que possível, operações de sincronização devem ser idempotentes.

Repetir uma operação devido a timeout ou retry não deve causar:

- duplicação;
- corrupção;
- múltiplos registros equivalentes;
- efeitos inesperados.

O sistema deve assumir que uma operação pode ser enviada mais de uma vez.

---

## IDs

Entidades sincronizadas devem utilizar identificadores estáveis.

Evite depender de identificadores temporários que precisem ser substituídos
depois do primeiro sync.

IDs estáveis facilitam:

- criação offline;
- referências;
- deduplicação;
- conflitos;
- sincronização entre dispositivos.

---

## Exclusões

Exclusões que precisam ser sincronizadas não devem depender apenas da remoção
física imediata do registro.

Quando necessário, utilizar tombstones ou mecanismo equivalente.

Fluxo conceitual:

```text
Registro ativo
      ↓
Usuário exclui
      ↓
Exclusão registrada localmente
      ↓
Tombstone / estado de exclusão
      ↓
Sync
      ↓
Outros dispositivos recebem a exclusão
```

O objetivo é impedir que um registro excluído reapareça após sincronização.

---

## Conflitos

Conflitos podem ocorrer quando o mesmo dado é alterado em mais de um dispositivo
antes do sync.

Exemplo:

```text
Dispositivo A
      ↓
edita registro

Dispositivo B
      ↓
edita o mesmo registro
```

A política de resolução de conflitos deve ser explícita.

Nenhuma implementação deve descartar silenciosamente mudanças sem uma regra
definida.

A estratégia poderá variar conforme o tipo de dado.

---

## Falhas de rede

Falhas de conexão não devem destruir mudanças locais.

Quando uma operação remota falhar:

```text
Operação local
      ↓
falha de rede
      ↓
mudança permanece local
      ↓
retry posterior
```

O usuário deve continuar podendo utilizar funcionalidades compatíveis com o modo
offline.

---

## Regras

- não depender de internet para operações básicas quando tecnicamente possível;
- persistir alterações localmente antes do sync remoto;
- preservar mudanças ainda não sincronizadas;
- utilizar IDs estáveis;
- tratar exclusões de forma sincronizável;
- evitar duplicação durante retry;
- projetar operações idempotentes quando possível;
- não apagar estado local pendente sem confirmação de sync;
- documentar política de conflitos;
- considerar múltiplos dispositivos;
- considerar reinicialização do aplicativo durante operações pendentes;
- testar perda e recuperação de conexão.

---

## Implicações para novas funcionalidades

Toda nova funcionalidade que persista dados deve responder:

1. funciona sem internet?
2. o que acontece quando a rede cai durante a operação?
3. onde a mudança é persistida localmente?
4. como ela será sincronizada?
5. como retry será tratado?
6. como duplicações serão evitadas?
7. como exclusões serão sincronizadas?
8. como conflitos serão tratados?
9. o que acontece se o aplicativo fechar antes do sync?
10. como outro dispositivo recebe a alteração?

Se essas perguntas não forem relevantes para a funcionalidade, isso deve ficar
claro na implementação.

---

## Testes esperados

Funcionalidades offline-first críticas devem ser testadas em cenários como:

- criação offline;
- edição offline;
- exclusão offline;
- fechamento do aplicativo antes do sync;
- reinicialização ainda offline;
- recuperação de conexão;
- retry;
- operação duplicada;
- sync em múltiplos dispositivos;
- conflito;
- tombstone;
- backend temporariamente indisponível.

Consulte:

```text
docs/TESTING.md
docs/TESTING_ROADMAP.md
```

---

## Alternativas consideradas

### Online-first

Mais simples de implementar inicialmente.

Foi rejeitada porque tornaria operações básicas dependentes da disponibilidade e
latência do backend.

### Cache somente leitura

Permitiria leitura de dados previamente carregados sem internet.

Foi rejeitada porque não atende:

- criação offline;
- edição offline;
- exclusão offline;
- sincronização posterior.

### Persistência local apenas para performance

Manter uma cópia local apenas como otimização não atende ao requisito de
preservar mudanças realizadas offline.

Foi rejeitada porque o armazenamento local precisa participar ativamente do
fluxo de escrita e sincronização.

---

## Consequências arquiteturais

Esta decisão afeta diretamente:

- repositories;
- persistência local;
- sync engine;
- modelos de dados;
- tombstones;
- conflitos;
- migrations;
- testes;
- arquitetura de segurança;
- múltiplos dispositivos.

Mudanças futuras nessas áreas devem preservar os princípios definidos neste ADR
ou registrar formalmente uma nova decisão que o substitua.

---

## Resultado

Offline-first passa a ser uma restrição arquitetural do projeto.

Novas funcionalidades devem considerar comportamento sem conectividade desde o
desenho inicial, e não como adaptação posterior.

Se uma funcionalidade exigir conexão permanente, essa exceção deve ser
intencional e documentada.
