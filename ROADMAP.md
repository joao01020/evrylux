# Roadmap

## Objetivo

Este roadmap comunica a direção, as prioridades e as principais áreas de

evolução do projeto.

Ele não representa uma promessa rígida de datas ou entregas.

As prioridades podem mudar conforme:

- feedback;

- segurança;

- estabilidade;

- necessidade dos usuários;

- limitações técnicas;

- dependências entre funcionalidades;

- descobertas durante desenvolvimento e testes;

- custo operacional;

- sustentabilidade financeira do produto;

- evolução da infraestrutura;

- aprendizado obtido com uso real.

---

## Como interpretar este roadmap

As tarefas estão organizadas em três horizontes:

### Agora

Itens prioritários ou em desenvolvimento no ciclo atual.

### Próximo

Itens planejados para serem trabalhados após as prioridades atuais.

### Depois

Itens importantes, mas que ainda não fazem parte do foco imediato.

Os itens podem mudar de posição conforme a evolução do projeto.

---

## Status

Utilizamos:

```text
[ ] Planejado

[x] Concluído
```

Quando necessário, uma issue ou Pull Request pode ser vinculada ao item

correspondente.

Exemplo:

```text
- [ ] Implementar notificações de tarefas — #123
```

---

# Agora

## Qualidade e colaboração

- [x] Padronizar Pull Requests.

- [ ] Proteger a branch `main`.

- [x] Adicionar CI inicial.

- [x] Configurar Dependabot.

- [x] Documentar arquitetura.

- [x] Criar documentação de contribuição.

- [x] Criar política de segurança.

- [x] Criar templates de issues.

- [x] Criar CODEOWNERS.

- [x] Consolidar o ambiente de desenvolvimento.

- [x] Revisar secrets e `.gitignore`.

- [x] Criar e revisar `.env.example`.

## Estabilidade

- [x] Reduzir erros de carregamento.

- [x] Melhorar tempos de inicialização.

- [x] Revisar estados de loading.

- [x] Melhorar mensagens de erro.

- [ ] Aumentar cobertura de testes críticos.

- [x] Identificar operações lentas.

- [x] Reduzir trabalho desnecessário durante inicialização.

## Dados

- [ ] Revisar arquitetura de sync offline-first.

- [ ] Validar fluxo de tombstones.

- [ ] Documentar estratégia de conflitos.

- [ ] Revisar políticas RLS.

- [ ] Revisar migrations existentes.

- [ ] Definir política para migrations futuras.

- [ ] Validar comportamento após perda e recuperação de conexão.

## IA — camada inicial em validação

- [x] Integrar assistente de IA ao Cérebro.

- [x] Conectar Flutter, Supabase Edge Function e Groq.

- [x] Criar consultas inteligentes baseadas no conhecimento local.

- [x] Criar resposta animada com resumo e próximos caminhos.

- [x] Adicionar ajuda de uso e instrução de ativação com Enter.

- [ ] Validar comportamento com diferentes volumes e tipos de conhecimento.

- [ ] Revisar segurança da função antes de uso público.

- [ ] Medir custo e latência reais.

## Segurança

- [x] Revisar exposição de secrets.

- [ ] Revisar permissões e RLS.

- [ ] Validar isolamento entre usuários.

- [ ] Revisar armazenamento local de informações sensíveis.

- [ ] Revisar logs para impedir exposição de dados sensíveis.

---

# Próximo

## Cérebro

- [x] Melhorar fluxo de criação de conhecimento.

- [x] Melhorar pesquisa.

- [x] Revisar destaque dos resultados.

- [x] Otimizar carregamento.

- [ ] Evoluir mapa de conhecimento.

- [ ] Melhorar revisão de conceitos e perguntas.

- [x] Melhorar estados vazios e feedback visual.

- [ ] Revisar comportamento offline.

- [x] Reduzir operações desnecessárias durante carregamento.

---

## IA no Cérebro

A IA funciona como uma camada de análise e apoio ao estudo sobre o conhecimento
já

registrado pelo usuário.

O objetivo não é substituir o conhecimento original nem transformar o Cérebro em

um chatbot genérico.

A camada inicial de IA já está integrada ao fluxo de pesquisa do Cérebro.

### Estado atual da implementação

- [x] Integrar IA real ao Cérebro.

- [x] Criar detector de intenção para diferenciar busca local de consulta
      inteligente.

- [x] Manter pesquisas simples locais, sem chamada de IA.

- [x] Acionar a IA somente após confirmação explícita com Enter.

- [x] Criar recuperação local antes da chamada de IA.

- [x] Enviar somente conhecimentos relevantes para o backend.

- [x] Limitar o contexto a até 8 conhecimentos por consulta.

- [x] Limitar resumos enviados à IA a aproximadamente 240 caracteres por item.

- [x] Não usar todas as notas como fallback quando nenhuma correspondência for
      encontrada.

- [x] Deduplicar conhecimentos antes do envio.

- [x] Integrar Flutter → Supabase Edge Function → Groq.

- [x] Manter `GROQ_API_KEY` somente no backend.

- [x] Utilizar `openai/gpt-oss-20b` como modelo inicial.

- [x] Utilizar resposta estruturada em JSON.

- [x] Utilizar `reasoning_effort: low` para reduzir custo e latência.

- [x] Limitar a resposta do modelo para manter custo previsível.

- [x] Limitar sugestões exibidas pela IA.

- [x] Considerar múltiplas notas relevantes na síntese quando disponíveis.

- [x] Evitar afirmar que o usuário sabe algo que não esteja sustentado pelo
      contexto recuperado.

- [x] Diferenciar conhecimento existente de novos caminhos sugeridos.

- [x] Criar resposta visual com animação de escrita no Flutter.

- [x] Exibir estado de carregamento enquanto a IA analisa o Cérebro.

- [x] Criar seção de ajuda com exemplos de consultas de IA.

- [x] Informar na interface que é necessário pressionar Enter para ativar a IA.

- [ ] Medir latência média das consultas em uso real.

- [ ] Medir custo médio por consulta e por usuário.

- [ ] Criar limites de uso de IA por plano.

- [ ] Criar testes automatizados para o fluxo completo da IA.

- [ ] Revisar autenticação e autorização da Edge Function para produção.

### Consultas inteligentes já suportadas

A camada inicial reconhece consultas como:

```text
o que eu já aprendi sobre ...
o que eu sei sobre ...
o que falta eu aprender sobre ...
o que eu deveria revisar sobre ...
quais conhecimentos estão relacionados a ...
quais perguntas eu ainda tenho sobre ...
```

Fluxo atual:

```text
Usuário escreve
      ↓
Busca local identifica conhecimento relevante
      ↓
Usuário pressiona Enter
      ↓
Detector de intenção decide se a IA deve ser acionada
      ↓
Contexto compacto é montado
      ↓
Supabase Edge Function
      ↓
Groq
      ↓
Resposta estruturada
      ↓
EVRYLUX apresenta resumo + próximos caminhos
```

### Princípios

- [x] A IA não deve substituir automaticamente o conteúdo original do usuário.

- [x] A IA nunca recebe o conhecimento total; recebe somente uma representação

      compacta dos conhecimentos relevantes recuperados localmente.

- [x] O conteúdo original continua sendo a fonte principal.

- [x] A IA deve organizar, relacionar e resumir quando solicitado.

- [x] Sugestões da IA devem ser claramente identificadas como sugestões.

- [x] O usuário deve continuar no controle sobre o que é salvo.

- [x] A IA não deve modificar conhecimento permanentemente sem ação explícita do

      usuário.

- [ ] Processamentos devem passar por revisão adicional de privacidade,
      segurança,

      autenticação e limites antes do lançamento público.

---

### Organização automática

- [ ] Identificar temas presentes nos conceitos existentes.

- [ ] Agrupar conhecimentos relacionados.

- [ ] Sugerir áreas automaticamente.

- [ ] Detectar conceitos semelhantes.

- [ ] Detectar possíveis duplicações.

- [ ] Criar relações entre conceitos.

- [ ] Criar ramificações no mapa de conhecimento.

- [ ] Sugerir conexões entre conhecimentos que o usuário estudou em momentos

      diferentes.

Exemplo:

```text
Usuário adiciona:

"JWT"

"Refresh token"

"Session"

"Supabase Auth"

"RLS"

              ↓

IA identifica relações

              ↓

Autenticação

├── JWT

├── Refresh token

├── Session

├── Supabase Auth

└── RLS
```

O usuário não precisa classificar manualmente cada conhecimento.

---

## IA para sugestões de estudo

A IA deve analisar o conteúdo já armazenado e identificar pontos que podem ser

aprofundados.

Exemplo:

```text
Você estudou:

ESP32

├── GPIO

├── SPI

├── Wi-Fi

└── BLE

Possíveis próximos assuntos:

→ interrupções

→ FreeRTOS

→ gerenciamento de energia

→ I2C

→ comunicação UART
```

Funcionalidades planejadas:

- [x] Identificar lacunas de conhecimento em consultas direcionadas.

- [x] Sugerir assuntos relacionados com base no contexto recuperado.

- [ ] Sugerir pré-requisitos que podem estar faltando.

- [x] Sugerir conceitos mais avançados como próximos caminhos.

- [ ] Identificar áreas pouco exploradas.

- [x] Mostrar possíveis caminhos de estudo.

- [ ] Permitir transformar uma sugestão em pergunta.

- [ ] Permitir transformar uma sugestão em item para estudar depois.

- [ ] Permitir ignorar sugestões permanentemente quando o usuário não tiver

      interesse.

---

## IA e mapa de conhecimento

O mapa do conhecimento deve evoluir para representar relações reais entre

conteúdos.

Exemplo:

```text
Programação

│

├── C++

│   ├── Ponteiros

│   ├── Memória

│   └── Classes

│

├── Flutter

│   ├── Dart

│   ├── State Management

│   └── Widgets

│

└── Embedded

    ├── ESP32

    ├── FreeRTOS

    └── Protocolos
```

A IA poderá:

- [ ] sugerir relações;

- [ ] sugerir agrupamentos;

- [ ] detectar ramificações;

- [ ] reorganizar visualmente o mapa;

- [ ] destacar áreas fortes;

- [ ] destacar áreas pouco estudadas;

- [ ] sugerir conexões entre áreas diferentes.

---

## IA e revisão

A IA poderá auxiliar na revisão do conhecimento.

Planejado:

- [ ] sugerir perguntas com base nos conceitos salvos;

- [ ] gerar perguntas de revisão;

- [ ] identificar conhecimentos que não são revisados há muito tempo;

- [x] sugerir revisões relacionadas por meio de consultas inteligentes;

- [ ] identificar respostas superficiais;

- [x] sugerir assuntos que merecem aprofundamento como próximos caminhos.

A IA deve auxiliar o processo, não substituir o esforço de lembrar e responder.

---

## IA e controle do usuário

Toda funcionalidade de IA deve respeitar este princípio:

```text
IA sugere

     ↓

Usuário decide

     ↓

Cérebro registra
```

Evitar:

```text
IA decide

     ↓

Cérebro altera automaticamente
```

Alterações permanentes importantes devem exigir ação explícita do usuário.

---

## Colaboração

- [ ] Implementar atribuição de tarefas.

- [ ] Criar notificações de tarefas.

- [ ] Exibir tarefas atribuídas no dashboard.

- [ ] Criar acesso rápido para tarefas recebidas.

- [ ] Adicionar estado de leitura das notificações.

- [ ] Criar histórico de atividade quando necessário.

- [ ] Avaliar permissões entre colaboradores.

- [ ] Melhorar experiência de revisão e acompanhamento de tarefas.

---

## Segurança

- [ ] Revisar fluxo E2EE.

- [ ] Revisar envelopes de chave.

- [ ] Adicionar testes de autorização.

- [ ] Adicionar testes de isolamento entre usuários.

- [ ] Validar comportamento com sessão expirada.

- [ ] Revisar recuperação e rotação de chaves.

- [ ] Melhorar resposta a incidentes.

- [ ] Documentar procedimentos para secrets comprometidos.

---

## Testes

- [ ] Expandir testes unitários.

- [ ] Criar testes para repositories.

- [ ] Criar testes para controllers críticos.

- [ ] Criar testes de sync.

- [ ] Criar testes de regressão para bugs relevantes.

- [ ] Criar testes de RLS.

- [ ] Avaliar testes de integração.

---

# Monetização e planos

O produto deve possuir uma camada gratuita funcional e permitir expansão através

de planos pagos.

O modelo inicial será baseado principalmente em armazenamento disponível para o

Brain e recursos adicionais conforme o produto evoluir.

---

## Plano gratuito

O usuário poderá começar sem pagamento.

Planejado:

```text
Free

US$ 0
```

Inclui inicialmente:

- [ ] até 1 GB de armazenamento;

- [ ] criação de conceitos;

- [ ] criação de perguntas;

- [ ] pesquisa;

- [ ] mapa de conhecimento;

- [ ] funcionamento offline;

- [ ] sincronização dentro dos limites definidos;

- [ ] recursos básicos do Brain.

Objetivo:

Permitir que qualquer pessoa utilize o produto de forma real antes de precisar

pagar.

---

## Plano de US$ 9

Plano intermediário para usuários que precisam de mais capacidade.

Preço inicial planejado:

```text
US$ 9 / mês
```

A capacidade exata deverá ser definida após análise de:

- custo de armazenamento;

- custo de banco;

- custo de tráfego;

- custo de IA;

- quantidade média de dados por usuário;

- margem necessária para operação.

Possíveis benefícios:

- [ ] armazenamento maior que o plano gratuito;

- [ ] maior quantidade de arquivos;

- [ ] recursos adicionais de IA;

- [ ] maior capacidade de processamento;

- [ ] histórico ampliado;

- [ ] recursos avançados de organização;

- [ ] prioridade em determinadas operações quando necessário.

---

## Plano de US$ 29

Plano avançado para usuários com maior volume de conhecimento e utilização.

Preço inicial planejado:

```text
US$ 29 / mês
```

Possíveis benefícios:

- [ ] armazenamento significativamente maior;

- [ ] limites maiores para IA;

- [ ] análise avançada do Cérebro;

- [ ] organização de grandes volumes de conhecimento;

- [ ] recursos avançados do mapa;

- [ ] mais processamento;

- [ ] recursos profissionais ou de colaboração;

- [ ] maior capacidade de arquivos e anexos.

---

## Estrutura inicial dos planos

Modelo conceitual:

```text
FREE

US$ 0

│

├── 1 GB

├── Brain básico

├── Pesquisa

├── Offline

└── Sync básico

PLUS

US$ 9/mês

│

├── Mais armazenamento

├── Mais recursos de IA

├── Organização avançada

└── Limites maiores

PRO

US$ 29/mês

│

├── Armazenamento avançado

├── IA avançada

├── Recursos profissionais

├── Colaboração

└── Limites maiores
```

Os nomes `PLUS` e `PRO` são provisórios e podem mudar.

---

## Armazenamento e limites

Antes de lançar os planos pagos, definir:

- [ ] o que conta como armazenamento;

- [ ] se conceitos em texto contam para a cota;

- [ ] como arquivos e anexos são contabilizados;

- [ ] como conteúdo criptografado é medido;

- [ ] limite de upload por arquivo;

- [ ] limite total por usuário;

- [ ] comportamento quando o limite for atingido;

- [ ] comportamento quando assinatura expirar;

- [ ] período de tolerância;

- [ ] política de exclusão por falta de pagamento;

- [ ] política de exportação antes da exclusão.

---

## Comportamento ao atingir o limite

O usuário não deve perder dados imediatamente ao atingir o limite.

Fluxo planejado:

```text
Usuário aproxima-se do limite

        ↓

Aviso dentro do aplicativo

        ↓

Usuário atinge limite

        ↓

Dados existentes continuam acessíveis

        ↓

Novos uploads/criações que aumentem armazenamento podem ser limitados

        ↓

Opção de upgrade
```

Nunca excluir conteúdo silenciosamente apenas porque o limite foi atingido.

---

## Downgrade

Se um usuário possuir mais dados do que o plano inferior permite:

```text
Plano pago

   ↓

downgrade

   ↓

uso atual > novo limite
```

o produto deve definir uma política clara.

Possível comportamento:

- manter dados existentes;

- bloquear novos uploads;

- permitir leitura;

- permitir exportação;

- solicitar redução de armazenamento;

- oferecer período de tolerância.

Dados não devem ser removidos imediatamente sem aviso adequado.

---

## Assinaturas

Antes do lançamento comercial:

- [ ] escolher provedor de pagamento;

- [ ] definir cobrança mensal;

- [ ] avaliar cobrança anual;

- [ ] implementar status da assinatura;

- [ ] implementar upgrade;

- [ ] implementar downgrade;

- [ ] implementar cancelamento;

- [ ] implementar renovação;

- [ ] implementar falha de pagamento;

- [ ] implementar período de tolerância;

- [ ] proteger webhooks;

- [ ] impedir manipulação do plano pelo cliente.

O backend deve ser a fonte confiável para saber qual plano o usuário possui.

---

## Segurança de pagamentos

O aplicativo não deve armazenar diretamente dados completos de cartão.

Utilizar provedor especializado.

O backend deve validar:

```text
Pagamento

   ↓

Webhook

   ↓

Validação

   ↓

Atualização da assinatura

   ↓

Plano liberado
```

Nunca confiar apenas em um valor enviado pelo cliente como:

```text
plan = "pro"
```

---

## Medição de uso

Será necessário acompanhar:

- armazenamento utilizado;

- armazenamento máximo;

- quantidade de arquivos;

- uso de IA;

- operações relevantes para custos;

- status da assinatura.

Exemplo de UI:

```text
Armazenamento

742 MB de 1 GB utilizados

███████████████░░░░░

72%
```

---

## Custos de IA

Recursos de IA podem possuir custo diferente do armazenamento.

Antes de definir limites finais:

- [ ] medir custo médio por usuário;

- [ ] medir número de chamadas;

- [ ] medir tamanho médio de contexto;

- [x] evitar processar todo o Cérebro a cada ação;

- [ ] utilizar cache quando apropriado;

- [ ] processar incrementalmente;

- [ ] definir limites justos por plano.

Implementação atual para controle de custo:

- [x] limitar contexto a até 8 conhecimentos relevantes;

- [x] limitar resumo de cada conhecimento;

- [x] não chamar IA durante digitação;

- [x] chamar IA somente após Enter em consultas inteligentes;

- [x] utilizar modelo leve com `reasoning_effort: low`;

- [x] limitar tamanho máximo da resposta;

- [x] limitar quantidade de sugestões;

- [x] evitar envio do Cérebro inteiro.

---

## Processamento incremental de IA

A IA não deve precisar reler todo o Cérebro a cada novo conceito.

Fluxo desejado:

```text
Novo conhecimento

      ↓

Processar somente alteração relevante

      ↓

Atualizar relações

      ↓

Atualizar índices

      ↓

Atualizar sugestões
```

Isso reduz:

- custo;

- latência;

- tráfego;

- processamento.

---

## Transparência de limites

O usuário deve conseguir visualizar claramente:

- plano atual;

- armazenamento usado;

- armazenamento disponível;

- limites de IA;

- próxima cobrança;

- status da assinatura.

Evitar limites ocultos.

---

# Depois

## Releases e distribuição

- [ ] Automatizar releases.

- [ ] Padronizar versionamento.

- [ ] Automatizar geração de artefatos.

- [ ] Melhorar processo de changelog.

- [ ] Avaliar assinatura de builds.

- [ ] Criar processo de rollback.

---

## Observabilidade

- [ ] Implementar logging estruturado.

- [ ] Avaliar telemetria técnica com privacidade.

- [ ] Criar monitoramento de erros.

- [ ] Melhorar diagnóstico de falhas de sync.

- [ ] Criar métricas técnicas essenciais.

---

## Dados e infraestrutura

- [ ] Criar estratégia formal de backup.

- [ ] Documentar processo de restauração.

- [ ] Avaliar ambiente de staging.

- [ ] Melhorar automação de migrations.

- [ ] Criar verificações adicionais de integridade de dados.

- [ ] Criar medição de armazenamento por usuário.

- [ ] Criar sistema de quotas.

- [ ] Criar alertas de aproximação do limite.

- [ ] Criar infraestrutura preparada para planos pagos.

---

## Plataforma

- [ ] Melhorar suporte a Linux.

- [ ] Melhorar suporte a macOS.

- [ ] Melhorar suporte a Windows.

- [ ] Avaliar suporte adicional a mobile e web conforme necessidade.

- [ ] Documentar diferenças entre plataformas.

---

## Documentação

- [ ] Criar documentação pública.

- [ ] Simplificar onboarding.

- [ ] Criar diagramas de arquitetura.

- [ ] Documentar fluxos críticos.

- [ ] Expandir ADRs conforme novas decisões arquiteturais.

- [x] Documentar arquitetura inicial de IA.

- [ ] Documentar arquitetura de billing.

- [ ] Documentar política de quotas e armazenamento.

---

## Inteligência avançada

Após estabilização da camada inicial de IA:

- [ ] identificar padrões de aprendizado;

- [ ] criar visualização de evolução;

- [ ] mostrar assuntos mais estudados;

- [ ] mostrar assuntos esquecidos;

- [ ] sugerir revisão baseada em histórico;

- [ ] relacionar conceitos distantes;

- [ ] criar caminhos personalizados de estudo;

- [ ] sugerir perguntas ainda não respondidas;

- [ ] criar visão de lacunas de conhecimento.

---

## Colaboração avançada

- [ ] compartilhamento controlado de conhecimento;

- [ ] Brain compartilhado quando fizer sentido;

- [ ] permissões por área;

- [ ] histórico de alterações;

- [ ] comentários;

- [ ] colaboração em conceitos;

- [ ] espaços de equipe;

- [ ] planos voltados para equipes no futuro.

---

# Princípios da IA

A evolução da IA deve respeitar os seguintes princípios:

1. conhecimento do usuário continua sendo a fonte principal;

2. IA organiza antes de criar;

3. IA sugere antes de decidir;

4. alterações permanentes importantes exigem confirmação;

5. IA deve explicar de onde surgiu uma sugestão quando possível;

6. processamento deve respeitar privacidade;

7. custos de IA devem ser controlados;

8. funcionalidades devem continuar úteis mesmo sem IA sempre que possível.

---

# Princípios de monetização

O modelo de assinatura deve seguir alguns princípios:

1. o plano gratuito deve ser realmente utilizável;

2. dados do usuário não devem ser usados como mecanismo de pressão;

3. atingir limite não deve provocar exclusão imediata;

4. limites devem ser transparentes;

5. upgrade e downgrade devem ser simples;

6. cancelamento deve ser possível;

7. plano pago deve oferecer valor real;

8. preço e limites podem mudar conforme custos reais forem conhecidos.

---

# Critérios de priorização

Uma tarefa tende a subir de prioridade quando:

1. afeta segurança;

2. pode causar perda ou corrupção de dados;

3. bloqueia o uso de uma funcionalidade importante;

4. afeta muitos usuários;

5. causa regressões recorrentes;

6. prejudica estabilidade ou performance;

7. reduz significativamente a produtividade da equipe;

8. bloqueia outras tarefas;

9. habilita várias funcionalidades futuras;

10. reduz custo operacional significativo;

11. é necessária para monetização sustentável;

12. melhora diretamente a experiência principal do Cérebro.

Prioridade não deve ser definida apenas pelo tamanho ou visibilidade da

funcionalidade.

---

# Itens críticos

Problemas relacionados a estas áreas devem receber atenção especial:

- segurança;

- perda de dados;

- corrupção de banco;

- autenticação;

- autorização;

- RLS;

- criptografia;

- sync;

- migrations;

- billing;

- quotas;

- indisponibilidade do aplicativo.

Esses itens podem interromper temporariamente outras prioridades do roadmap.

---

# Fora de escopo imediato

Ideias podem ser registradas sem compromisso de implementação.

Estar registrado neste roadmap não significa que um recurso será necessariamente

desenvolvido.

Evite aumentar o escopo antes de estabilizar funcionalidades principais.

Funcionalidades experimentais devem ser avaliadas conforme:

- valor para o produto;

- complexidade;

- manutenção futura;

- impacto em segurança;

- impacto em arquitetura;

- custo de suporte;

- custo de infraestrutura;

- custo de IA.

---

# Como propor mudanças

Abra uma Feature Request descrevendo:

- problema;

- contexto;

- solução proposta;

- impacto;

- critérios de aceite;

- riscos ou dependências conhecidas.

Mudanças grandes devem ser discutidas antes da implementação.

Quando a proposta envolver uma decisão arquitetural relevante, considere também

criar um ADR em:

```text
docs/adr/
```

Possíveis ADRs futuros:

```text
0004-ai-organization.md

0005-storage-quotas.md

0006-subscription-billing.md
```

---

# Relação com Issues e Pull Requests

O roadmap apresenta direção e prioridades.

As issues representam unidades de trabalho concretas.

Os Pull Requests representam mudanças implementadas.

Fluxo esperado:

```text
Roadmap

   ↓

Feature / objetivo

   ↓

Issue

   ↓

Branch

   ↓

Pull Request

   ↓

Review + CI

   ↓

Merge

   ↓

Roadmap atualizado
```

Quando uma tarefa importante for concluída, atualize este arquivo para refletir

o novo estado.

---

# Manutenção do roadmap

O roadmap deve ser revisado periodicamente.

Ao revisar:

1. marque itens concluídos;

2. remova itens que perderam relevância;

3. mova prioridades quando necessário;

4. associe issues importantes;

5. evite manter tarefas concluídas como pendentes;

6. adicione novas prioridades com contexto suficiente;

7. revise limites e planos conforme custos reais;

8. revise decisões de IA conforme comportamento real dos usuários.

O roadmap deve representar o estado e a direção reais do projeto, não apenas uma

lista histórica de ideias.
