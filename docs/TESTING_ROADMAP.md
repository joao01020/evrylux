# Testing Roadmap

## Objetivo

Este roadmap organiza as principais áreas que precisam ser testadas antes que o
projeto seja considerado estável para uso real e produção.

Ele complementa:

```text
docs/TESTING.md
```

Enquanto `TESTING.md` define **como testar**, este arquivo registra **o que
ainda precisa ser testado**.

As prioridades podem mudar conforme:

- bugs encontrados;
- mudanças de arquitetura;
- novas funcionalidades;
- risco de perda de dados;
- segurança;
- comportamento em diferentes plataformas;
- evolução do sync;
- integração com IA;
- implementação de planos pagos.

---

## Como interpretar este roadmap

Os testes estão divididos em três níveis:

### Agora

Fluxos críticos que devem ser validados primeiro.

### Próximo

Fluxos importantes que devem ser cobertos depois da base crítica.

### Depois

Testes avançados, escala, carga, resiliência e cenários de produção.

---

## Status

Utilizamos:

```text
[ ] Não testado
[~] Testado parcialmente
[x] Validado
```

Quando um bug for encontrado, ele deve gerar uma issue e, quando possível, um
teste de regressão.

---

# Agora

## Inicialização do aplicativo

- [ ] Abrir aplicativo após instalação limpa.
- [ ] Abrir aplicativo com banco local já existente.
- [ ] Abrir aplicativo sem internet.
- [ ] Abrir aplicativo após atualização de versão.
- [ ] Abrir aplicativo com `.env` válido.
- [ ] Validar erro controlado quando configuração obrigatória estiver ausente.
- [ ] Medir tempo de inicialização.
- [ ] Verificar se operações pesadas bloqueiam a UI.
- [ ] Verificar se nenhum loading fica infinito.
- [ ] Validar recuperação após fechamento inesperado.

---

## Autenticação

- [ ] Login com credenciais válidas.
- [ ] Login com senha inválida.
- [ ] Login com usuário inexistente.
- [ ] Logout.
- [ ] Sessão restaurada após reiniciar o aplicativo.
- [ ] Sessão expirada.
- [ ] Token inválido.
- [ ] Refresh token inválido.
- [ ] Usuário removido do backend.
- [ ] Aplicativo offline com sessão previamente válida.
- [ ] Troca entre contas.
- [ ] Garantir que dados da conta anterior não apareçam na próxima conta.

---

## Isolamento entre usuários

Criar pelo menos dois usuários de teste:

```text
Usuário A
Usuário B
```

Validar:

- [ ] usuário A vê apenas seus dados privados;
- [ ] usuário B não lê dados do usuário A;
- [ ] usuário B não altera dados do usuário A;
- [ ] usuário B não exclui dados do usuário A;
- [ ] IDs manipulados manualmente não permitem acesso;
- [ ] filtros no Flutter não são a única proteção;
- [ ] RLS bloqueia acesso diretamente pelo backend.

---

## RLS

Para cada tabela privada relevante:

- [ ] testar `SELECT`;
- [ ] testar `INSERT`;
- [ ] testar `UPDATE`;
- [ ] testar `DELETE`;
- [ ] testar usuário autenticado correto;
- [ ] testar outro usuário autenticado;
- [ ] testar usuário anônimo;
- [ ] testar registros sem ownership válido;
- [ ] testar alteração manual de `user_id`.

---

## Criação de conhecimento

### Conceitos

- [ ] Criar conceito com título e conteúdo válidos.
- [ ] Criar conceito com campos opcionais.
- [ ] Criar conceito sem detalhes opcionais.
- [ ] Validar campos obrigatórios.
- [ ] Cancelar criação.
- [ ] Salvar múltiplos conceitos em sequência.
- [ ] Minimizar processo de salvamento.
- [ ] Continuar usando o aplicativo enquanto salva.
- [ ] Validar feedback de progresso.
- [ ] Validar ausência de duplicação.

### Perguntas

- [ ] Criar pergunta.
- [ ] Revisar pergunta.
- [ ] Editar pergunta.
- [ ] Excluir pergunta.
- [ ] Validar persistência.
- [ ] Validar comportamento offline.

---

## Edição de conhecimento

- [ ] Editar título.
- [ ] Editar conteúdo.
- [ ] Adicionar detalhe opcional.
- [ ] Remover detalhe opcional.
- [ ] Editar offline.
- [ ] Editar e fechar aplicativo antes do sync.
- [ ] Editar o mesmo conteúdo em dois dispositivos.
- [ ] Verificar conflito.
- [ ] Verificar timestamps e versionamento.

---

## Exclusão

- [ ] Excluir conceito.
- [ ] Excluir pergunta.
- [ ] Excluir offline.
- [ ] Reiniciar aplicativo antes do sync.
- [ ] Recuperar internet e sincronizar exclusão.
- [ ] Verificar tombstone.
- [ ] Verificar se registro não reaparece.
- [ ] Verificar se outro dispositivo recebe exclusão.
- [ ] Verificar exclusão repetida.
- [ ] Verificar exclusão de item já removido remotamente.

---

## Tombstones

- [ ] Tombstone criado corretamente.
- [ ] Tombstone sincroniza.
- [ ] Tombstone não mantém conteúdo sensível desnecessário.
- [ ] Tombstone não é apagado cedo demais.
- [ ] Tombstone evita ressurreição do registro.
- [ ] Cleanup futuro de tombstones funciona com segurança.
- [ ] Dois dispositivos processam o mesmo tombstone sem erro.

---

## Pesquisa

- [ ] Pesquisar título exato.
- [ ] Pesquisar parte do título.
- [ ] Pesquisar conteúdo.
- [ ] Pesquisar com maiúsculas/minúsculas.
- [ ] Pesquisar com acentos.
- [ ] Pesquisar termo inexistente.
- [ ] Limpar busca.
- [ ] Confirmar busca antes de mostrar resultados, conforme comportamento
      definido.
- [ ] Validar destaque dos resultados.
- [ ] Validar resultados sem destaque incorreto.
- [ ] Pesquisar com muitos registros.
- [ ] Medir latência da pesquisa.

---

## Dashboard

- [ ] Carregar contadores corretamente.
- [ ] Conceitos exibem quantidade correta.
- [ ] Perguntas exibem quantidade correta.
- [ ] Dados não aparecem duplicados.
- [ ] Loading não bloqueia desnecessariamente.
- [ ] Estado vazio funciona.
- [ ] Dados são atualizados após criação.
- [ ] Dados são atualizados após exclusão.
- [ ] Dados são atualizados após sync.

---

## Persistência local

- [ ] Criar conteúdo.
- [ ] Fechar aplicativo.
- [ ] Abrir novamente.
- [ ] Confirmar persistência.
- [ ] Reiniciar máquina.
- [ ] Confirmar persistência.
- [ ] Simular erro durante escrita.
- [ ] Validar integridade do banco.
- [ ] Validar migration local.
- [ ] Validar dados antigos após atualização.

---

## Offline-first

Fluxo mínimo:

```text
Online
  ↓
carregar dados
  ↓
ficar offline
  ↓
criar
  ↓
editar
  ↓
excluir
  ↓
fechar app
  ↓
abrir ainda offline
  ↓
recuperar internet
  ↓
sincronizar
```

Validar:

- [ ] nenhuma mudança local é perdida;
- [ ] UI continua funcional;
- [ ] operações pendentes são preservadas;
- [ ] sync acontece posteriormente;
- [ ] não existem duplicações;
- [ ] exclusões permanecem excluídas;
- [ ] estado final é consistente.

---

## Sync

- [ ] Sync manual.
- [ ] Sync automático.
- [ ] Sync com conexão normal.
- [ ] Sync após longo período offline.
- [ ] Sync com conexão interrompida no meio.
- [ ] Retry.
- [ ] Retry múltiplo.
- [ ] Mesma operação enviada duas vezes.
- [ ] Operação local já existente remotamente.
- [ ] Operação remota já aplicada localmente.
- [ ] Dois dispositivos sincronizando simultaneamente.
- [ ] Sync de grande quantidade de registros.
- [ ] Sync não bloqueia a interface.

---

## Conflitos

- [ ] Mesmo registro editado em dois dispositivos.
- [ ] Registro editado em um dispositivo e excluído em outro.
- [ ] Registro criado offline em dois dispositivos.
- [ ] Timestamps iguais ou muito próximos.
- [ ] Relógio de dispositivo incorreto.
- [ ] Política de conflito produz resultado previsível.
- [ ] Nenhum dado é perdido silenciosamente.

---

## Segurança local

- [ ] `.env` não entra no Git.
- [ ] Tokens não aparecem em logs.
- [ ] Senhas não aparecem em logs.
- [ ] Chaves privadas não aparecem em logs.
- [ ] Banco local não contém plaintext indevido.
- [ ] Arquivos temporários não expõem conteúdo sensível.
- [ ] Logout remove estado sensível necessário.
- [ ] Troca de usuário limpa contexto anterior.

---

## E2EE

- [ ] Encrypt → decrypt.
- [ ] Chave correta.
- [ ] Chave incorreta.
- [ ] Payload corrompido.
- [ ] Nonce/IV válido.
- [ ] Nonce diferente quando necessário.
- [ ] Formato versionado.
- [ ] Conteúdo remoto permanece ciphertext.
- [ ] Plaintext não é salvo indevidamente.
- [ ] Reinicialização preserva capacidade de decrypt.
- [ ] Novo dispositivo recebe envelopes corretamente.
- [ ] Dispositivo revogado perde acesso quando aplicável.

---

# Próximo

## IA — organização do Brain

A IA deve receber apenas contexto mínimo necessário.

Testar:

- [ ] Brain completo nunca é enviado por padrão.
- [ ] Retrieval seleciona apenas itens relevantes.
- [ ] JSON enviado contém apenas campos permitidos.
- [ ] Conteúdo completo só é enviado quando necessário.
- [ ] Quantidade máxima de itens por chamada é respeitada.
- [ ] Resumos compactos reduzem tokens.
- [ ] IA recebe IDs estáveis.
- [ ] Resposta retorna IDs válidos.
- [ ] IDs inexistentes são rejeitados.
- [ ] Sugestões não alteram conteúdo automaticamente.

---

## IA — retrieval seletivo

Fluxo:

```text
Brain local
   ↓
índice
   ↓
busca por relevância
   ↓
top N itens
   ↓
JSON compacto
   ↓
IA
```

Validar:

- [ ] consulta simples seleciona poucos conceitos;
- [ ] conceitos irrelevantes não são enviados;
- [ ] top N possui limite configurável;
- [ ] resultado continua bom com 100 conceitos;
- [ ] resultado continua bom com 1.000 conceitos;
- [ ] resultado continua bom com 10.000 conceitos;
- [ ] latência permanece aceitável;
- [ ] custo por chamada é registrado.

---

## IA — processamento incremental

- [ ] novo conceito não reprocessa todo o Brain;
- [ ] apenas candidatos relacionados são analisados;
- [ ] atualização de conceito reprocessa somente relações afetadas;
- [ ] exclusão remove relações antigas;
- [ ] processamento pode ser repetido sem duplicar relações;
- [ ] falha no processamento não afeta conteúdo original.

---

## IA — sugestões de estudo

- [ ] sugerir assuntos relacionados.
- [ ] sugerir pré-requisitos.
- [ ] sugerir aprofundamentos.
- [ ] não sugerir duplicados já estudados.
- [ ] permitir ignorar sugestão.
- [ ] permitir transformar sugestão em pergunta.
- [ ] permitir transformar sugestão em item futuro.
- [ ] sugestões não são salvas automaticamente.
- [ ] conteúdo original não é sobrescrito.

---

## IA — custo

Registrar por chamada:

```text
input tokens
output tokens
latência
tipo de operação
quantidade de conceitos enviados
```

Testar:

- [ ] chamadas pequenas.
- [ ] chamadas médias.
- [ ] limite máximo.
- [ ] fallback quando limite é excedido.
- [ ] cache.
- [ ] reuso de resultados.
- [ ] chamadas duplicadas evitadas.
- [ ] orçamento mensal simulado.

---

## IA — privacidade

- [ ] nenhum secret é enviado.
- [ ] nenhum token é enviado.
- [ ] conteúdo não relacionado não é enviado.
- [ ] metadados são minimizados.
- [ ] logs não armazenam prompts sensíveis completos sem necessidade.
- [ ] usuário sabe quando IA é utilizada.
- [ ] falha da IA não compromete acesso ao Brain.

---

## Mapa de conhecimento

- [ ] criar relação entre conceitos.
- [ ] remover relação.
- [ ] atualizar relação.
- [ ] relação duplicada não é criada.
- [ ] mapa com 100 nós.
- [ ] mapa com 1.000 nós.
- [ ] zoom.
- [ ] pan.
- [ ] seleção de nó.
- [ ] pesquisa no mapa.
- [ ] carregamento progressivo.
- [ ] performance aceitável.

---

## Notificações de tarefas

- [ ] atribuir tarefa ao usuário B.
- [ ] usuário B recebe notificação.
- [ ] notificação aparece no dashboard.
- [ ] link abre tarefa correta.
- [ ] notificação marcada como lida.
- [ ] não notificar usuário errado.
- [ ] tarefa concluída atualiza estado.
- [ ] múltiplas notificações não duplicam.
- [ ] offline → receber após reconectar.
- [ ] som respeita configuração futura.

---

## Colaboração

- [ ] usuário sem permissão não altera tarefa.
- [ ] usuário atribuído acessa tarefa permitida.
- [ ] usuário removido perde acesso.
- [ ] alteração simultânea por dois usuários.
- [ ] histórico registra mudanças relevantes.
- [ ] auditoria não expõe dados sensíveis.

---

## Migrations

Para cada migration importante:

- [ ] aplicar em banco limpo.
- [ ] aplicar em banco com dados.
- [ ] validar schema.
- [ ] validar índices.
- [ ] validar constraints.
- [ ] validar RLS.
- [ ] validar aplicação antiga quando aplicável.
- [ ] validar aplicação nova.
- [ ] testar falha parcial quando possível.
- [ ] verificar estratégia de correção.

---

## Atualização do aplicativo

- [ ] atualizar de versão anterior.
- [ ] manter dados locais.
- [ ] executar migration local.
- [ ] manter sessão.
- [ ] sync após atualização.
- [ ] rollback quando suportado.
- [ ] versão incompatível mostra erro adequado.

---

## Dependências

- [ ] Dependabot abre PR.
- [ ] CI executa no PR.
- [ ] atualização patch.
- [ ] atualização minor.
- [ ] atualização major.
- [ ] plugin desktop continua funcionando.
- [ ] build Linux continua funcionando.
- [ ] build macOS continua funcionando quando suportado.
- [ ] build Windows continua funcionando quando suportado.

---

# Planos e monetização

## Plano gratuito

Validar limite inicial:

```text
1 GB
```

Testar:

- [ ] usuário novo começa no plano gratuito.
- [ ] limite exibido corretamente.
- [ ] armazenamento utilizado calculado corretamente.
- [ ] usuário pode usar até próximo do limite.
- [ ] aviso aparece antes de atingir o limite.
- [ ] atingir 1 GB não exclui dados.
- [ ] leitura continua funcionando após atingir limite.
- [ ] novas operações acima do limite são tratadas corretamente.

---

## Plano de US$ 9

- [ ] upgrade do gratuito.
- [ ] plano liberado após pagamento confirmado.
- [ ] limite atualizado.
- [ ] plano persiste entre sessões.
- [ ] cliente não consegue alterar plano localmente.
- [ ] webhook inválido é rejeitado.
- [ ] pagamento duplicado é idempotente.
- [ ] cancelamento funciona.
- [ ] renovação funciona.
- [ ] falha de pagamento entra no fluxo correto.

---

## Plano de US$ 29

- [ ] upgrade direto do gratuito.
- [ ] upgrade do plano de US$ 9.
- [ ] downgrade para US$ 9.
- [ ] downgrade para gratuito.
- [ ] limites são atualizados corretamente.
- [ ] recursos premium são ativados corretamente.
- [ ] recursos premium são removidos corretamente no downgrade.

---

## Quotas

- [ ] cálculo do uso é confiável.
- [ ] texto é contabilizado conforme política.
- [ ] arquivos são contabilizados.
- [ ] anexos são contabilizados.
- [ ] conteúdo criptografado é contabilizado corretamente.
- [ ] exclusão reduz uso.
- [ ] tombstone não gera cobrança indevida.
- [ ] sync duplicado não duplica quota.
- [ ] medição não pode ser manipulada pelo cliente.

---

## Downgrade

Cenário:

```text
Usuário possui 5 GB
↓
faz downgrade para plano de 1 GB
```

Validar:

- [ ] dados não são apagados imediatamente.
- [ ] leitura continua.
- [ ] usuário recebe aviso.
- [ ] novos uploads são limitados.
- [ ] exportação continua disponível.
- [ ] período de tolerância funciona quando implementado.

---

## Billing

- [ ] checkout.
- [ ] pagamento aprovado.
- [ ] pagamento recusado.
- [ ] pagamento pendente.
- [ ] webhook duplicado.
- [ ] webhook fora de ordem.
- [ ] assinatura cancelada.
- [ ] renovação.
- [ ] chargeback quando aplicável.
- [ ] plano não depende apenas de estado no cliente.

---

# Depois

## Performance

Testar com:

```text
100 conceitos
1.000 conceitos
10.000 conceitos
50.000 conceitos
```

Medir:

- [ ] inicialização;
- [ ] pesquisa;
- [ ] dashboard;
- [ ] criação;
- [ ] sync;
- [ ] mapa;
- [ ] uso de memória;
- [ ] uso de CPU;
- [ ] tamanho do banco.

---

## Stress de sync

- [ ] 1.000 operações pendentes.
- [ ] 10.000 operações pendentes.
- [ ] conexão lenta.
- [ ] conexão oscilando.
- [ ] timeout.
- [ ] backend temporariamente indisponível.
- [ ] app fechado durante sync.
- [ ] máquina desligada durante sync.
- [ ] retry após reinicialização.

---

## Banco grande

- [ ] banco local pequeno.
- [ ] banco médio.
- [ ] banco grande.
- [ ] índices utilizados.
- [ ] queries lentas identificadas.
- [ ] migrations continuam aceitáveis.
- [ ] backup e restauração.

---

## Corrupção e recuperação

- [ ] banco local corrompido.
- [ ] arquivo incompleto.
- [ ] migration interrompida.
- [ ] registro inválido.
- [ ] sync inconsistente.
- [ ] recuperação sem apagar tudo quando possível.
- [ ] mensagem clara quando recuperação automática não for possível.

---

## Backup

- [ ] backup criado.
- [ ] backup restaurado.
- [ ] backup criptografado quando necessário.
- [ ] restauração em máquina diferente.
- [ ] restauração com versão mais nova.
- [ ] dados completos após restauração.

---

## Build e plataformas

### Linux

- [ ] build debug.
- [ ] build release.
- [ ] instalação.
- [ ] execução.
- [ ] atualização.

### macOS

- [ ] build debug.
- [ ] build release.
- [ ] plugins desktop.
- [ ] permissões.
- [ ] execução.

### Windows

- [ ] build debug.
- [ ] build release.
- [ ] plugins.
- [ ] instalação.
- [ ] execução.

---

## UI

- [ ] resolução pequena.
- [ ] resolução grande.
- [ ] janela redimensionada.
- [ ] texto longo.
- [ ] título longo.
- [ ] lista vazia.
- [ ] lista enorme.
- [ ] loading lento.
- [ ] erro de rede.
- [ ] tema futuro quando aplicável.

---

## Acessibilidade

- [ ] navegação por teclado.
- [ ] foco visível.
- [ ] contraste.
- [ ] tamanho de texto.
- [ ] labels adequados.
- [ ] componentes utilizáveis sem mouse quando possível.

---

## CI

- [ ] `dart format`.
- [ ] `flutter analyze`.
- [ ] `flutter test`.
- [ ] build Linux.
- [ ] Gitleaks.
- [ ] Dependency Review.
- [ ] PR bloqueado quando check obrigatório falha.
- [ ] push novo cancela execução antiga.

---

## Release

- [ ] versão correta no `pubspec.yaml`.
- [ ] changelog atualizado.
- [ ] tag criada.
- [ ] artefato corresponde à tag.
- [ ] aplicativo mostra versão correta.
- [ ] migration de release validada.
- [ ] smoke test pós-release.
- [ ] rollback documentado.

---

# Matriz de criticidade

## Crítico

Deve bloquear release quando falhar:

- autenticação;
- autorização;
- RLS;
- perda de dados;
- corrupção;
- E2EE;
- migrations críticas;
- sync destrutivo;
- isolamento entre usuários;
- billing incorreto.

## Alto

Deve ser corrigido antes da release quando possível:

- criação;
- edição;
- exclusão;
- pesquisa;
- carregamento;
- notificações;
- quotas;
- atualização.

## Médio

Pode ser avaliado conforme impacto:

- pequenos problemas visuais;
- mensagens;
- comportamento secundário;
- otimizações não críticas.

---

# Testes de regressão

Sempre que um bug relevante for encontrado:

```text
Bug
 ↓
Issue
 ↓
Teste que reproduz
 ↓
Correção
 ↓
Teste passa
 ↓
Regressão protegida
```

Exemplos importantes:

- pesquisa sem destaque;
- duplicação de conceitos;
- loading infinito;
- exclusão que reaparece;
- sync duplicando registro;
- usuário acessando registro incorreto.

---

# Critério para considerar uma área validada

Não marque um item como concluído apenas porque funcionou uma vez.

Quando aplicável, valide:

- caso normal;
- caso inválido;
- offline;
- reinicialização;
- retry;
- usuário diferente;
- grande quantidade de dados;
- erro controlado.

---

# Evidências

Para testes relevantes, registrar quando necessário:

```text
Issue:
Branch:
Commit:
Ambiente:
Passos:
Resultado:
Screenshot:
Log:
```

Isso ajuda a reproduzir regressões no futuro.

---

# Relação com Issues

Quando um teste falhar e revelar um problema:

```text
Testing Roadmap
      ↓
Falha encontrada
      ↓
Issue
      ↓
Correção
      ↓
Teste de regressão
      ↓
PR
      ↓
CI
      ↓
Validado
```

---

# Manutenção

Este roadmap deve ser atualizado conforme o sistema evoluir.

Ao adicionar uma funcionalidade importante:

1. adicionar os cenários de teste;
2. definir criticidade;
3. automatizar o que for viável;
4. registrar bugs encontrados;
5. adicionar regressão após correções;
6. marcar como validado somente após testes suficientes.

O objetivo não é marcar todas as caixas rapidamente.

O objetivo é construir confiança real de que o sistema continua funcionando
conforme cresce.
