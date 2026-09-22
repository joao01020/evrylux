# EVRYLUX — Documentação do projeto

> **Status:** em desenvolvimento ativo.

EVRYLUX é um projeto open source voltado à organização de conhecimento, evolução pessoal e acompanhamento de diferentes áreas da vida em uma única experiência.

## Propósito

O projeto nasceu da ideia de transformar informações soltas em algo que continue evoluindo com o usuário.

Em vez de ser apenas um bloco de notas ou um conjunto de ferramentas independentes, o objetivo é criar uma estrutura onde seja possível registrar, organizar, conectar, revisar e acompanhar conhecimento e progresso ao longo do tempo.

A proposta é ajudar o usuário a enxergar:

- o que aprendeu;
- o que ainda não entendeu;
- o que precisa revisar;
- como diferentes ideias se conectam;
- como seu progresso evolui;
- como diferentes áreas da vida podem fazer parte do mesmo ecossistema.

---

# Aplicativo

## Cérebro

O Cérebro é a área de conhecimento do EVRYLUX.

Ele foi pensado para transformar anotações em conhecimento estruturado.

Principais elementos:

- conceitos;
- perguntas;
- revisões;
- busca;
- histórico;
- áreas de conhecimento;
- conexões entre ideias;
- mapa visual;
- organização progressiva;
- uso offline;
- sincronização;
- proteção dos dados.

### Conceitos

Representam algo aprendido.

```text
Título
Estado em Flutter

O que você aprendeu?
Estado representa informações que podem mudar
durante a execução da interface.

Detalhes opcionais
- Exemplo
- Ponto de atenção
- Fonte
```

### Perguntas

Representam aquilo que ainda precisa ser entendido, investigado ou retomado.

### Revisões

Permitem retomar conteúdos importantes ao longo do tempo.

### Mapa visual

A intenção é mostrar relações entre conceitos, perguntas e áreas, em vez de exibir apenas uma lista de notas.

---

## Financeiro

Área voltada ao acompanhamento de metas e evolução financeira:

- meta;
- valor atual;
- progresso;
- valor restante;
- histórico;
- ritmo de evolução.

---

## Treino

Área voltada à consistência e evolução física:

- registro de treino;
- visão semanal;
- histórico;
- frequência;
- rotina;
- progresso.

---

## Rotina

Explora:

- planejamento;
- quadros;
- notas;
- mapas mentais;
- lembretes;
- organização pessoal.

---

# Funciona mesmo sem internet

Offline-first é uma diretriz importante do EVRYLUX.

A intenção é permitir que o usuário continue trabalhando com seus dados locais mesmo sem conexão constante.

```text
dados locais
↓
uso offline
↓
conexão disponível
↓
sincronização
```

---

# Sincronização

O projeto trabalha com a ideia de manter dados locais e sincronizar quando houver conexão, buscando convergência entre dispositivos sem transformar a internet em requisito para tarefas básicas.

---

# Privacidade

O EVRYLUX está sendo pensado para reduzir exposição desnecessária dos dados do usuário.

A arquitetura explora:

- criptografia ponta a ponta;
- Vault local;
- proteção de chaves;
- sincronização segura;
- menor exposição possível de dados.

Nem todos os componentes estão finalizados.

---

# Arquitetura

## Aplicativo

- Flutter
- Dart

## Dados

- Supabase
- PostgreSQL
- Auth
- Realtime

## Direção arquitetural

- offline-first;
- dados locais;
- sincronização;
- E2EE;
- Vault.

---

# Site do projeto

O EVRYLUX possui um site público feito em Astro.

O papel do site é apresentar o projeto, facilitar o acesso às informações e dar suporte ao processo de criação, distribuição e evolução do aplicativo.

O site não é o produto principal. O foco do EVRYLUX continua sendo o aplicativo.

---

# Open source

EVRYLUX é open source.

A intenção é permitir:

- estudo;
- contribuição;
- modificação;
- redistribuição;
- colaboração pública;
- evolução coletiva.

O software é distribuído sob a:

**GNU Affero General Public License v3.0 — AGPL-3.0**

---

# Estado atual

EVRYLUX está em desenvolvimento ativo.

O aplicativo já passou por diferentes iterações de interface e arquitetura, especialmente em:

- dashboard;
- criação de conceitos;
- criação de perguntas;
- revisão;
- busca;
- mapa visual;
- armazenamento local;
- sincronização;
- modais de criação;
- processos de salvamento.

Estruturas e interfaces ainda podem mudar conforme o produto amadurece.

---

# Objetivo de longo prazo

O objetivo é criar uma plataforma onde o usuário consiga acompanhar evolução contínua conectando:

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
