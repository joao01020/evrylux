# EVRYLUX — Checklist de Lançamento

Este README organiza o que precisa estar pronto antes do lançamento público do
EVRYLUX.

A prioridade está dividida em três níveis:

- **BLOQUEADOR DE LANÇAMENTO** → não deve lançar sem isso.
- **IMPORTANTE** → ideal fechar antes do público geral; pode entrar durante beta
  se o risco estiver controlado.
- **PODE FICAR PARA DEPOIS** → melhora produto e operação, mas não precisa
  impedir o primeiro lançamento controlado.

## Estado atual da auditoria de segurança

| Área                                                       | Estado                                                 |
| ---------------------------------------------------------- | ------------------------------------------------------ |
| RLS nas tabelas `public`                                   | <X> concluído                                          |
| RLS no Supabase Storage                                    | <X> concluído                                          |
| Storage isolado por `auth.uid()`                           | <X> concluído                                          |
| Policies principais por usuário                            | <X> concluído                                          |
| `storage.objects` com SELECT/INSERT/UPDATE/DELETE por dono | <X> concluído                                          |
| `storage.buckets` com RLS ativo                            | <X> concluído                                          |
| Policies abertas com `USING (true)`                        | <X> auditado — somente `app_updates` para autenticados |
| RPCs principais do Brain                                   | <X> auditadas                                          |
| RPCs internas expostas a `anon`                            | <X> corrigido                                          |
| `SECURITY DEFINER` sensíveis                               | <X> auditadas                                          |
| `is_routine_owner()`                                       | <X> restrita a `authenticated`                         |
| `rls_auto_enable()`                                        | <X> removido EXECUTE de cliente                        |
| triggers de validação do Brain                             | <X> removido EXECUTE de cliente                        |
| `CREATE` no schema `public`                                | <X> bloqueado para `anon` e `authenticated`            |
| Grants `TRUNCATE`, `TRIGGER`, `REFERENCES`                 | <X> removidos de `anon` e `authenticated`              |
| `routine_blocks_view`                                      | <X> auditada com `security_invoker=true`               |
| trigger functions públicas                                 | <X> auditadas                                          |
| `upsert_brain_object_e2ee`                                 | <X> auditada                                           |
| tabela antiga `study_sessions`                             | <X> identificada como não usada e sem dependências     |
| credencial `service_role` no Flutter                       | <X> não encontrada                                     |
| segredo `sb_secret_` no repositório                        | <X> não encontrado                                     |
| `.env` versionado                                          | <X> não — está ignorado pelo Git                       |
| `service_role` real no histórico Git                       | <X> não encontrada                                     |
| acesso de `anon` a funções `public`                        | <X> nenhum EXECUTE restante                            |
| acesso de `anon` às tabelas privadas                       | <X> hardening concluído                                |
| teste real Conta A → Conta B                               | [ ] pendente                                           |
| teste cruzado no Storage A → B                             | [ ] pendente                                           |
| revisão de Edge Functions                                  | [ ] pendente                                           |
| rate limiting / antiabuso                                  | [ ] pendente                                           |
| Auth / sessões / recovery                                  | [ ] pendente                                           |
| teste offline completo                                     | [ ] pendente                                           |
| backup / restore                                           | [ ] pendente                                           |
| beta fechado                                               | [ ] pendente                                           |

---

## Resumo do que já foi concluído nesta auditoria

- <X> RLS ativada em todas as tabelas relevantes do schema `public`.
- <X> RLS ativada em `storage.objects` e `storage.buckets`.
- <X> Storage validado com isolamento por pasta `auth.uid()`.
- <X> Policies de `board-files` auditadas.
- <X> Policies de `routine-images` auditadas.
- <X> Policies principais do schema `public` auditadas.
- <X> `app_updates` validado com leitura global apenas para `authenticated`.
- <X> Funções `SECURITY DEFINER` sensíveis revisadas.
- <X> RPCs do Brain verificadas usando `auth.uid()` como identidade real do
  usuário.
- <X> `_brain_device_authorized_internal()` bloqueada para `anon` e
  `authenticated`.
- <X> `approve_brain_device()` validada.
- <X> `brain_device_is_authorized()` validada.
- <X> `claim_brain_device_envelope()` validada.
- <X> `get_brain_device()` validada.
- <X> `list_brain_devices()` validada.
- <X> `register_brain_device()` validada.
- <X> `revoke_brain_device()` validada.
- <X> `register_user_device()` validada.
- <X> `revoke_user_device()` validada.
- <X> `disconnect_current_user_device()` validada.
- <X> `touch_user_device()` validada.
- <X> `rls_auto_enable()` não pode mais ser executada pelo cliente.
- <X> `validate_brain_concept_owner()` não pode mais ser executada pelo cliente.
- <X> `validate_brain_review_owner()` não pode mais ser executada pelo cliente.
- <X> `is_routine_owner()` removida de `anon` e mantida para `authenticated`.
- <X> `TRUNCATE`, `TRIGGER` e `REFERENCES` removidos de `anon` e
  `authenticated`.
- <X> `routine_blocks_view` confirmada como `security_invoker=true`.
- <X> `routine_blocks_view` confirmada como não atualizável e não inserível.
- <X> `set_app_updates_updated_at()` auditada.
- <X> `set_updated_at()` auditada.
- <X> `sync_task_completed_at()` auditada.
- <X> `update_routine_comments_updated_at()` auditada.
- <X> `upsert_brain_object_e2ee()` auditada e vinculada a `auth.uid()`.
- <X> `study_sessions` estava vazia.
- <X> `study_sessions` não aparece no código Flutter atual.
- <X> `study_sessions` não possui foreign keys dependentes.
- <X> `study_sessions` não possui triggers.
- <X> `study_sessions` não possui views/dependências registradas.
- <X> `anon` e `authenticated` não possuem `CREATE` no schema `public`.
- <X> Nenhuma função `public` continua executável por `anon`.
- <X> Nenhuma `service_role` real encontrada no Flutter.
- <X> Nenhuma `sb_secret_` real encontrada no código.
- <X> Nenhuma URL PostgreSQL com senha encontrada.
- <X> `.env` está ignorado pelo Git.
- <X> `.env` não está versionado.
- <X> Histórico Git não mostrou uma credencial administrativa real.

# Visão geral**

Ordem recomendada:

```text
1\. Vault / chaves / recuperação

2\. RLS e permissões Supabase

3\. Local ↔ Cloud

4\. Backup / restore

5\. Antiabuso

6\. Crash handling

7\. Migrações

8\. Privacidade / exclusão de conta

9\. Installer / ícone / atualização

10\. Teste em máquina limpa

11\. Beta fechado

12\. Lançamento público
```

O objetivo principal antes do lançamento é simples:

> O EVRYLUX não pode perder conhecimento, misturar contas, vazar dados, quebrar
> o Vault ou deixar o usuário preso sem recuperação.

**---**

**# FASE 1 — VAULT, CHAVES E RECUPERAÇÃO**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

Essa é a parte mais crítica do EVRYLUX.

**## Checklist**

- [ ] Vault abre corretamente em instalação normal.

- [ ] Vault abre após fechar e abrir o aplicativo.

- [ ] Vault abre após reiniciar o computador.

- [ ] Logout não apaga chave de outra forma inesperada.

- [ ] Login novamente na mesma conta recupera o estado esperado.

- [ ] Trocar de conta não mistura Vault, chave ou preferência Local/Cloud.

- [ ] Cada conta usa o próprio contexto de segurança.

- [ ] Chave criptográfica nunca fica salva em plaintext.

- [ ] Chave nunca aparece em logs.

- [ ] Tokens nunca aparecem em logs.

- [ ] `keyNotFound` não derruba o aplicativo.

- [ ] Falta de chave mostra uma tela de recuperação clara.

- [ ] Usuário consegue entender o que aconteceu quando a chave não existe.

- [ ] Dispositivo autorizado consegue recuperar Cloud quando aplicável.

- [ ] Dispositivo revogado perde acesso ao fluxo Cloud.

- [ ] Recovery não aceita dispositivo não autorizado.

- [ ] Tentativas de recuperação possuem limite/cooldown.

- [ ] Recuperação falha fechada quando o estado não é seguro.

**## Cenários obrigatórios de teste**

**### Teste A — uso normal**

```text
login

↓

abre Cérebro

↓

Vault abre

↓

cria conhecimento

↓

fecha app

↓

abre novamente

↓

conteúdo continua acessível
```

- [ ] Aprovado

**### Teste B — logout/login**

```text
Conta A

↓

cria conteúdo

↓

logout

↓

login Conta A

↓

Vault correto reaparece
```

- [ ] Aprovado

**### Teste C — duas contas**

```text
Conta A

↓

conteúdo A

logout

Conta B

↓

conteúdo B
```

Resultado esperado:

```text
Conta A nunca vê B

Conta B nunca vê A
```

- [ ] Aprovado

**### Teste D — chave ausente**

Simular chave indisponível.

Resultado esperado:

```text
NÃO crashar

NÃO recriar chave silenciosamente sobre Vault antigo

NÃO apagar dados

mostrar caminho de recuperação
```

- [ ] Aprovado

**---**

**# FASE 2 — RLS E PERMISSÕES DO SUPABASE**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

Nunca dependa apenas do Flutter para segurança de dados.

O usuário pode chamar a API do Supabase diretamente.

**## Checklist**

- <X> RLS ativada em todas as tabelas privadas.

- [ ] Usuário só consegue ler os próprios registros. **Policies auditadas; falta
      teste real Conta A → Conta B.**

- [ ] Usuário só consegue atualizar os próprios registros. **Policies auditadas;
      falta teste real cruzado.**

- [ ] Usuário só consegue deletar os próprios registros. **Policies auditadas;
      falta teste real cruzado.**

- <X> Usuário não consegue definir `user_id` arbitrário nas RPCs auditadas;
  funções críticas derivam identidade de `auth.uid()`.

- <X> Service Role nunca está embutida no app.

- <X> O cliente usa `SUPABASE_PUBLISHABLE_KEY`; nenhuma chave administrativa foi
  encontrada.

- <X> Storage possui policies equivalentes para `board-files` e
  `routine-images`, isoladas por `auth.uid()`.

- <X> Tabelas de device authorization ficam protegidas atrás de RPCs específicas
  e RLS.

- <X> RPCs de recovery auditadas e filtradas por `auth.uid()`; falta apenas
  teste prático entre duas contas.

- [ ] Sync queue remota não pode ser manipulada por outro usuário.

- <X> `brain_objects` e `upsert_brain_object_e2ee()` foram auditados por
  usuário/Vault; falta teste cruzado final.

**## Testes de ataque obrigatórios**

Tentar manualmente:

```text
SELECT registro de outro user_id

UPDATE registro de outro user_id

DELETE registro de outro user_id

INSERT usando user_id de outra pessoa
```

Resultado esperado:

```text
NEGADO
```

- [ ] Aprovado

## Hardening já concluído no banco

- <X> `anon` sem `CREATE` no schema `public`.
- <X> `authenticated` sem `CREATE` no schema `public`.
- <X> `TRUNCATE` removido de clientes.
- <X> `TRIGGER` removido de clientes.
- <X> `REFERENCES` removido de clientes.
- <X> Nenhuma função do schema `public` permanece executável por `anon`.
- <X> Funções internas/trigger não ficam expostas ao cliente.
- <X> `routine_blocks_view` usa `security_invoker=true`.
- <X> `routine_blocks_view` não é atualizável nem inserível.
- <X> `app_updates` é o único caso auditado de `USING (true)` e está limitado a
  `authenticated` para leitura.
- <X> `.env` não é rastreado pelo Git.
- <X> Nenhum segredo administrativo real encontrado no código ou histórico Git.
- <X> `SUPABASE_PUBLISHABLE_KEY` é a chave usada pelo Flutter.

## Teste final de isolamento ainda obrigatório

Executar com duas contas reais:

```text
Conta A cria:
- Brain note
- Reminder
- Finance data
- Routine
- Storage object

Conta B tenta:
- SELECT pelo ID da Conta A
- UPDATE pelo ID da Conta A
- DELETE pelo ID da Conta A
- INSERT usando identidade da Conta A
- baixar arquivo da Conta A
```

Resultado obrigatório:

```text
Conta B não lê A
Conta B não altera A
Conta B não apaga A
Conta B não assume propriedade de A
Conta B não baixa arquivo privado de A
```

- [ ] Teste Conta A → Conta B aprovado.
- [ ] Teste Conta B → Conta A aprovado.
- [ ] Teste de Storage cruzado aprovado.

**---**

**# PRÓXIMOS PASSOS DE SEGURANÇA

## Bloqueadores imediatos ainda pendentes

- [ ] Executar teste real de isolamento Conta A ↔ Conta B.
- [ ] Executar teste real de isolamento de Storage entre duas contas.
- [ ] Revisar Edge Function `account-cleanup`.
- [ ] Revisar Edge Function `send-reminders`.
- [ ] Confirmar validação de JWT/bearer token dentro das Edge Functions.
- [ ] Confirmar que `service_role` só existe em secrets do ambiente da Edge
      Function.
- [ ] Revisar rate limiting de endpoints sensíveis.
- [ ] Revisar recuperação de senha.
- [ ] Revisar expiração/refresh de sessão.
- [ ] Revisar revogação de sessões/dispositivos.
- [ ] Testar conta revogada tentando continuar usando token antigo.
- [ ] Testar dispositivo revogado tentando recuperar Brain.
- [ ] Testar payloads inválidos nas RPCs críticas.
- [ ] Testar limites de tamanho de payload/envelope.
- [ ] Confirmar que logs não imprimem tokens, secrets ou payload E2EE sensível.

## Depois dos testes de segurança

- [ ] Testar Local ↔ Cloud completo.
- [ ] Testar offline.
- [ ] Testar backup/restore.
- [ ] Testar migrações.
- [ ] Testar instalação limpa.
- [ ] Testar atualização de versão.
- [ ] Fazer beta fechado antes do lançamento público.

---

# FASE 3 — LOCAL ↔ CLOUD**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

Os dois modos precisam ter significado claro e previsível.

**## Local**

Comportamento esperado:

```text
dados permanecem no dispositivo

nenhum novo conteúdo do Cérebro sobe para Cloud

backup manual é responsabilidade do usuário
```

**### Checklist**

- [ ] Local funciona sem internet.

- [ ] Local funciona com Supabase fora do ar.

- [ ] Local não dispara upload do Brain.

- [ ] UI informa corretamente que os dados ficam neste dispositivo.

- [ ] Backup `.evbrain` fica disponível.

- [ ] Dispositivos Cloud ficam ocultos.

- [ ] Recuperação em outro dispositivo fica oculta.

**## Cloud**

Comportamento esperado:

```text
cópia local

\+

cópia criptografada na nuvem
```

**### Checklist**

- [ ] Cloud mantém cópia local.

- [ ] Cloud nunca depende exclusivamente da rede para abrir conteúdo já local.

- [ ] Upload acontece somente se gate de segurança permitir.

- [ ] Dispositivo precisa estar autorizado.

- [ ] Dados enviados ao banco estão criptografados.

- [ ] Cloud não envia plaintext.

- [ ] UI mostra estado pendente quando dispositivo ainda não foi autorizado.

- [ ] Falha de internet não perde conteúdo local.

**## Local → Cloud**

Fluxo esperado:

```text
ativa Cloud

↓

mantém conteúdo local

↓

detecta conteúdo antigo

↓

enfileira tudo

↓

criptografa

↓

sincroniza
```

**### Checklist**

- [ ] Conteúdo antigo também sobe.

- [ ] Conteúdo novo sobe.

- [ ] Não duplica objetos.

- [ ] Pode interromper e continuar depois.

- [ ] Mostra progresso.

- [ ] Falha parcial pode ser retomada.

- [ ] Não apaga local após upload.

**## Cloud → Local**

Fluxo esperado:

```text
desativa novos syncs

↓

mantém conteúdo local

↓

não apaga automaticamente cópia remota
```

**### Checklist**

- [ ] Pede confirmação.

- [ ] Para novos uploads.

- [ ] Mantém dados locais.

- [ ] Não apaga remoto automaticamente.

- [ ] Ação destrutiva de apagar Cloud, se existir, é separada.

**---**

**# FASE 4 — BACKUP E RESTAURAÇÃO**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

Se o usuário escolhe Local, o backup é essencial.

**## Checklist**

- [ ] Exportar `.evbrain` funciona.

- [ ] Backup é criado com sucesso em máquina real.

- [ ] Backup não inclui Master Key em plaintext.

- [ ] Backup preserva estrutura necessária.

- [ ] Importar `.evbrain` funciona.

- [ ] Restore não sobrescreve tudo silenciosamente.

- [ ] Arquivo inválido é rejeitado.

- [ ] Arquivo corrompido é rejeitado.

- [ ] Backup de outro Vault não é aceito sem fluxo válido.

- [ ] Tamanho máximo definido.

- [ ] Importação grande não trava a interface.

- [ ] Restore interrompido não deixa estado inconsistente.

- [ ] Usuário recebe mensagem clara de sucesso/erro.

**## Teste obrigatório**

Criar backup em uma instalação e restaurar em ambiente limpo.

- [ ] Aprovado

**---**

**# FASE 5 — ANTIABUSO**

**## Prioridade**

****BLOQUEADOR antes de abrir recursos sociais**** **IMPORTANTE para lançamento

privado**

**## Cadastro**

- [ ] Confirmação de e-mail ativada.

- [ ] CAPTCHA/Turnstile no signup.

- [ ] Rate limit de autenticação revisado.

- [ ] Recuperação de senha com rate limit.

- [ ] Tentativas repetidas recebem cooldown.

- [ ] E-mails descartáveis podem ser bloqueados no futuro.

- [ ] Before User Created Hook considerado para produção pública.

**## Conta nova**

Conta recém-criada não precisa ter todos os privilégios sociais imediatamente.

Exemplo:

```text
Conta nova

→ limites menores

Conta verificada

→ limites normais

Conta suspeita

→ cooldown / restrição
```

**### Checklist**

- [ ] Limite para operações caras.

- [ ] Limite de criação em massa.

- [ ] Limite de convites futuros.

- [ ] Limite de compartilhamentos futuros.

- [ ] Limite de recuperação.

- [ ] Limite de importação.

**## Conteúdo**

- [ ] Tamanho máximo por nota.

- [ ] Tamanho máximo por arquivo.

- [ ] Tamanho máximo por backup.

- [ ] Quantidade máxima de anexos definida.

- [ ] Payload inválido rejeitado.

- [ ] URLs suspeitas podem ser tratadas futuramente.

- [ ] Arquivos executáveis não são tratados como conteúdo confiável.

**---**

**# FASE 6 — CRASH HANDLING E ESTADOS DE ERRO**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

O aplicativo não pode morrer por estados previsíveis.

**## Erros que precisam ter UX**

- [ ] Chave ausente.

- [ ] Vault indisponível.

- [ ] Supabase offline.

- [ ] Sem internet.

- [ ] Sessão expirada.

- [ ] Dispositivo não autorizado.

- [ ] Sync pendente.

- [ ] Backup inválido.

- [ ] Importação falhou.

- [ ] Banco local indisponível.

- [ ] Permissão de arquivo negada.

- [ ] Espaço em disco insuficiente.

**## Regra**

Nunca:

```text
Unhandled Exception

→ aplicativo fica inutilizável
```

Preferir:

```text
erro conhecido

↓

estado seguro

↓

mensagem amigável

↓

ação possível
```

**---**

**# FASE 7 — INTEGRIDADE DOS DADOS**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

**## Checklist**

- [ ] Salvar é idempotente.

- [ ] Sync é idempotente.

- [ ] Retry não duplica conteúdo.

- [ ] Fechar app durante save não corrompe Vault.

- [ ] Fechar app durante sync não perde objeto.

- [ ] Editar não cria duplicata.

- [ ] Excluir localmente é refletido corretamente.

- [ ] Conflitos Cloud são tratados.

- [ ] `updatedAt` é consistente.

- [ ] IDs são estáveis.

- [ ] Operações críticas são atômicas quando necessário.

**---**

**# FASE 8 — IDENTIDADE VISUAL PERSISTENTE DO CÉREBRO**

**## Prioridade**

****IMPORTANTE****

Antes de aumentar muito a visualização do cérebro, a ligação entre conteúdo e

ramo precisa ser estável.

**## Hoje**

```text
BrainFile

→ posição cronológica

→ conexão visual
```

Isso funciona para a versão atual, mas pode ficar limitado.

**## Antes de escalar**

Criar uma associação persistente, por exemplo:

```text
BrainFile

↕

visualBranchId

↕

BrainVisual
```

ou:

```text
semanticKey

branchId

visualNodeId
```

**## Checklist**

- [ ] Mesmo conhecimento sempre acende o mesmo caminho.

- [ ] Editar não muda caminho.

- [ ] Reiniciar app não muda caminho.

- [ ] Backup/restore reconstrói a mesma associação.

- [ ] Cloud em outro dispositivo reconstrói corretamente.

- [ ] Excluir remove a associação.

- [ ] Reordenar lista não muda ramo.

Depois disso vale aumentar:

- [ ] número de ramificações;

- [ ] clusters;

- [ ] regiões;

- [ ] conexões secundárias;

- [ ] animações mais complexas.

**---**

**# FASE 9 — MIGRAÇÕES**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

Usuário antigo não pode depender de reinstalação limpa.

**## Checklist**

- [ ] Existe versão do schema local.

- [ ] Existe versão do Vault.

- [ ] Existe versão do payload Cloud.

- [ ] Migrações são incrementais.

- [ ] Migração falha sem destruir dados antigos.

- [ ] Backup antes de migração crítica, quando necessário.

- [ ] App antigo → app novo testado.

- [ ] Dados antigos continuam legíveis.

**## Regra**

Nunca lançar uma mudança que exija:

```text
"apague os dados e instale novamente"
```

para o usuário comum.

**---**

**# FASE 10 — PRIVACIDADE E EXCLUSÃO DE CONTA**

**## Prioridade**

****BLOQUEADOR para lançamento público****

**## Política de privacidade**

Explicar claramente:

- [ ] O que fica local.

- [ ] O que vai para Cloud.

- [ ] O que é criptografado.

- [ ] O que o servidor consegue ver.

- [ ] O que o servidor não consegue ver.

- [ ] Quais dados de conta são armazenados.

- [ ] Logs e telemetria, se existirem.

- [ ] Como solicitar exclusão.

**## Exclusão de conta**

Definir comportamento:

```text
Excluir conta

↓

remover dados remotos

↓

revogar dispositivos

↓

invalidar sessões

↓

explicar o que acontece com dados locais
```

**### Checklist**

- [ ] Usuário consegue solicitar exclusão.

- [ ] Confirmação explícita.

- [ ] Dados remotos são removidos conforme política.

- [ ] Sessões são revogadas.

- [ ] Dispositivos são revogados.

- [ ] Local não é apagado silenciosamente sem aviso.

- [ ] Prazo de retenção documentado, se houver.

**---**

**# FASE 11 — LOGS E OBSERVABILIDADE**

**## Prioridade**

****IMPORTANTE****

Você precisa conseguir diagnosticar erros depois do lançamento.

**## Registrar**

- [ ] Falha de inicialização.

- [ ] Falha de Vault.

- [ ] Falha de sync.

- [ ] Falha de autenticação.

- [ ] Falha de recuperação.

- [ ] Falha de migração.

- [ ] Crash.

**## Nunca registrar**

- [ ] Master Key.

- [ ] Chaves derivadas.

- [ ] Tokens JWT completos.

- [ ] Senhas.

- [ ] Conteúdo privado do Brain sem necessidade.

- [ ] Backup descriptografado.

- [ ] Dados sensíveis em plaintext.

**---**

**# FASE 12 — ATUALIZAÇÕES DO APP**

**## Prioridade**

****IMPORTANTE****

**## Checklist**

- [ ] Versão do app definida.

- [ ] Changelog.

- [ ] Migração vinculada à versão quando necessário.

- [ ] Atualização não quebra dados locais.

- [ ] Atualização não muda Application ID.

- [ ] Atualização não perde secure storage.

- [ ] Atualização não perde Vault.

- [ ] Ícone/desktop entry consistentes.

- [ ] Installer cria backup quando altera arquivos sensíveis durante

      desenvolvimento.

**---**

**# FASE 13 — INSTALAÇÃO LIMPA**

**## Prioridade**

****BLOQUEADOR DE LANÇAMENTO****

Testar em uma máquina onde EVRYLUX nunca existiu.

**## Checklist**

- [ ] Instala.

- [ ] Abre.

- [ ] Ícone aparece corretamente.

- [ ] Signup funciona.

- [ ] Login funciona.

- [ ] Modal Local/Cloud aparece para conta nova.

- [ ] Local funciona.

- [ ] Cloud funciona.

- [ ] Vault é criado.

- [ ] Chave é criada.

- [ ] Reiniciar preserva chave.

- [ ] Criar conhecimento funciona.

- [ ] Pesquisa funciona.

- [ ] Backup funciona.

- [ ] Logout/login funciona.

**---**

**# FASE 14 — TESTE OFFLINE**

**## Prioridade**

****BLOQUEADOR para proposta local-first****

**## Checklist**

Com internet desligada:

- [ ] App abre.

- [ ] Vault abre.

- [ ] Conteúdo local aparece.

- [ ] Criar conhecimento funciona.

- [ ] Editar funciona.

- [ ] Excluir funciona.

- [ ] Pesquisa funciona.

- [ ] Brain visual funciona.

- [ ] Sync fica pendente sem quebrar a UX.

Depois da internet voltar:

- [ ] Sync retoma.

- [ ] Não duplica.

- [ ] Não perde conteúdo.

**---**

**# FASE 15 — PERFORMANCE**

**## Prioridade**

****IMPORTANTE****

Testar com volumes maiores.

**## Cenários**

- [ ] 100 conhecimentos.

- [ ] 500 conhecimentos.

- [ ] 1.000 conhecimentos.

- [ ] 5.000 conhecimentos, se fizer sentido para o produto.

Avaliar:

- [ ] Tempo de abertura.

- [ ] Memória.

- [ ] Pesquisa.

- [ ] Renderização do cérebro.

- [ ] Sync.

- [ ] Exportação de backup.

- [ ] Restore.

**---**

**# FASE 16 — ACESSIBILIDADE E UX DE SEGURANÇA**

**## Prioridade**

****IMPORTANTE****

**## Checklist**

- [ ] Mensagens não usam termos técnicos desnecessários.

- [ ] Local/Cloud são compreensíveis.

- [ ] Ações destrutivas possuem confirmação.

- [ ] Botões têm tooltip quando necessário.

- [ ] Estado de loading é visível.

- [ ] Estado de erro é visível.

- [ ] Usuário entende se algo está salvo localmente.

- [ ] Usuário entende se Cloud está pendente.

- [ ] Usuário entende quando precisa fazer backup.

**---**

**# FASE 17 — TERMOS DE USO**

**## Prioridade**

****BLOQUEADOR antes de recursos sociais públicos****

Principalmente quando existirem:

```text
Explorar

Compartilhamento

Transferência

Colaboração

Conteúdo público
```

**## Incluir**

- [ ] Conteúdo proibido.

- [ ] Abuso.

- [ ] Spam.

- [ ] Assédio.

- [ ] Conteúdo ilegal.

- [ ] Responsabilidade do usuário.

- [ ] Regras de compartilhamento.

- [ ] Direitos de autoria.

- [ ] Denúncias.

- [ ] Suspensão.

- [ ] Remoção de conteúdo.

**---**

**# FASE 18 — AUTORIA E PROVENIÊNCIA**

**## Prioridade**

****BLOQUEADOR antes de compartilhamento****

Para a ideia futura de conhecimento transferível:

```text
original_author_id

created_at original

parent_id

derived_from

contributors

history
```

**## Regras**

- [ ] Autor original nunca muda.

- [ ] Derivação cria novo objeto.

- [ ] Original não é sobrescrito.

- [ ] Alterações têm autoria.

- [ ] Histórico é preservado.

- [ ] Importar conteúdo público mantém origem.

- [ ] Cópia não vira automaticamente autoria própria.

**---**

**# FASE 19 — DENÚNCIA, BLOQUEIO E MODERAÇÃO**

**## Prioridade**

****BLOQUEADOR antes de camada social pública****

**## Checklist**

- [ ] Bloquear usuário.

- [ ] Denunciar usuário.

- [ ] Denunciar conteúdo.

- [ ] Ocultar conteúdo.

- [ ] Rate limit de denúncias.

- [ ] Sistema contra denúncia abusiva.

- [ ] Moderação administrativa.

- [ ] Registro de ação.

- [ ] Processo de recurso, se necessário.

**---**

**# FASE 20 — BETA FECHADO**

**## Prioridade**

****BLOQUEADOR antes do público geral****

Não ir direto para lançamento público.

**## Grupo recomendado**

```text
5 a 20 usuários
```

**## O que observar**

- [ ] Perda de dados.

- [ ] Crash.

- [ ] Erros de Vault.

- [ ] Erros de chave.

- [ ] Sync.

- [ ] Cloud.

- [ ] Local.

- [ ] Backup.

- [ ] Restore.

- [ ] Login/logout.

- [ ] Confusão de UX.

- [ ] Performance.

- [ ] Uso real da pesquisa.

- [ ] Uso real do Brain visual.

**## Regra**

Se houver qualquer relato de:

```text
"meu conteúdo sumiu"

"não consigo abrir meu Cérebro"

"troquei de conta e misturou"

"perdi a chave"
```

o lançamento público deve esperar.

**---**

**# FASE 21 — LANÇAMENTO PÚBLICO**

Só liberar quando os bloqueadores estiverem fechados.

**## Gate final**

**### Segurança**

- [ ] Vault estável.

- [ ] Chaves estáveis.

- [ ] Recovery funcional.

- <X> RLS — auditoria estrutural concluída; falta teste real A/B validada.

- [ ] Antiabuso básico ativo.

- [ ] Confirmação de e-mail ativa.

- [ ] CAPTCHA ativo.

**### Dados**

- [ ] Local estável.

- [ ] Cloud estável.

- [ ] Backup testado.

- [ ] Restore testado.

- [ ] Migrações testadas.

- [ ] Offline testado.

**### Produto**

- [ ] UX compreensível.

- [ ] Erros tratados.

- [ ] Installer/distribuição testados.

- [ ] Política de privacidade pronta.

- [ ] Exclusão de conta pronta.

- [ ] Termos de uso prontos se houver social.

**### Operação**

- [ ] Logs seguros.

- [ ] Monitoramento de falhas.

- [ ] Processo de suporte.

- [ ] Plano para rollback.

- [ ] Changelog/versionamento.

**---**

**# O QUE PODE FICAR PARA DEPOIS**

Estas coisas não precisam bloquear uma primeira versão sólida:

- [ ] Cérebro visual muito maior.

- [ ] Animações avançadas adicionais.

- [ ] Clusters semânticos complexos.

- [ ] Marketplace de conhecimento.

- [ ] Explorar público.

- [ ] Transferência entre usuários.

- [ ] Colaboração estilo GitHub.

- [ ] Reputação avançada.

- [ ] Ranking.

- [ ] Sugestões inteligentes complexas.

- [ ] Moderador automático avançado.

- [ ] Mobile.

- [ ] Windows/macOS, se o lançamento inicial for Linux.

- [ ] Sistema completo de analytics.

**---**

**# PRIORIZAÇÃO RESUMIDA**

**## BLOQUEADORES**

```text
[ ] Vault

[ ] Chaves

[ ] Recovery

<X> RLS — auditoria estrutural concluída; falta teste real A/B

[ ] Local

[ ] Cloud

[ ] Backup

[ ] Restore

[ ] Crash handling

[ ] Integridade de dados

[ ] Migrações

[ ] Instalação limpa

[ ] Offline

[ ] Privacidade

[ ] Exclusão de conta

[ ] Beta fechado
```

Antes de social:

```text
[ ] Antiabuso

[ ] Autoria

[ ] Proveniência

[ ] Denúncia

[ ] Bloqueio

[ ] Termos
```

**## IMPORTANTES**

```text
[ ] Logs

[ ] Observabilidade

[ ] Performance

[ ] UX de segurança

[ ] Atualizações

[ ] Identidade visual persistente
```

**## DEPOIS**

```text
[ ] Cérebro maior

[ ] Explore

[ ] Transferência

[ ] Colaboração

[ ] Reputação

[ ] Recursos sociais avançados
```

**---**

**# REGRA PRINCIPAL DO EVRYLUX**

Antes de adicionar novas funcionalidades, fazer sempre esta pergunta:

> Essa alteração pode fazer o usuário perder acesso, perder conhecimento,

> misturar dados, vazar informação ou ficar sem recuperação?

Se a resposta for ****sim****, ela exige teste antes de entrar em produção.

**---**

**# DEFINIÇÃO DE PRONTO PARA LANÇAMENTO**

O EVRYLUX estará pronto para o primeiro lançamento público quando:

```text
um usuário novo

↓

instala

↓

cria conta

↓

escolhe Local ou Cloud

↓

cria conhecimento

↓

fecha o app

↓

abre novamente

↓

continua com tudo

↓

fica offline

↓

continua usando

↓

volta online

↓

sincroniza corretamente

↓

faz backup

↓

restaura

↓

troca de sessão

↓

nada é misturado

↓

nenhum estado esperado causa crash
```

Quando esse fluxo estiver confiável, o produto já tem uma base forte para

crescer.
