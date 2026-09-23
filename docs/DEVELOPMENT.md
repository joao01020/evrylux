# Ambiente de Desenvolvimento

## 1. Objetivo

Este documento explica como preparar, validar e utilizar o ambiente local de
desenvolvimento do projeto.

O objetivo é permitir que um novo colaborador consiga:

- clonar o repositório;
- configurar Flutter;
- configurar variáveis de ambiente;
- executar o aplicativo;
- trabalhar com Supabase;
- criar branches;
- executar testes;
- abrir Pull Requests.

---

## 2. Estrutura esperada

O projeto utiliza aproximadamente esta estrutura:

```text
ghost-core/
├── app/
├── website/
├── supabase/
├── scripts/
├── docs/
└── .github/
```

A aplicação Flutter principal está em:

```text
app/
```

---

## 3. Pré-requisitos

Ferramentas principais:

- Git;
- Flutter;
- Dart;
- VS Code ou outro editor compatível;
- Docker;
- Supabase CLI;
- GitHub CLI (`gh`) recomendado.

Confirme:

```bash
git --version
flutter --version
dart --version
docker --version
supabase --version
gh --version
```

Depois:

```bash
flutter doctor -v
```

Corrija erros relevantes antes de começar o desenvolvimento.

---

## 4. Clonando o projeto

Clone:

```bash
git clone https://github.com/joao01020/ghost-core.git
cd ghost-core
```

Confira as branches:

```bash
git branch -a
```

Atualize as referências:

```bash
git fetch --all --prune
```

---

## 5. Branch de trabalho

Evite desenvolver diretamente na `main`.

Antes de iniciar uma tarefa, confirme qual branch deve ser utilizada como base.

Exemplo:

```bash
git branch --show-current
```

Quando `main` for a base:

```bash
git checkout main
git pull origin main
```

Crie sua branch:

```bash
git checkout -b feature/nome-da-tarefa
```

Se o projeto estiver utilizando uma branch intermediária de desenvolvimento,
crie a nova branch a partir dela.

Exemplo:

```bash
git checkout dev-stable
git pull origin dev-stable
git checkout -b feature/nome-da-tarefa
```

---

## 6. Aplicação Flutter

Entre em:

```bash
cd app
```

Instale dependências:

```bash
flutter pub get
```

Valide:

```bash
flutter doctor -v
```

Liste dispositivos:

```bash
flutter devices
```

Execute:

```bash
flutter run
```

---

## 7. Linux

Para executar como aplicação desktop Linux:

```bash
flutter config --enable-linux-desktop
flutter run -d linux
```

Se houver problemas com dependências nativas, confirme que as bibliotecas
necessárias ao Flutter Linux estão instaladas.

O CI também utiliza Linux para validar builds.

---

## 8. macOS

Em um Mac:

```bash
flutter config --enable-macos-desktop
flutter run -d macos
```

Execute:

```bash
flutter doctor -v
```

para verificar requisitos adicionais do ambiente macOS.

Plugins desktop podem possuir diferenças entre Linux, macOS e Windows.

Uma funcionalidade funcionando no Linux não deve ser considerada automaticamente
validada no macOS.

---

## 9. Windows

No Windows:

```powershell
flutter config --enable-windows-desktop
flutter run -d windows
```

Valide o ambiente com:

```powershell
flutter doctor -v
```

---

## 10. Variáveis de ambiente

Nunca compartilhe o `.env` real pelo Git.

O projeto deve possuir um exemplo sem secrets:

```text
.env.example
```

Exemplo:

```env
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
```

Crie o arquivo local conforme a localização esperada pelo aplicativo.

Exemplo:

```bash
cp .env.example .env
```

Preencha somente com as credenciais correspondentes ao ambiente correto.

O arquivo real deve estar no `.gitignore`.

Confirme:

```bash
git status
```

O `.env` não deve aparecer como arquivo pronto para commit.

---

## 11. Ambientes

Quando possível, mantenha separação entre:

```text
development
staging
production
```

Não utilize credenciais de produção durante desenvolvimento normal.

Cada colaborador deve utilizar somente as credenciais necessárias ao ambiente em
que está trabalhando.

---

## 12. Supabase

O projeto já inicializado normalmente possui:

```text
supabase/config.toml
```

Portanto, não execute `supabase init` novamente sem necessidade.

Confirme:

```bash
ls supabase/
```

Para vincular o repositório a um projeto remoto:

```bash
supabase link --project-ref PROJECT_REF
```

Use o `PROJECT_REF` correspondente ao ambiente correto.

---

## 13. Supabase local

Docker precisa estar funcionando:

```bash
docker info
```

Inicie:

```bash
supabase start
```

Confira:

```bash
supabase status
```

Pare:

```bash
supabase stop
```

---

## 14. Migrations

Mudanças de schema devem ocorrer através de migrations.

Crie:

```bash
supabase migration new add_task_notifications
```

O arquivo será criado em:

```text
supabase/migrations/
```

Edite o SQL e revise antes de aplicar.

Regras:

- não modificar silenciosamente migration já aplicada em produção;
- testar antes de aplicar remotamente;
- revisar impacto em RLS;
- evitar operações destrutivas sem estratégia;
- documentar migrations importantes.

---

## 15. Banco de desenvolvimento

Utilize dados fictícios ou contas de teste.

Evite:

- dumps de produção;
- dados pessoais reais;
- credenciais reais de usuários;
- tokens de produção.

O ambiente de desenvolvimento deve ser descartável sempre que possível.

---

## 16. Padrão de branches

Tipos recomendados:

```text
feature/
fix/
hotfix/
refactor/
docs/
test/
chore/
perf/
security/
ci/
build/
```

Exemplos:

```text
feature/task-notifications
fix/search-highlight
docs/update-architecture
security/session-validation
ci/flutter-build
```

---

## 17. Durante o desenvolvimento

Antes de modificar:

```bash
git status
```

Durante o desenvolvimento:

```bash
git diff
```

Antes de adicionar:

```bash
git status
```

Adicione somente arquivos relacionados à tarefa:

```bash
git add caminho/do/arquivo
```

Revise:

```bash
git diff --cached
```

---

## 18. Formatação

Para formatar:

```bash
dart format .
```

Antes de PR, valide sem alterar:

```bash
dart format --set-exit-if-changed .
```

Evite commits com centenas de alterações apenas de formatação que não pertencem
à tarefa.

---

## 19. Análise

Execute:

```bash
flutter analyze
```

Novos erros não devem ser introduzidos.

Warnings relevantes também devem ser avaliados.

---

## 20. Testes

Execute:

```bash
flutter test
```

Consulte:

```text
docs/TESTING.md
```

para a estratégia completa de testes.

---

## 21. Build local

Quando aplicável:

```bash
flutter build linux --debug
```

ou para release:

```bash
flutter build linux --release
```

Utilize a plataforma correspondente ao ambiente.

---

## 22. Commits

Padrão:

```text
tipo(escopo): descrição
```

Exemplos:

```text
feat(tasks): adiciona atribuição de tarefas
fix(search): corrige destaque dos resultados
refactor(brain): simplifica carregamento
docs(dev): atualiza configuração local
ci(repo): adiciona validação de build
```

Consulte também:

```text
.github/CONTRIBUTING.md
```

---

## 23. Antes do commit

Confira:

```bash
git status
git diff
```

Depois de adicionar:

```bash
git diff --cached
```

Verifique especialmente:

- `.env`;
- tokens;
- senhas;
- private keys;
- dumps;
- logs;
- builds;
- dados pessoais;
- arquivos temporários.

---

## 24. Pull Requests

Antes do PR:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Atualize sua branch com a base correta.

Exemplo:

```bash
git fetch origin
git rebase origin/main
```

ou, se a base for outra:

```bash
git rebase origin/dev-stable
```

Se a equipe preferir merge:

```bash
git merge origin/main
```

Depois:

```bash
git push -u origin sua-branch
```

---

## 25. GitHub CLI

Confirme autenticação:

```bash
gh auth status
```

O GitHub CLI pode ser usado para:

```bash
gh pr create
gh pr status
gh issue list
gh label list
```

---

## 26. Segurança

Nunca faça commit de:

```text
.env
*.pem
*.key
service-account*.json
database dumps
tokens
credentials
private keys
```

Se um secret for commitado por engano, removê-lo do arquivo não é suficiente.

Ele deve ser considerado comprometido e rotacionado.

---

## 27. Limpeza Flutter

Quando houver comportamento inconsistente de build:

```bash
flutter clean
flutter pub get
```

Não utilize `flutter clean` automaticamente para qualquer problema.

Primeiro tente identificar a causa.

---

## 28. Problemas comuns

### Dependência ausente

```bash
flutter pub get
```

### Ambiente Flutter

```bash
flutter doctor -v
```

### Branch incorreta

```bash
git branch --show-current
```

### Arquivos modificados inesperadamente

```bash
git status
git diff
```

### Dependências desatualizadas

```bash
flutter pub outdated
```

### Mudanças locais antes de trocar de branch

```bash
git status
```

Faça commit ou stash somente quando entender quais arquivos serão preservados.

---

## 29. Antes de pedir ajuda

Colete:

```bash
git status
git branch --show-current
flutter --version
flutter doctor -v
```

Quando necessário:

```bash
git log --oneline --decorate -n 10
```

Nunca publique secrets junto com logs.

---

## 30. Definition of Done

Uma tarefa não está pronta apenas porque funciona na máquina do autor.

Antes de concluir:

- [ ] código formatado;
- [ ] `flutter analyze` executado;
- [ ] testes executados;
- [ ] build validado quando aplicável;
- [ ] sem secrets;
- [ ] documentação atualizada;
- [ ] migration validada quando aplicável;
- [ ] segurança avaliada;
- [ ] PR aberto;
- [ ] CI aprovado;
- [ ] revisão concluída;
- [ ] feedback crítico resolvido.

---

## 31. Documentação relacionada

Consulte também:

```text
README.md
.github/CONTRIBUTING.md
docs/ARCHITECTURE.md
docs/TESTING.md
docs/SECURITY_ARCHITECTURE.md
docs/RELEASE.md
```

A documentação deve refletir o processo real do projeto.
