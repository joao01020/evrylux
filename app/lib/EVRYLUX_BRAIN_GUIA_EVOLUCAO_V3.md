# EVRYLUX --- Guia de Evolução do Cérebro

## 1. Objetivo deste documento

Este documento registra as decisões tomadas para a próxima evolução do
**Cérebro do EVRYLUX**.

A proposta não é transformar o EVRYLUX em apenas mais um aplicativo de
notas, nem criar complexidade de organização para o usuário.

A direção definida é:

> **O usuário não organiza o Cérebro. O Cérebro se organiza conforme o
> usuário o utiliza.**

O usuário deve poder registrar informações de maneira simples. O EVRYLUX
será responsável por interpretar, estruturar, relacionar, recuperar e,
progressivamente, refletir sobre o conhecimento acumulado.

------------------------------------------------------------------------

## 2. Problema que queremos resolver

Um bloco de notas tradicional resolve bem a captura de informação, mas
conforme o volume cresce surgem problemas:

-   o usuário esquece onde escreveu;
-   não lembra as palavras exatas utilizadas;
-   informações relacionadas ficam separadas;
-   dúvidas antigas podem permanecer sem resposta;
-   ideias são esquecidas;
-   projetos e assuntos ficam pela metade;
-   conhecimentos antigos podem ser contraditos ou atualizados;
-   torna-se difícil perceber a evolução do próprio aprendizado.

O EVRYLUX deve transformar registros isolados em uma **memória pessoal
estruturada e consultável**.

A ideia central deixa de ser apenas:

> "Guardar e pesquisar anotações."

e passa a ser:

> **"Registrar conhecimento e poder fazer perguntas sobre tudo aquilo
> que você já aprendeu, pensou e construiu."**

------------------------------------------------------------------------

## 3. O que já existe e deve ser preservado

O Cérebro já possui uma camada de pesquisa capaz de aceitar consultas em
linguagem natural.

Exemplos de consultas que já fazem parte do conceito atual:

-   "Onde eu falei de Redis?"
-   "O que estudei ontem?"
-   "O que anotei ontem à noite?"
-   "Me mostre 5 perguntas sobre C++."
-   consultas com assunto;
-   consultas com período/data;
-   consultas com período do dia;
-   consultas com quantidade;
-   consultas relacionadas ao tipo de registro.

A nova arquitetura **não deve substituir nem duplicar essa pesquisa**.

A pesquisa atual deve se tornar uma das fundações da nova camada de
inteligência.

------------------------------------------------------------------------

# 4. Princípio de UX --- Zero-Friction Capture

## 4.1 Decisão central

A tela atual de criação que exige escolher previamente entre opções
como:

``` text
Conceito
Pergunta
Exemplo
Atenção
```

deve deixar de ser o fluxo principal.

Essa escolha exige que o usuário **organize a informação antes mesmo de
registrá-la**, contrariando a direção definida para o EVRYLUX.

A nova regra é:

> **O EVRYLUX não deve perguntar ao usuário como organizar uma
> informação antes de permitir salvá-la.**

O usuário fornece o conteúdo primeiro.

O sistema decide depois:

-   tipo;
-   conceitos;
-   assuntos;
-   estado;
-   relações;
-   indexação;
-   possíveis vínculos com registros anteriores.

------------------------------------------------------------------------

## 4.2 Novo fluxo principal de captura

O fluxo desejado deve ser aproximadamente:

``` text
+ Adicionar
      ↓
┌──────────────────────────────────────────────┐
│ ✨ Adicionar ao Cérebro                     │
│                                              │
│ Escreva, cole ou registre qualquer coisa.   │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ O que você quer guardar?                │ │
│ │                                          │ │
│ │                                          │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ 📎 Anexar                         Salvar →   │
└──────────────────────────────────────────────┘
      ↓
SALVAR
```

O objetivo é aproximar a energia necessária para registrar algo da
simplicidade de um bloco de notas.

Idealmente:

``` text
+ → escrever/colar → salvar
```

e não:

``` text
+ → escolher tipo → abrir formulário → organizar → preencher → salvar
```

------------------------------------------------------------------------

## 4.3 Exemplo: dúvida

Usuário escreve:

``` text
Ainda não entendi direito quando usar weak_ptr.
```

E toca em **Salvar**.

Internamente:

``` text
conteúdo recebido
       ↓
classificação automática
       ↓
tipo: dúvida
estado: aberta
       ↓
extração de conceitos
       ↓
C++
smart pointers
weak_ptr
ownership
       ↓
busca de registros relacionados
       ↓
criação de relações
       ↓
indexação
```

Nenhuma dessas decisões precisa ser exigida do usuário antes do
salvamento.

------------------------------------------------------------------------

## 4.4 Exemplo: conhecimento

Usuário escreve:

``` text
unique_ptr representa propriedade exclusiva de um recurso.
```

O EVRYLUX pode inferir:

``` text
tipo: conhecimento

conceitos:
- C++
- unique_ptr
- smart pointers
- ownership
- gerenciamento de recursos
```

------------------------------------------------------------------------

## 4.5 Exemplo: ideia

Usuário escreve:

``` text
Tive uma ideia de criar um sistema que encontre empresas
com presença digital ruim e gere uma demonstração.
```

O EVRYLUX pode inferir:

``` text
tipo: ideia

conceitos:
- negócios
- prospecção
- automação
- presença digital
- geração de demonstração
```

O usuário não precisa selecionar previamente uma opção chamada
**Ideia**.

------------------------------------------------------------------------

## 4.6 Não aumentar o número de opções manuais

A solução **não** será transformar:

``` text
Conceito
Pergunta
Exemplo
Atenção
```

em:

``` text
Conceito
Pergunta
Exemplo
Atenção
Ideia
Problema
Solução
Decisão
Projeto
Objetivo
...
```

Isso aumentaria a carga cognitiva justamente quando queremos reduzi-la.

Esses tipos podem existir no modelo interno sem aparecer como uma
decisão obrigatória na entrada.

------------------------------------------------------------------------

## 4.7 Classificação automática com correção opcional

Automação não significa remover o controle do usuário.

Depois que o EVRYLUX classificar um registro, poderá existir uma ação
discreta como:

``` text
Ajustar classificação
```

ou:

``` text
Editar organização
```

Ela será utilizada quando:

-   o EVRYLUX interpretar algo incorretamente;
-   o usuário quiser alterar o tipo;
-   quiser corrigir conceitos;
-   quiser confirmar ou alterar um estado;
-   quiser remover/adicionar uma relação.

### Regra

> **Correção manual é uma exceção, não uma etapa obrigatória da
> captura.**

------------------------------------------------------------------------

## 4.8 Salvar primeiro, enriquecer depois

A captura não deve ficar bloqueada esperando processamento pesado de IA.

A direção arquitetural desejada é:

``` text
USUÁRIO
   ↓
SALVAR CONTEÚDO
   ↓
registro já existe no Cérebro
   ↓
ENRIQUECIMENTO
   ├── classificação
   ├── conceitos
   ├── relações
   ├── estado
   └── indexação semântica
```

Quando tecnicamente adequado, o enriquecimento poderá acontecer de forma
assíncrona ou progressiva.

O princípio é:

> **Nunca tornar uma anotação difícil de salvar apenas porque o Cérebro
> possui inteligência avançada.**

------------------------------------------------------------------------

## 4.9 Falha da IA não pode significar perda da anotação

Se classificação, embeddings, relações ou outro processamento falhar, o
conteúdo original deve continuar salvo.

Conceitualmente:

``` text
conteúdo bruto = fonte principal
enriquecimento = camada derivada
```

Isso evita que a inteligência automática torne a captura menos confiável
que um bloco de notas.

------------------------------------------------------------------------

## 4.10 Interface bonita, mas mínima

A simplificação não significa tornar o EVRYLUX visualmente pobre.

A tela pode continuar:

-   moderna;
-   limpa;
-   elegante;
-   consistente com a identidade atual;
-   com boa tipografia;
-   com animações sutis;
-   com feedback de salvamento.

Mas o visual não deve introduzir decisões desnecessárias.

A beleza deve estar na **clareza**, não na quantidade de controles.

------------------------------------------------------------------------

## 4.11 Entrada simples, inteligência interna

O princípio definitivo é:

> **O usuário registra. O EVRYLUX entende.**

O usuário não deve ser obrigado a:

-   criar pastas;
-   criar vários "cérebros";
-   construir árvores de assuntos;
-   escolher categorias antes de escrever;
-   relacionar registros manualmente;
-   preencher metadados técnicos;
-   decidir se algo é conceito, pergunta, exemplo ou atenção antes de
    salvá-lo.

A complexidade deve existir **dentro do EVRYLUX**, não na cabeça do
usuário.

------------------------------------------------------------------------

# 5. Decisão: um único Cérebro auto-organizado

Foi descartada, neste momento, a ideia de obrigar o usuário a criar
diferentes Cérebros como:

``` text
Cérebro C++
Cérebro Eletrônica
Cérebro Segurança
Cérebro Flutter
```

Isso adicionaria organização manual e complexidade desnecessária.

O EVRYLUX continuará trabalhando conceitualmente com **um Cérebro
pessoal**.

Dentro dele, o próprio sistema identifica:

-   assuntos;
-   conceitos;
-   grupos;
-   relações;
-   dúvidas;
-   conhecimentos;
-   projetos;
-   ideias;
-   evolução temporal.

Exemplo interno:

``` text
C++
│
├── Ponteiros
│   ├── referências
│   └── ponteiros crus
│
├── Smart Pointers
│   ├── unique_ptr
│   ├── shared_ptr
│   └── weak_ptr
│
├── RAII
│
└── Move Semantics
```

Essa estrutura não precisa ser criada manualmente pelo usuário.

Ela emerge dos registros.

------------------------------------------------------------------------

# 6. Nova camada: Brain Reflection / Brain Reasoning

A principal evolução planejada é adicionar uma camada acima da pesquisa
atual.

Arquitetura conceitual:

``` text
                    PERGUNTA
                       │
                       ▼
              ┌─────────────────┐
              │ Intent Analyzer │
              └────────┬────────┘
                       │
                       ▼
          ┌────────────────────────┐
          │ Pesquisa atual EVRYLUX │
          │       Retrieval        │
          └────────────┬───────────┘
                       │
                       ▼
                   Evidências
                       │
                       ▼
              ┌─────────────────┐
              │ Brain Reasoning │
              │ / Reflection    │
              └────────┬────────┘
                       │
                       ▼
               RESPOSTA + FONTES
```

A diferença fundamental será:

### Pesquisa

Responde:

> "Onde está determinada informação?"

### Reflexão

Responde:

> "O que meu conjunto de informações significa?"

------------------------------------------------------------------------

# 7. Perguntas que a primeira versão deverá entender

A primeira versão da camada de Reflexão deverá ser projetada para
responder pelo menos às seguintes intenções.

## 7.1 O que eu aprendi?

Exemplos:

-   "O que eu aprendi?"
-   "O que aprendi esta semana?"
-   "O que aprendi sobre C++ este mês?"
-   "Quais foram meus principais aprendizados recentes?"

O sistema deverá recuperar conhecimentos relevantes, agrupá-los por
conceitos/assuntos e produzir uma síntese baseada nos registros
existentes.

------------------------------------------------------------------------

## 7.2 O que ainda não entendi?

Exemplos:

-   "O que ainda não entendi?"
-   "Quais dúvidas ainda tenho?"
-   "O que ainda não entendi sobre C++?"
-   "Que assuntos ficaram sem resposta?"

O sistema deverá procurar:

-   dúvidas abertas;
-   perguntas sem resolução posterior;
-   conceitos com sinais de entendimento parcial;
-   registros que indiquem dificuldade;
-   possíveis lacunas sustentadas pelo histórico.

Exemplo:

``` text
Move semantics

→ dúvida registrada há 12 dias
→ nenhuma resolução posterior encontrada
```

A resposta deve explicar **por que** aquilo foi considerado uma possível
lacuna.

------------------------------------------------------------------------

## 7.3 Que ideias tive?

Exemplos:

-   "Que ideias tive?"
-   "Quais ideias tive sobre negócios?"
-   "Que ideias de projetos tive nos últimos meses?"
-   "Quais ideias minhas são parecidas?"

O EVRYLUX deverá:

-   encontrar registros classificados como ideias;
-   identificar conceitos;
-   agrupar ideias semanticamente relacionadas;
-   permitir recuperar ideias antigas mesmo quando palavras diferentes
    foram utilizadas.

------------------------------------------------------------------------

## 7.4 O que estou deixando pela metade?

Exemplos:

-   "O que deixei pela metade?"
-   "O que comecei e não terminei?"
-   "Que projetos parecem abandonados?"
-   "O que eu estava estudando de C++ e larguei?"

Possíveis evidências:

-   atividade antiga sem continuação;
-   registro marcado/inferido como projeto ou objetivo;
-   próxima ação sem atividade posterior;
-   dúvida aberta associada ao assunto;
-   ausência de evidência de conclusão.

O sistema não deve afirmar arbitrariamente que algo foi abandonado. Deve
apresentar como uma inferência baseada em evidências.

------------------------------------------------------------------------

## 7.5 Em que assuntos estou focando mais?

Exemplos:

-   "No que estou focando?"
-   "Sobre o que mais tenho estudado?"
-   "Em que assuntos estou gastando mais tempo?"
-   "Qual assunto mais apareceu este mês?"

Possíveis sinais:

-   frequência de registros;
-   sessões;
-   distribuição temporal;
-   recorrência dos conceitos;
-   quantidade de atividade recente.

Sempre que o sistema não possuir dados suficientes para medir "tempo",
deve deixar claro que está usando atividade/frequência como aproximação,
e não inventar horas.

------------------------------------------------------------------------

## 7.6 Quais coisas que escrevi estão relacionadas?

Exemplos:

-   "Quais coisas estão relacionadas?"
-   "O que se conecta com essa anotação?"
-   "Quais ideias minhas falam de problemas parecidos?"
-   "Isso tem relação com algo que já estudei?"

A camada deverá aproveitar:

-   similaridade semântica;
-   conceitos extraídos;
-   relações explícitas;
-   relações inferidas;
-   proximidade contextual;
-   histórico.

------------------------------------------------------------------------

## 7.7 O que posso retomar?

Exemplos:

-   "O que posso retomar?"
-   "O que ficou parado?"
-   "Tem alguma coisa importante que eu poderia continuar?"
-   "Que estudos antigos ainda possuem pendências?"

O EVRYLUX **não deve decidir pelo usuário** o que ele obrigatoriamente
deve fazer.

A resposta deverá apresentar possibilidades e critérios.

Exemplo:

``` text
C++ / ownership

Motivos:
→ dúvida ainda aberta
→ assunto estudado várias vezes
→ 21 dias sem atividade
```

O usuário toma a decisão.

------------------------------------------------------------------------

## 7.8 O que mudou no meu conhecimento?

Exemplos:

-   "O que mudou?"
-   "Como meu conhecimento sobre C++ evoluiu?"
-   "O que eu pensava antes e penso diferente agora?"
-   "O que aprendi desde que comecei a estudar isso?"

Essa função deverá comparar registros em diferentes momentos e
identificar:

-   novos conceitos;
-   dúvidas posteriormente resolvidas;
-   conhecimentos aprofundados;
-   possíveis correções;
-   contradições;
-   mudanças de entendimento.

------------------------------------------------------------------------

# 8. Intent Analyzer

As perguntas anteriores não devem existir apenas como oito botões
rígidos.

O EVRYLUX deverá interpretar diferentes maneiras de formular a mesma
intenção.

Exemplo:

``` text
"O que eu estava estudando de C++ que acabei largando?"
```

Pode resultar internamente em algo semelhante a:

``` text
intent: INCOMPLETE_OR_INACTIVE
subject: C++
```

Outro exemplo:

``` text
"O que aprendi sobre ponteiros esse mês?"
```

Pode resultar em:

``` text
intent: LEARNING_SUMMARY
subject: ponteiros
period: este mês
```

O objetivo é manter a linguagem natural como principal interface.

------------------------------------------------------------------------

# 9. Classificação automática dos registros

Os registros devem ganhar significado estrutural.

Tipos iniciais possíveis:

``` text
conhecimento
dúvida
ideia
problema
solução
decisão
projeto
objetivo
```

Essa lista poderá evoluir conforme os testes reais mostrarem
necessidade.

O usuário não deverá necessariamente selecionar o tipo.

Exemplo:

``` text
"Ainda não entendi quando devo usar unique_ptr."
```

O sistema pode inferir:

``` text
tipo: dúvida
estado: aberta

conceitos:
- C++
- smart pointers
- unique_ptr
- ownership
```

------------------------------------------------------------------------

# 10. Extração automática de conceitos

Cada registro poderá possuir conceitos associados automaticamente.

Exemplo:

``` text
"weak_ptr permite observar um objeto gerenciado por shared_ptr
sem aumentar a contagem de referências."
```

Possíveis conceitos:

``` text
C++
smart pointers
weak_ptr
shared_ptr
ownership
reference counting
```

Isso permitirá recuperar conhecimento sem depender exclusivamente das
palavras exatas usadas na anotação.

------------------------------------------------------------------------

# 11. Relações entre registros

Uma das partes centrais da evolução será permitir que registros formem
relações.

Relações inicialmente consideradas:

``` text
relacionado_a
responde_a
complementa
possivelmente_contradiz
```

Outras relações só devem ser adicionadas quando houver necessidade real.

Exemplo:

``` text
DÚVIDA

"Não entendi quando usar weak_ptr."
            │
            │ respondida por
            ▼
CONHECIMENTO

"weak_ptr é útil para..."
```

Essas relações formarão gradualmente um **grafo de conhecimento
pessoal**.

------------------------------------------------------------------------

# 12. Estado do conhecimento

Não basta saber que um registro existe.

Alguns registros precisam possuir estado.

Possíveis estados iniciais:

``` text
aberto
possivelmente_resolvido
resolvido
ativo
concluído
possivelmente_desatualizado
```

Nem todo tipo de registro precisa utilizar todos esses estados.

### Regra importante

A IA não deve afirmar automaticamente:

> "Você domina esse assunto."

apenas porque existe uma anotação sobre ele.

O sistema deve trabalhar com evidências e níveis de confiança.

Por exemplo:

``` text
Dúvida sobre weak_ptr
        │
        ▼
Explicação posterior encontrada

Estado:
POSSIVELMENTE_RESOLVIDA
```

O usuário poderá confirmar quando fizer sentido.

------------------------------------------------------------------------

# 13. Importância e conhecimento útil

Também foi discutida a possibilidade de permitir que o usuário marque
registros especialmente valiosos.

Exemplo:

``` text
⭐ Útil
⭐ Importante
```

Isso pode servir futuramente para:

-   priorizar resultados;
-   selecionar conhecimento de alta qualidade;
-   preparar conteúdo para compartilhamento;
-   distinguir anotação bruta de conhecimento curado.

Não devemos transformar isso em uma obrigação de organização.

É uma ação opcional.

------------------------------------------------------------------------

# 14. Evidências e explicabilidade

Uma regra importante da nova camada será:

> **Conclusões devem poder mostrar de onde vieram.**

Exemplo:

``` text
Possível lacuna: Move Semantics

Você registrou uma dúvida há 12 dias e não encontrei
posteriormente um conhecimento que pareça resolvê-la.

[Ver evidências]
```

Ao abrir as evidências, o usuário poderá visualizar os registros
utilizados.

Isso é importante para:

-   confiança;
-   correção de erros da IA;
-   navegação;
-   transparência;
-   evitar respostas sem fundamento no próprio Cérebro.

------------------------------------------------------------------------

# 15. Relação temporal

O tempo será uma dimensão importante do Cérebro.

O EVRYLUX deverá progressivamente conseguir compreender:

``` text
registro antigo
      ↓
novo aprendizado
      ↓
dúvida
      ↓
resolução
      ↓
aprofundamento
```

Isso permitirá responder perguntas como:

> "Como meu entendimento disso evoluiu?"

ou:

> "Essa informação ainda parece atual dentro do meu próprio Cérebro?"

------------------------------------------------------------------------

# 16. Busca semântica

A recuperação não deve depender somente de correspondência literal.

Exemplo:

O usuário registrou:

``` text
"Quero prospectar negócios locais que possuem presença digital ruim
e criar uma demonstração de site."
```

Meses depois pergunta:

> "Qual era aquela ideia de ganhar dinheiro com empresas sem site?"

Mesmo que as palavras sejam diferentes, o sistema deve tentar recuperar
o registro por significado.

A busca semântica deverá trabalhar junto da busca/filtros atuais, não
necessariamente substituí-los.

------------------------------------------------------------------------

# 17. Síntese

A nova camada deverá conseguir receber vários registros relevantes e
produzir uma resposta consolidada.

Exemplo:

``` text
Pergunta:
"O que eu já sei sobre smart pointers?"
```

Em vez de apenas listar 20 resultados, o EVRYLUX poderá:

1.  recuperar os registros;
2.  identificar conceitos recorrentes;
3.  agrupar registros;
4.  sintetizar;
5.  indicar dúvidas;
6.  mostrar evidências.

A IA atua como mecanismo de interpretação e síntese.

O EVRYLUX fornece a memória e as evidências.

------------------------------------------------------------------------

# 18. Fluxo desejado de uma pergunta

Exemplo:

``` text
"O que ainda não entendi sobre C++?"
```

Fluxo:

``` text
1. Interpretar intenção
        ↓
KNOWLEDGE_GAPS

2. Identificar assunto
        ↓
C++

3. Recuperar evidências
        ↓
dúvidas
problemas
conhecimentos
relações
histórico

4. Avaliar estados
        ↓
abertas
possivelmente resolvidas
resolvidas

5. Agrupar por conceito
        ↓
ownership
move semantics
weak_ptr
...

6. Brain Reasoning
        ↓
síntese baseada nas evidências

7. Responder
        ↓
resultado + explicação + registros utilizados
```

------------------------------------------------------------------------

# 19. Fluxo de criação de conhecimento

A captura deve continuar simples.

Exemplo:

``` text
Usuário:

"Ainda não consegui entender move semantics."
```

Processamento interno:

``` text
SALVAR REGISTRO
      ↓
CLASSIFICAR
      ↓
tipo = dúvida
      ↓
EXTRAIR CONCEITOS
      ↓
C++
move semantics
ownership
      ↓
BUSCAR RELAÇÕES
      ↓
registros relacionados
      ↓
DEFINIR ESTADO
      ↓
aberta
      ↓
INDEXAR
```

Posteriormente:

``` text
"Agora entendi que std::move não move diretamente..."
```

O sistema pode:

``` text
classificar como conhecimento
        ↓
detectar move semantics
        ↓
encontrar dúvida anterior
        ↓
criar relação responde_a
        ↓
marcar dúvida como possivelmente_resolvida
```

------------------------------------------------------------------------

# 20. Interface planejada

A pesquisa atual poderá evoluir conceitualmente para:

## Pergunte ao Cérebro

``` text
┌────────────────────────────────────────────┐
│ O que você quer saber sobre o que          │
│ já registrou?                              │
└────────────────────────────────────────────┘
```

Sugestões podem aparecer como atalhos:

``` text
O que aprendi?
O que ainda não entendi?
Que ideias tive?
O que deixei pela metade?
No que estou focando?
O que está relacionado?
O que posso retomar?
O que mudou?
```

Esses atalhos ajudam a descobrir a funcionalidade, mas não limitam a
linguagem.

O usuário continua podendo escrever qualquer pergunta natural.

------------------------------------------------------------------------

# 21. Público e privado --- preparação futura

A ideia de compartilhamento continua válida, mas **não será prioridade
da primeira implementação**.

A arquitetura deverá evitar decisões que impeçam futuramente que um
registro possua visibilidade.

Conceitualmente:

``` text
visibility:
PRIVATE
PUBLIC
```

Por padrão:

``` text
PRIVATE
```

No futuro, o usuário poderá escolher conhecimentos específicos e
publicá-los.

Isso é diferente de tornar todo o Cérebro público.

------------------------------------------------------------------------

# 22. Possível visão futura de publicação

Uma pessoa poderá passar anos construindo conhecimento dentro do
EVRYLUX.

Durante esse processo:

-   cria registros;
-   resolve dúvidas;
-   acumula experiências;
-   marca conhecimentos úteis;
-   corrige informações;
-   cria relações;
-   desenvolve conhecimento especializado.

Depois poderá selecionar uma parte curada:

``` text
Meu Cérebro pessoal
        ↓
selecionar conhecimentos públicos
        ↓
coleção pública / conhecimento publicado
```

A organização para publicação acontece **na saída**, não durante a
captura.

Isso preserva a simplicidade do Cérebro pessoal.

------------------------------------------------------------------------

# 23. Possível valor futuro

O EVRYLUX pode evoluir de:

``` text
aplicativo de anotações
```

para:

``` text
memória pessoal pesquisável
```

e depois para:

``` text
sistema de conhecimento pessoal
```

e finalmente:

``` text
sistema capaz de refletir sobre
o conhecimento acumulado pelo usuário
```

A proposta não é substituir a internet ou uma IA geral.

A diferença conceitual é:

``` text
Internet
→ conhecimento disponível no mundo

IA geral
→ raciocínio e conhecimento do modelo/contexto fornecido

EVRYLUX
→ memória longitudinal construída pelo próprio usuário
```

Uma pergunta especialmente importante para o produto é:

> **"Com base no que EU já registrei, o que sei, o que não sei e como
> isso evoluiu?"**

------------------------------------------------------------------------

# 24. O que NÃO será construído agora

Para evitar complexidade prematura, ficam fora do escopo inicial:

-   múltiplos Cérebros manuais;
-   marketplace;
-   pagamentos;
-   venda de Cérebros;
-   seguidores;
-   feed social;
-   avaliações públicas;
-   perfis complexos de criadores;
-   organização manual obrigatória;
-   árvores manuais de conhecimento;
-   dezenas de categorias obrigatórias.

Essas possibilidades poderão ser revisitadas somente depois que o valor
central estiver comprovado.

------------------------------------------------------------------------

# 25. Primeira implementação planejada

## Prioridade 0 --- Captura sem fricção

Antes de depender da nova camada de Reflexão, simplificar o fluxo
principal de criação.

Objetivo:

``` text
+ → escrever/colar → salvar
```

Remover do caminho obrigatório a escolha prévia entre `Conceito`,
`Pergunta`, `Exemplo` e `Atenção`.

O conteúdo deve ser salvo primeiro e enriquecido automaticamente pelo
sistema.

Essa prioridade existe porque todas as capacidades futuras dependem de o
usuário realmente alimentar o Cérebro.

A implementação inicial deverá se concentrar em quatro fundações.

## Fundação 1 --- Estrutura automática

Adicionar ou adaptar suporte para:

``` text
tipo
conceitos
estado
importância
relações
```

sem exigir preenchimento manual.

## Fundação 2 --- Relações

Criar mecanismo para identificar e armazenar relações entre registros.

Começar simples:

``` text
relacionado_a
responde_a
complementa
possivelmente_contradiz
```

## Fundação 3 --- Reflexão

Criar a camada `Brain Reflection / Brain Reasoning`.

Primeiras intenções:

``` text
LEARNING_SUMMARY
KNOWLEDGE_GAPS
IDEA_REVIEW
INCOMPLETE_OR_INACTIVE
FOCUS_ANALYSIS
RELATED_KNOWLEDGE
RESUME_CANDIDATES
KNOWLEDGE_EVOLUTION
```

Os nomes internos podem mudar conforme a arquitetura real do projeto.

## Fundação 4 --- Evidências

Toda reflexão relevante deverá retornar também os registros que
sustentaram a conclusão.

------------------------------------------------------------------------

# 26. Regra para implementação no projeto existente

Antes de escrever essa nova camada, deve ser analisada a versão atual do
EVRYLUX para identificar:

-   modelos atuais de conhecimento;
-   tabelas e migrations do Supabase;
-   repositories;
-   services;
-   mecanismo atual de pesquisa;
-   parser/intérprete de linguagem natural;
-   busca semântica existente, caso haja;
-   embeddings existentes, caso haja;
-   sistema de IA existente;
-   cache;
-   tela atual do Cérebro;
-   criação/edição de conhecimento;
-   tipos já existentes;
-   sistema de relações existente, caso haja.

### Objetivo

**Reutilizar o máximo possível.**

Não criar:

``` text
pesquisa antiga
+
pesquisa nova independente
+
sistema de IA duplicado
```

O desejado é:

``` text
INFRAESTRUTURA EXISTENTE
          │
          ▼
RECUPERAÇÃO
          │
          ▼
NOVA CAMADA DE REFLEXÃO
```

------------------------------------------------------------------------

# 27. Como validar se a ideia realmente funciona

Após a primeira implementação, o EVRYLUX deve ser usado como produto,
não apenas testado como software.

Durante algumas semanas:

1.  registrar informações reais;
2.  evitar criar features grandes;
3.  usar o EVRYLUX como primeira opção para recuperar conhecimento;
4.  observar fricções;
5.  fazer perguntas reais, não consultas artificiais de teste.

Perguntas de validação:

``` text
O que eu aprendi?

O que ainda não entendi?

Que ideias tive?

O que estou deixando pela metade?

Em que assuntos estou focando?

Quais coisas que escrevi estão relacionadas?

O que posso retomar?

O que mudou no meu conhecimento?
```

O principal sinal de valor será quando o EVRYLUX recuperar ou revelar
algo que o usuário havia genuinamente esquecido.

Exemplo:

> "Eu tinha esquecido completamente que já tinha pensado nisso."

Outro sinal:

> "Olhando essas informações juntas, percebi uma relação que não tinha
> notado."

------------------------------------------------------------------------

# 28. Métrica conceitual de sucesso

A pergunta principal não deve ser:

> "Quantas funcionalidades o EVRYLUX possui?"

Deve ser:

> **"O usuário sentiria falta do Cérebro se ele desaparecesse amanhã?"**

Outras perguntas úteis:

-   o usuário registra conhecimento espontaneamente?
-   ele procura primeiro no EVRYLUX?
-   consegue recuperar coisas esquecidas?
-   as relações automáticas ajudam?
-   as reflexões revelam algo útil?
-   registrar é rápido?
-   a organização automática funciona sem intervenção constante?
-   as respostas conseguem mostrar evidências confiáveis?

------------------------------------------------------------------------

# 29. Princípios finais do Cérebro EVRYLUX

## 1. Capturar deve exigir o mínimo possível

> **Abrir, escrever ou colar e salvar.**

Nenhuma classificação prévia deve ser obrigatória.

## 2. Organização deve ser automática

> O usuário não precisa construir a taxonomia antes de possuir
> conhecimento.

## 3. Pesquisa deve aceitar linguagem humana

> O usuário pergunta como pensa.

## 4. Recuperação deve funcionar por significado

> Não depender apenas de palavras exatas.

## 5. Conhecimentos devem se relacionar

> Registros não devem permanecer ilhas para sempre.

## 6. O tempo importa

> Conhecimento evolui.

## 7. Dúvidas precisam poder encontrar respostas posteriores

> O Cérebro deve acompanhar continuidade.

## 8. Reflexões precisam de evidências

> O usuário deve conseguir entender de onde uma conclusão veio.

## 9. A IA não deve fingir certeza

> Inferências devem ser apresentadas como inferências.

## 10. Privacidade é o padrão

> Conhecimento pessoal nasce privado.

## 11. Compartilhamento é uma possibilidade futura

> O usuário poderá escolher o que vale tornar público.

## 12. Complexidade fica no sistema

> **O usuário não organiza o Cérebro. O Cérebro se organiza conforme o
> usuário o utiliza.**

------------------------------------------------------------------------

# 30. Visão resumida

``` text
                    USUÁRIO
                       │
                  escreve algo
                       │
                       ▼
              ┌─────────────────┐
              │     EVRYLUX     │
              └────────┬────────┘
                       │
          ┌────────────┼─────────────┐
          ▼            ▼             ▼
     classifica     conceitos     relações
          │            │             │
          └────────────┼─────────────┘
                       ▼
               MEMÓRIA ESTRUTURADA
                       │
                       ▼
                  PESQUISA
                       │
                       ▼
                  REFLEXÃO
                       │
          ┌────────────┼─────────────┐
          ▼            ▼             ▼
      aprendizado    lacunas      conexões
          │            │             │
          └────────────┼─────────────┘
                       ▼
             RESPOSTA + EVIDÊNCIAS
```

------------------------------------------------------------------------

## Frase guia

> **Você registra. O EVRYLUX entende, organiza e relaciona. Quando
> precisar, você pergunta ao seu próprio conhecimento.**

------------------------------------------------------------------------

# 31. Arquitetura final definida --- Cérebro local + IA opcional

## 31.1 Decisão central

O EVRYLUX não deve depender de uma IA externa para existir ou para
cumprir suas funções fundamentais.

A divisão definida é:

``` text
                    EVRYLUX

        ┌─────────────────────────────┐
        │       CÉREBRO LOCAL         │
        │                             │
        │ registros                   │
        │ conceitos                   │
        │ relações                    │
        │ estados                     │
        │ histórico                   │
        │ busca                       │
        │ grafo                       │
        └──────────────┬──────────────┘
                       │
              funciona offline
                       │
                       ▼
        ┌─────────────────────────────┐
        │       IA OPCIONAL           │
        │                             │
        │ interpreta perguntas        │
        │ sintetiza evidências         │
        │ compara conhecimento         │
        │ sugere próximos assuntos     │
        │ complementa contexto         │
        └─────────────────────────────┘
```

Regra arquitetural:

> **Nenhuma função fundamental do Cérebro deve depender de uma IA
> externa.**

A IA melhora a experiência, mas não é necessária para:

-   salvar;
-   classificar intenções explícitas;
-   pesquisar;
-   recuperar histórico;
-   navegar por conceitos;
-   encontrar relações locais;
-   visualizar o grafo;
-   consultar registros offline.

------------------------------------------------------------------------

# 32. Novo propósito do Cérebro

O EVRYLUX não deve tentar competir com a internet ou com uma IA geral
para responder perguntas como:

``` text
O que é weak_ptr?
Como funciona TCP?
O que é um ESP32?
```

A internet já resolve esse tipo de pergunta rapidamente.

O diferencial do EVRYLUX deve estar em perguntas que dependem do
histórico pessoal:

``` text
O que EU já sei sobre weak_ptr?

Eu já tive essa dúvida antes?

Que problemas eu já tive com ESP32 e como resolvi?

O que venho estudando sobre C++?

Quais dúvidas continuam abertas?

Como meu conhecimento mudou?

Que ideias minhas estão relacionadas?

O que comecei e não continuei?

Que assuntos fazem sentido explorar a partir
do que venho estudando?
```

Nova formulação do produto:

> **O EVRYLUX constrói um mapa do que o usuário sabe ao longo do
> tempo.**

A busca continua importante, mas passa a ser infraestrutura para uma
função maior:

``` text
REGISTRAR
    ↓
ESTRUTURAR
    ↓
RELACIONAR
    ↓
ACUMULAR
    ↓
ENTENDER
    ↓
REFLETIR
```

------------------------------------------------------------------------

# 33. Captura final definida

Ao tocar em `+`, o usuário deve ir diretamente para:

``` text
┌──────────────────────────────────────────────┐
│ ✨ Adicionar ao Cérebro                  ⓘ  │
│                                              │
│ Escreva ou cole qualquer coisa.              │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ O que você quer guardar?                │ │
│ │                                          │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ 📎 Anexar                          Salvar →  │
└──────────────────────────────────────────────┘
```

Fluxo:

``` text
+ → escrever/colar → salvar
```

O usuário não precisa escolher previamente:

``` text
Conceito
Pergunta
Exemplo
Atenção
Ideia
Problema
Solução
...
```

O conteúdo original é sempre salvo primeiro.

------------------------------------------------------------------------

# 34. Ajuda `ⓘ` e intenções explícitas opcionais

O botão `ⓘ` deve explicar que organização manual não é necessária.

Exemplo:

``` text
Como registrar

Você não precisa organizar nada.
Escreva normalmente e o EVRYLUX fará o restante.

Se quiser deixar sua intenção explícita, pode usar:

Dúvida: ...
Ideia: ...
Aprendi: ...
Problema: ...
Solução: ...
Decisão: ...
Projeto: ...

Essas indicações são opcionais.
```

Esses prefixos não são comandos técnicos obrigatórios.

Eles são linguagem natural com significado explícito.

Exemplos:

``` text
Dúvida: quando devo usar weak_ptr?

Aprendi: unique_ptr possui ownership exclusivo.

Problema: meu ESP32 reinicia quando ligo o display.

Solução: descobri que o problema era queda de tensão.

Ideia: criar um analisador portátil usando ESP32.

Decisão: vou utilizar SQLite localmente.
```

Quando houver prefixo explícito:

``` text
"Dúvida:"
    ↓
QUESTION
confidence = 1.0
```

Quando não houver:

``` text
texto normal
    ↓
classificação local quando houver evidência suficiente
    ↓
ou NOTE / UNCLASSIFIED
```

Regra:

> **Não saber classificar é melhor do que classificar errado.**

------------------------------------------------------------------------

# 35. Inteligência local sem IA

A primeira inteligência do EVRYLUX será determinística e offline.

Ela pode combinar:

-   parser de intenção;
-   normalização textual;
-   remoção de stopwords;
-   stemming/lematização quando apropriado;
-   termos importantes;
-   aliases;
-   sinônimos locais;
-   índice textual;
-   FTS;
-   BM25;
-   datas;
-   tipos;
-   frequência;
-   raridade de termos;
-   conceitos conhecidos;
-   relações incrementais.

Fluxo:

``` text
NOVO REGISTRO
     ↓
salvar original
     ↓
Intent Parser
     ↓
normalização
     ↓
extração local de termos/conceitos
     ↓
indexação
     ↓
busca de candidatos relacionados
     ↓
Relationship Scorer
     ↓
somente relações úteis
```

Nenhuma dessas etapas exige internet.

------------------------------------------------------------------------

# 36. Relações incrementais

O EVRYLUX não precisa reanalisar todo o Cérebro constantemente.

A estratégia definida é incremental:

> **Entrou algo novo → verificar se esse novo registro possui relações
> relevantes com registros anteriores.**

Exemplo:

Registro antigo:

``` text
Problema: meu ESP32 reinicia quando ligo o display.
```

Novo registro:

``` text
Solução: descobri que a alimentação caía quando
o backlight do display era ligado.
```

Pipeline:

``` text
NOVO REGISTRO
      ↓
extrair termos
      ↓
buscar candidatos locais
      ↓
Top N candidatos
      ↓
calcular força das relações
      ↓
salvar somente relações fortes
```

Não comparar diretamente o novo registro com todos os registros
existentes.

------------------------------------------------------------------------

# 37. Busca de candidatos eficiente

Para um Cérebro grande:

``` text
100.000 registros
```

não executar:

``` text
novo registro × 99.999 comparações profundas
```

Executar:

``` text
novo registro
     ↓
FTS / BM25 / índice local
     ↓
Top 20 ou Top 50 candidatos
     ↓
filtros por conceitos/tipos
     ↓
Relationship Scorer
     ↓
poucas relações realmente úteis
```

O número exato de candidatos deve ser calibrado posteriormente.

------------------------------------------------------------------------

# 38. Relationship Scorer local

A força de uma possível relação pode considerar sinais como:

``` text
similaridade textual
+
termos importantes compartilhados
+
raridade dos termos
+
conceitos compartilhados
+
compatibilidade dos tipos
+
proximidade contextual
```

Exemplo:

``` text
A:
Problema: meu ESP32 reinicia quando ligo o display.

B:
Solução: a alimentação insuficiente fazia o ESP32
reiniciar ao ligar o backlight.
```

Sinais fortes:

``` text
ESP32
reiniciar
display/backlight
problema ↔ solução
```

O sistema gera um `relationship_score`.

Os thresholds não devem ser tratados como definitivos antes de testes
com dados reais.

Princípio:

> **É melhor perder uma relação fraca do que criar muitas relações
> inúteis.**

Por padrão:

``` text
NÃO RELACIONAR
```

até existir evidência suficiente.

------------------------------------------------------------------------

# 39. Dois níveis de conexão

## 39.1 Registro ↔ Conceito

Esse é o tipo de conexão mais comum.

``` text
Registro A ───→ ESP32
Registro B ───→ ESP32
Registro C ───→ alimentação
Registro B ───→ alimentação
```

Isso já forma um grafo útil.

Não é necessário criar uma aresta direta entre todos os registros que
compartilham um assunto.

## 39.2 Registro ↔ Registro

Criar somente quando a relação direta acrescentar significado.

Exemplos futuros:

``` text
POSSIBLY_SOLVED_BY
POSSIBLY_ANSWERS
COMPLEMENTS
CONTINUES
SUPERSEDES
POSSIBLY_CONTRADICTS
```

Na primeira versão offline, relações mais genéricas podem ser usadas de
forma conservadora.

O sistema não deve inventar relações apenas porque dois textos mencionam
o mesmo assunto.

------------------------------------------------------------------------

# 40. Conceitos em vez de excesso de tags

Tags podem existir como apoio, mas não devem ser a estrutura principal.

Separação conceitual:

``` text
TAG
→ agrupamento

CONCEITO
→ significado

RELAÇÃO
→ conexão estrutural
```

Exemplo:

``` text
Registro
│
├── tipo: knowledge
│
├── tags:
│     programação
│     estudo
│
├── conceitos:
│     weak_ptr
│     shared_ptr
│     reference counting
│
└── relações:
      ...
```

O grafo principal deve ser construído principalmente por conceitos e
relações.

------------------------------------------------------------------------

# 41. Concept Resolver local

O EVRYLUX precisa evitar conceitos duplicados.

Exemplo:

``` text
smart pointers
smart pointer
ponteiros inteligentes
ponteiro inteligente
```

não deveriam necessariamente virar quatro nós.

Estrutura possível:

``` text
concept_id: 182

canonical_name:
Smart Pointers

aliases:
- smart pointer
- smart pointers
- ponteiro inteligente
- ponteiros inteligentes
```

O resolver local pode utilizar:

1.  correspondência exata normalizada;
2.  aliases conhecidos;
3.  dicionário local de sinônimos;
4.  similaridade textual;
5.  regras específicas para termos técnicos.

No futuro, IA/embeddings podem melhorar essa etapa, mas não são
obrigatórios.

------------------------------------------------------------------------

# 42. Busca offline

A pesquisa fundamental do Cérebro deve funcionar sem internet.

Estratégia:

``` text
PERGUNTA
   ↓
Query Parser
   ↓
┌───────────┬───────────┬────────────┐
│ data      │ tipo      │ termos     │
└───────────┴───────────┴────────────┘
   ↓
FTS / BM25
   +
conceitos
   +
sinônimos locais
   +
filtros
   ↓
ranking
   ↓
RESULTADOS
```

Exemplo:

``` text
Quais foram minhas últimas 5 dúvidas
sobre ESP32 essa semana?
```

pode virar:

``` text
type = QUESTION
terms = ESP32
period = current_week
order = newest
limit = 5
```

Sem LLM.

------------------------------------------------------------------------

# 43. Sinônimos e vocabulário local

Para aumentar a sensação de pesquisa semântica offline, manter um
dicionário local extensível.

Exemplo:

``` text
erro
bug
falha
problema

resolver
corrigir
consertar
solução

aprender
estudar
entender

pc
computador
desktop

wifi
wi-fi
wireless
```

Esse vocabulário pode evoluir com o projeto.

Não deve substituir conceitos técnicos específicos.

------------------------------------------------------------------------

# 44. O grafo não é uma funcionalidade decorativa

O grafo deve existir para responder perguntas úteis.

Não criar um grafo apenas para visualização.

Ele deve ajudar a responder:

``` text
O que eu já sei?

Quais dúvidas continuam abertas?

Que problema foi posteriormente resolvido?

Que conhecimentos estão conectados?

Como meu conhecimento evoluiu?

O que comecei e não continuei?
```

Um grafo pequeno, esparso e significativo é preferível a um grafo em que
tudo se conecta com tudo.

------------------------------------------------------------------------

# 45. Estado do conhecimento

Tipos e estados são diferentes.

Exemplo:

``` text
type:
QUESTION

state:
OPEN
```

Posteriormente:

``` text
novo conhecimento
      ↓
possível relação com a dúvida
      ↓
POSSIBLY_ANSWERS
```

Estado:

``` text
OPEN
 ↓
POSSIBLY_RESOLVED
```

Não marcar automaticamente como `RESOLVED` apenas porque existe uma
anotação posterior relacionada.

O EVRYLUX deve preservar incerteza.

------------------------------------------------------------------------

# 46. Ausência de registro não significa falta de conhecimento

Regra fundamental:

> **Não encontrar evidência de que o usuário estudou algo não significa
> que ele não saiba aquilo.**

Portanto, o EVRYLUX deve distinguir:

``` text
AUSÊNCIA DE EVIDÊNCIA
```

de:

``` text
EVIDÊNCIA DE LACUNA
```

Uma lacuna pode ter evidências como:

``` text
dúvida explícita
+
nenhuma resolução posterior encontrada
```

ou:

``` text
problema registrado
+
nenhuma solução posterior encontrada
```

A resposta correta seria:

``` text
"Existe uma possível lacuna em weak_ptr:
você registrou uma dúvida sobre o assunto e
não encontrei posteriormente um registro que
pareça resolvê-la."
```

e não:

``` text
"Você não sabe weak_ptr."
```

------------------------------------------------------------------------

# 47. Evolução temporal do conhecimento

O histórico é uma das principais vantagens do EVRYLUX.

Exemplo:

``` text
JANEIRO
"Dúvida: não entendo ponteiros."

      ↓

FEVEREIRO
"Aprendi endereço e desreferenciamento."

      ↓

MARÇO
"Aprendi unique_ptr."

      ↓

ABRIL
"Entendi ownership e RAII."

      ↓

MAIO
"Aprendi como weak_ptr ajuda com ciclos."
```

Isso permite responder:

``` text
Como meu conhecimento de C++ evoluiu?
```

A internet pode explicar C++.

O EVRYLUX pode explicar a trajetória registrada pelo usuário em C++.

------------------------------------------------------------------------

# 48. Papel final da IA

A IA não será responsável por manter o Cérebro funcionando.

Ela será uma camada de raciocínio opcional.

Funções adequadas para IA:

``` text
interpretar perguntas complexas
sintetizar vários registros
explicar padrões
comparar evidências
resumir evolução
sugerir próximos assuntos
complementar com conhecimento geral
```

Funções que devem continuar locais:

``` text
salvar
indexar
buscar
filtrar
consultar histórico
armazenar conceitos
armazenar relações
navegar no grafo
recuperar evidências
```

------------------------------------------------------------------------

# 49. IA respondendo sobre o que o usuário sabe

Pergunta:

``` text
O que eu já sei sobre smart pointers?
```

Fluxo:

``` text
PERGUNTA
   ↓
identificar intenção
   ↓
KNOWLEDGE_SUMMARY
   ↓
assunto = smart pointers
   ↓
Cérebro local recupera:
- registros
- conceitos
- dúvidas
- estados
- relações
- histórico
   ↓
somente evidências relevantes
   ↓
IA opcional
   ↓
síntese
```

A IA não recebe necessariamente o Cérebro inteiro.

Ela recebe um contexto pequeno e relevante recuperado localmente.

Exemplo de resposta desejada:

``` text
Pelos seus registros, você estudou unique_ptr,
shared_ptr, ownership e contagem de referências.

weak_ptr também aparece, mas existe uma dúvida
aberta relacionada ao seu uso em ciclos de referência.
```

Sempre oferecer:

``` text
Ver evidências
```

------------------------------------------------------------------------

# 50. IA e possíveis lacunas

Pergunta:

``` text
O que falta eu aprender sobre smart pointers?
```

O sistema deve separar:

## Evidências pessoais

``` text
o que foi registrado
dúvidas abertas
conceitos estudados
problemas ainda sem solução
```

## Conhecimento externo da IA

``` text
assuntos normalmente relacionados
pré-requisitos
possíveis próximos tópicos
```

Resposta ideal:

``` text
Com base no seu Cérebro:
- há registros sobre unique_ptr e shared_ptr;
- existe uma dúvida aberta sobre weak_ptr.

Como próximos assuntos relacionados, você poderia explorar:
- custom deleters;
- make_unique / make_shared;
- lifetime;
- thread safety da contagem de referências.

Essas são sugestões gerais.
A ausência desses assuntos no Cérebro não significa
que você não os conheça.
```

------------------------------------------------------------------------

# 51. Recomendações baseadas no foco atual

O EVRYLUX pode detectar localmente o foco recente usando:

``` text
frequência de registros
+
recência
+
conceitos
+
tipos
+
atividade temporal
```

Exemplo:

``` text
FOCO RECENTE

C++
└── Memory Management
      └── Smart Pointers
```

Ao pedir ajuda à IA, enviar:

``` text
FOCO ATUAL
+
REGISTROS RECENTES
+
DÚVIDAS ABERTAS
+
CONCEITOS REGISTRADOS
+
PROJETOS/IDEIAS RELACIONADOS
```

Então a pergunta:

``` text
O que faz sentido eu estudar agora considerando
o que venho aprendendo?
```

pode receber recomendações contextualizadas pelo histórico do usuário.

------------------------------------------------------------------------

# 52. Três níveis claros de consulta

A interface pode distinguir três capacidades.

## 52.1 Buscar no meu Cérebro

``` text
🔎 Buscar no meu Cérebro
```

-   offline;
-   local;
-   rápida;
-   baseada nos registros do usuário.

## 52.2 Analisar com IA

``` text
✨ Analisar com IA
```

-   opcional;
-   utiliza evidências recuperadas do Cérebro;
-   sintetiza e interpreta;
-   pode exigir conexão/modelo disponível.

## 52.3 Complementar com conhecimento externo

``` text
🌐 Complementar com conhecimento externo
```

-   opcional;
-   adiciona conhecimento que não veio do Cérebro;
-   deve deixar clara a diferença entre histórico pessoal e informação
    externa.

Essa separação melhora confiança e transparência.

------------------------------------------------------------------------

# 53. Proveniência das relações

Cada relação automática deve registrar por que foi criada.

Exemplo conceitual:

``` text
relationship
────────────────────────────
from_id: 72
to_id: 10

type:
RELATED

score:
0.91

signals:
- shared_term: esp32
- shared_term: reiniciar
- compatible_intent: solution/problem
- high_bm25_similarity

created_by:
local_relation_engine_v1

created_at:
...
```

Isso permite:

-   explicar relações;
-   depurar falsos positivos;
-   recalcular relações;
-   comparar versões do algoritmo;
-   aumentar confiança do usuário.

------------------------------------------------------------------------

# 54. Versionamento do enriquecimento

A camada derivada deve possuir versão.

Exemplo:

``` text
enrichment_version = 1
relation_engine_version = 1
```

Quando o algoritmo melhorar:

``` text
version < current_version
        ↓
reprocessamento
```

O EVRYLUX pode reconstruir:

-   conceitos;
-   índices;
-   relações;
-   scores;

a partir dos registros originais.

O texto original nunca é alterado automaticamente.

------------------------------------------------------------------------

# 55. Reprocessamento

O sistema deve ser projetado para permitir:

``` text
REGISTROS ORIGINAIS
        ↓
novo algoritmo
        ↓
recriar metadados
        ↓
recriar conceitos
        ↓
recalcular relações
        ↓
reindexar busca
```

Isso permite que um Cérebro criado hoje fique mais inteligente no futuro
sem perder sua história.

------------------------------------------------------------------------

# 56. Ordem de implementação atualizada

A implementação deve acontecer em camadas.

## Fase 1 --- Captura

``` text
+ → escrever/colar → salvar
```

Adicionar:

-   novo Quick Capture;
-   botão `ⓘ`;
-   prefixos opcionais;
-   `NOTE` / `UNCLASSIFIED`;
-   salvamento imediato do original.

## Fase 2 --- Organização local

Adicionar:

-   Intent Parser;
-   normalização;
-   termos relevantes;
-   conceitos básicos;
-   aliases;
-   sinônimos locais.

## Fase 3 --- Busca local

Adicionar ou consolidar:

-   FTS;
-   BM25;
-   filtros;
-   datas;
-   tipos;
-   ranking;
-   consulta natural baseada em regras.

## Fase 4 --- Relações incrementais

``` text
novo registro
     ↓
buscar candidatos
     ↓
Relationship Scorer
     ↓
salvar somente relações fortes
```

Começar principalmente por:

``` text
Registro ↔ Conceito
```

e ser conservador com:

``` text
Registro ↔ Registro
```

## Fase 5 --- Grafo útil

Permitir navegar:

-   registros;
-   conceitos;
-   conexões;
-   dúvidas abertas;
-   problemas/soluções;
-   histórico.

Não priorizar visualização sofisticada antes de o grafo possuir
utilidade real.

## Fase 6 --- Reflexão local

Começar a responder, quando possível:

``` text
O que eu já registrei sobre X?
Quais dúvidas estão abertas?
Quais problemas ainda não têm solução?
O que venho estudando recentemente?
```

## Fase 7 --- IA opcional

Adicionar:

``` text
Analisar com IA
```

para:

-   síntese;
-   evolução;
-   interpretação;
-   possíveis lacunas;
-   recomendações;
-   próximos assuntos.

## Fase 8 --- Complemento externo

Permitir que a IA compare o histórico pessoal com conhecimento geral,
deixando clara a origem de cada conclusão.

------------------------------------------------------------------------

# 57. Critérios de eficiência

A arquitetura deve preservar:

## Captura

``` text
rápida
não bloqueante
sem classificação obrigatória
```

## Busca

``` text
offline
local
indexada
```

## Relações

``` text
incrementais
Top N candidatos
não comparar tudo com tudo
```

## IA

``` text
opcional
somente quando agrega valor
contexto recuperado localmente
não enviar o Cérebro inteiro
```

## Grafo

``` text
esparso
explicável
reprocessável
```

------------------------------------------------------------------------

# 58. Critério de sucesso do Cérebro

O objetivo não é apenas conseguir salvar muitas anotações.

Depois de meses de uso, o EVRYLUX deve ser capaz de ajudar o usuário a
responder perguntas pessoais que uma busca comum na internet não
consegue responder:

``` text
O que eu já sei?

Onde tenho evidências de dúvida?

O que ficou sem resolução?

Como meu conhecimento evoluiu?

Que coisas que registrei estão conectadas?

O que comecei e deixei de continuar?

Qual tem sido meu foco recente?

Que próximos assuntos fazem sentido considerando
minha trajetória registrada?
```

Se essas respostas forem úteis e fundamentadas em evidências, o Cérebro
estará cumprindo sua proposta.

------------------------------------------------------------------------

# 59. Princípios finais consolidados

## 1. O usuário registra; o EVRYLUX organiza

Nenhuma taxonomia obrigatória antes de salvar.

## 2. O original é permanente; a organização é derivada

Classificações, conceitos e relações podem ser reconstruídos.

## 3. Offline primeiro

Salvar, pesquisar, recuperar e navegar não dependem de IA.

## 4. IA é amplificação, não fundação

Ela interpreta e recomenda quando o usuário desejar.

## 5. Ausência de evidência não é evidência de desconhecimento

O EVRYLUX não afirma que o usuário não sabe algo apenas porque não
encontrou registros.

## 6. Relações precisam ser úteis

Não conectar registros somente porque compartilham palavras genéricas.

## 7. O grafo existe para responder perguntas

Não para ser apenas uma visualização bonita.

## 8. Evidências sempre disponíveis

Conclusões importantes devem apontar para os registros que as sustentam.

## 9. Inteligência incremental

Cada novo registro pode enriquecer o mapa existente sem reprocessar
tudo.

## 10. O produto conhece a trajetória, não apenas o conteúdo

A principal vantagem do EVRYLUX é preservar e tornar consultável a
evolução do conhecimento pessoal.

------------------------------------------------------------------------

# 60. Frase-guia atualizada

> **Você registra. O EVRYLUX organiza e conecta seu conhecimento
> localmente. Quando quiser ir além, a IA ajuda a entender o que você já
> sabe, encontrar possíveis lacunas e decidir o que explorar a seguir.**

Versão curta:

> **Seu conhecimento continua seu. A inteligência cresce com ele.**
