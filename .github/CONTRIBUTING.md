# Como Contribuir

Obrigado por contribuir com este projeto.

Este documento define o fluxo recomendado para escolher tarefas, criar branches,
desenvolver, testar, abrir Pull Requests, solicitar revisão e integrar mudanças
com segurança.

---

## 1. Antes de começar

Antes de alterar o código:

1. atualize seu repositório local;
2. verifique a branch correta;
3. confira se já existe uma issue, tarefa ou Pull Request relacionado;
4. entenda o escopo da alteração;
5. identifique dependências ou impactos;
6. evite incluir mudanças não relacionadas na mesma branch.

Exemplo:

```bash
git checkout main
git pull origin main
```

> Se o projeto utilizar outra branch base, adapte os comandos conforme o fluxo
> atual da equipe.

Nunca faça mudanças diretamente na `main` quando o fluxo exigir Pull Request.

---

## 2. Como escolher uma tarefa

Dê preferência a tarefas que:

- estejam abertas e ainda não tenham responsável;
- possuam descrição e critérios de aceite claros;
- estejam dentro do escopo atual do projeto;
- não dependam de outra tarefa ainda não concluída;
- tenham prioridade ou contexto suficiente para desenvolvimento.

Antes de iniciar, verifique:

- objetivo;
- arquivos ou módulos envolvidos;
- comportamento esperado;
- possíveis dependências;
- critérios de aceite;
- necessidade de migration;
- impacto em banco;
- impacto em sync;
- impacto em segurança;
- impacto em outras plataformas;
- necessidade de documentação.

Quando aplicável, associe-se à issue ou informe que começará a trabalhar nela.

Mudanças grandes ou arquiteturais devem ser alinhadas antes da implementação.

---

## 3. Criando uma branch

Nunca desenvolva diretamente na `main`.

Crie uma branch específica para cada tarefa.

Padrão recomendado:

```text
tipo/descricao-curta
```

Tipos comuns:

```text
feature/   nova funcionalidade
fix/       correção de bug
hotfix/    correção urgente
refactor/  refatoração sem mudança funcional intencional
docs/      documentação
test/      testes
chore/     manutenção ou configuração
perf/      melhoria de desempenho
security/  correção relacionada à segurança
ci/        integração contínua
build/     sistema de build
```

Exemplos:

```text
feature/task-notifications
fix/search-highlight
refactor/brain-controller
docs/update-contributing
security/session-validation
ci/flutter-workflow
```

Criando a branch:

```bash
git checkout main
git pull origin main
git checkout -b feature/task-notifications
```

---

## 4. Trabalhando na tarefa

Mantenha a alteração focada.

Evite misturar na mesma branch:

- nova funcionalidade;
- refatoração extensa;
- atualização de dependências;
- alterações de infraestrutura;
- mudanças visuais não relacionadas;
- correções de outros bugs;
- migrations sem relação com a tarefa.

Antes de adicionar arquivos:

```bash
git status
git diff
```

Adicione somente o que pertence à tarefa:

```bash
git add caminho/do/arquivo
```

Quando todas as mudanças pertencem à mesma tarefa:

```bash
git add .
```

Revise novamente:

```bash
git status
git diff --cached
```

---

## 5. Padrão de commits

Use commits pequenos, claros e relacionados a uma única intenção.

Padrão recomendado baseado em Conventional Commits:

```text
tipo(escopo): descrição curta
```

Exemplos:

```text
feat(tasks): adiciona notificação para usuário atribuído
fix(search): corrige destaque inconsistente dos resultados
refactor(brain): simplifica carregamento dos conceitos
docs(repo): adiciona guia de contribuição
test(auth): adiciona testes de sessão expirada
chore(deps): atualiza dependências do projeto
perf(dashboard): reduz consultas durante carregamento
security(auth): valida token antes de restaurar sessão
ci(repo): adiciona workflow de análise e testes
```

Tipos principais:

```text
feat      nova funcionalidade
fix       correção
docs      documentação
refactor  refatoração
test      testes
chore     manutenção
perf      desempenho
security  segurança
build     sistema de build
ci        integração contínua
```

Evite mensagens vagas como:

```text
update
fix
alterações
coisas novas
teste
final
ajustes
agora vai
```

### Commits maiores

Quando necessário, adicione contexto no corpo:

```bash
git commit \
  -m "feat(tasks): adiciona convite de tarefa" \
  -m "Cria notificação para o usuário atribuído e adiciona acesso rápido pelo dashboard."
```

---

## 6. Banco de dados e migrations

Mudanças de schema devem ser feitas por migrations versionadas.

Antes de criar ou alterar uma migration:

- confirme que ela pertence à tarefa;
- revise impacto em produção;
- valide políticas RLS;
- evite operações destrutivas desnecessárias;
- considere rollback ou estratégia de correção.

Nunca altere silenciosamente uma migration já aplicada em produção.

Crie uma nova migration quando necessário.

Exemplo:

```bash
supabase migration new add_task_notifications
```

Nunca inclua dumps de produção, credenciais ou dados reais no repositório.

---

## 7. Antes de abrir um Pull Request

Atualize sua branch com a branch base.

Exemplo com rebase:

```bash
git fetch origin
git rebase origin/main
```

Ou, se o projeto utilizar merge:

```bash
git merge origin/main
```

Resolva conflitos antes de abrir o PR.

Depois confira:

```bash
git status
git log --oneline --decorate -n 10
```

---

## 8. Testes obrigatórios

Antes de solicitar revisão, valide a alteração localmente.

No mínimo:

- o projeto deve compilar;
- a funcionalidade alterada deve funcionar;
- fluxos diretamente relacionados não devem quebrar;
- não devem existir erros novos no console;
- arquivos temporários, secrets e builds não devem entrar no commit.

Para Flutter:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Quando aplicável:

```bash
flutter run
```

ou:

```bash
flutter build linux --debug
```

Também revise:

```bash
git diff origin/main...HEAD
```

Verifique especialmente:

- credenciais;
- `.env`;
- tokens;
- chaves;
- arquivos gerados;
- logs;
- dumps de banco;
- dados pessoais;
- arquivos muito grandes;
- configurações específicas da máquina local.

---

## 9. Testes específicos

Dependendo da alteração, valide também:

### Interface

- fluxo principal;
- loading;
- estado vazio;
- erro;
- diferentes tamanhos de janela quando aplicável.

### Banco

- criação;
- leitura;
- edição;
- exclusão;
- migration;
- RLS.

### Sync

- online;
- offline;
- reconexão;
- retry;
- conflitos;
- duplicação;
- tombstones.

### Segurança

- autenticação;
- autorização;
- isolamento entre usuários;
- armazenamento local;
- exposição de dados;
- permissões.

---

## 10. Abrindo um Pull Request

Envie sua branch:

```bash
git push -u origin feature/task-notifications
```

Abra o Pull Request para a branch correta.

O PR deve seguir o template definido em:

```text
.github/PULL_REQUEST_TEMPLATE.md
```

### Título

Use um título objetivo.

Exemplo:

```text
feat(tasks): adiciona notificações para tarefas atribuídas
```

### Descrição

Explique:

- o que foi alterado;
- por que a mudança foi necessária;
- como testar;
- riscos;
- limitações;
- migrations;
- impacto em segurança;
- issue relacionada;
- screenshots ou vídeos quando houver alteração visual.

Exemplo:

```markdown
## O que foi feito

- envia uma notificação ao usuário atribuído;
- mostra a tarefa no dashboard;
- adiciona acesso direto à tarefa.

## Como testar

1. entrar com o usuário A;
2. atribuir uma tarefa ao usuário B;
3. entrar com o usuário B;
4. verificar a notificação;
5. abrir a tarefa pelo dashboard.

## Checklist

- [x] Código compilando
- [x] Testes executados
- [x] Sem credenciais no commit
- [x] Fluxo principal validado

Closes #123
```

---

## 11. Tamanho do Pull Request

Sempre que possível, prefira PRs pequenos.

Um bom Pull Request deve permitir que outra pessoa entenda:

- qual problema está sendo resolvido;
- quais arquivos foram afetados;
- como validar a solução;
- quais impactos a mudança pode gerar.

Se uma tarefa ficou grande demais, considere dividi-la em PRs menores.

Evite PRs que misturem múltiplos objetivos independentes.

---

## 12. GitHub Actions e CI

Pull Requests podem executar verificações automáticas como:

- formatação;
- `flutter analyze`;
- testes;
- build;
- secret scanning;
- dependency review.

Quando um check falhar:

1. abra o log;
2. identifique o passo que falhou;
3. corrija o problema;
4. envie um novo commit;
5. aguarde a nova execução.

PRs não devem ser integrados com checks críticos falhando sem justificativa
técnica documentada.

---

## 13. Pedindo revisão

Só marque alguém para revisar quando o PR estiver pronto.

Antes de solicitar revisão:

- remova código temporário;
- resolva TODOs relacionados à tarefa;
- execute os testes;
- revise seu próprio diff;
- atualize a descrição do PR;
- informe limitações conhecidas;
- verifique se o CI está passando.

Ao pedir revisão, destaque pontos que merecem atenção especial.

Exemplo:

```text
PR pronto para revisão.

Pontos principais:
- novo fluxo de atribuição de tarefas;
- criação de notificação;
- atualização do dashboard.

Atenção especial:
- lógica de sincronização;
- tratamento de tarefas já concluídas.
```

---

## 14. CODEOWNERS

O projeto pode utilizar:

```text
.github/CODEOWNERS
```

para definir responsáveis por determinadas áreas.

Quando o GitHub solicitar automaticamente um revisor responsável por determinada
pasta, aguarde a revisão correspondente quando exigido pelas regras da branch.

---

## 15. Durante a revisão

Feedback de revisão faz parte do processo.

Ao receber comentários:

1. responda dúvidas;
2. implemente correções necessárias;
3. envie novos commits;
4. explique quando optar por não aplicar uma sugestão;
5. marque conversas como resolvidas somente após corrigir ou alinhar o po
