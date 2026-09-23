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

O projeto possui ambientes separados para desenvolvimento e produção.

Durante desenvolvimento normal, os colaboradores devem utilizar somente o
ambiente DEV.

A aplicação Flutter utiliza:

```text
app/.env
```

O repositório também deve possuir:

```text
app/.env.example
```

O `.env.example` serve apenas como referência de estrutura.

Exemplo:

```env
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
```

Para criar o arquivo local:

```bash
cd app
cp .env.example .env
```

Depois, preencha o `.env` com as configurações do ambiente DEV.

---

## 11. Supabase DEV oficial

O seguinte projeto Supabase é destinado ao ambiente de desenvolvimento.

Ele pode ser utilizado pelos colaboradores para executar e testar o aplicativo
durante o desenvolvimento.

```env
SUPABASE_URL=https://unlsxswbdugdnywkgvzd.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_PeoQ1pPBpHQeKhIjJdi97A_Zc6vx5iz
```

O arquivo local:

```text
app/.env
```

pode ficar assim:

```env
SUPABASE_URL=https://unlsxswbdugdnywkgvzd.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_PeoQ1pPBpHQeKhIjJdi97A_Zc6vx5iz
```

Esse projeto deve ser tratado como ambiente:

```text
development
```

e não como produção.

---

## 12. Regras do ambiente DEV

O banco DEV existe para permitir:

- desenvolvimento;
- testes manuais;
- testes de migrations;
- testes de RLS;
- criação de contas fictícias;
- testes de sync;
- testes offline-first;
- testes de colaboração;
- testes de novas funcionalidades;
- validação antes de mudanças chegarem à produção.

Dados presentes nesse ambiente não devem ser considerados dados de produção.

Use preferencialmente:

- contas de teste;
- dados fictícios;
- arquivos de teste;
- informações sem valor real.

Evite utilizar:

- dados pessoais reais;
- contas reais de usuários;
- dumps de produção;
- tokens de produção;
- secrets de produção.

---

## 13. Ambiente de produção

O ambiente de produção deve permanecer separado do ambiente DEV.

Fluxo conceitual:

```text
DESENVOLVIMENTO

Flutter local
    ↓
.env DEV
    ↓
Supabase DEV


PRODUÇÃO

Aplicativo publicado
    ↓
configuração PROD
    ↓
Supabase PROD
```

As credenciais e configurações de produção não devem ser adicionadas a este
documento.

O acesso ao ambiente PROD deve ser restrito às pessoas e sistemas que realmente
necessitam dele.

---

## 14. Chaves permitidas no cliente

O aplicativo Flutter pode utilizar uma chave pública destinada ao cliente, como:

```text
SUPABASE_PUBLISHABLE_KEY
```

Nunca coloque no Flutter, neste documento ou no repositório:

```text
service_role
secret key
database password
private key
access token administrativo
refresh token
senha de usuário
```

A `service_role` possui privilégios elevados e nunca deve ser distribuída dentro
do aplicativo cliente.

---

## 15. `.env` e Git

O arquivo:

```text
.env
```

deve permanecer ignorado pelo Git.

Configuração recomendada no `.gitignore`:

```gitignore
.env
.env.*
!.env.example
```

Assim:

```text
.env
→ não versionado

.env.development
→ não versionado, se utilizado

.env.production
→ não versionado

.env.example
→ versionado
```

Confirme:

```bash
git status
```

O `.env` real não deve aparecer como arquivo pronto para commit.

---

## 16. Ambientes

O projeto deve manter separação entre:

```text
development
staging
production
```

quando cada ambiente estiver disponível.

Atualmente, desenvolvimento deve utilizar o Supabase DEV documentado neste
arquivo.

Não utilize o banco de produção durante desenvolvimento normal.

Cada colaborador deve utilizar somente as credenciais necessárias ao ambiente em
que está trabalhando.

---

## 17. Supabase

O projeto já inicializado normalmente possui:

```text
supabase/config.toml
```

Portanto, não execute:

```bash
supabase init
```

novamente sem necessidade.

Confirme:

```bash
ls supabase/
```

---

## 18. Identificando o projeto DEV

A URL configurada para desenvolvimento é:

```text
https://unlsxswbdugdnywkgvzd.supabase.co
```

O `project-ref` correspondente é:

```text
unlsxswbdugdnywkgvzd
```

Para vincular o Supabase CLI ao projeto DEV:

```bash
supabase link --project-ref unlsxswbdugdnywkgvzd
```

Esse comando pode solicitar autenticação ou credenciais adicionais dependendo da
configuração da CLI.

O acesso administrativo ao projeto Supabase deve continuar controlado
separadamente.

---

## 19. Supabase local

O Supabase remoto DEV e o Supabase executado localmente são conceitos
diferentes.

### Supabase DEV remoto

```text
https://unlsxswbdugdnywkgvzd.supabase.co
```

Utilizado para:

- colaboração;
- desenvolvimento compartilhado;
- testes entre máquinas;
- sync;
- integração do aplicativo.

### Supabase local

Executado através de Docker na máquina do desenvolvedor.

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

O Supabase local é útil principalmente para testar migrations e alterações de
banco antes de aplicá-las no ambiente DEV compartilhado.

---

## 20. Fluxo recomendado de banco

Para mudanças estruturais importantes:

```text
Criar migration
      ↓
Supabase local
      ↓
Testar
      ↓
Revisar SQL
      ↓
Revisar RLS
      ↓
Aplicar no DEV
      ↓
Testar aplicativo
      ↓
Pull Request
      ↓
Review
      ↓
Produção posteriormente
```

Evite criar alterações diretamente em produção sem passar pelas etapas
anteriores.

---

## 21. Migrations

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

## 22. Banco de desenvolvimento

Utilize dados fictícios ou contas de teste.

Evite:

- dumps de produção;
- dados pessoais reais;
- credenciais reais de usuários;
- tokens de produção.

O ambiente de desenvolvimento deve ser descartável sempre que possível.

Antes de executar scripts destrutivos, confirme que está conectado ao projeto
correto.

---

## 23. Confirmando ambiente antes de mudanças críticas

Antes de executar comandos que alteram banco remoto, confirme:

```bash
supabase status
```

e revise a configuração utilizada.

Para operações importantes, confirme também que o `project-ref` corresponde ao
DEV:

```text
unlsxswbdugdnywkgvzd
```

Nunca execute uma migration destrutiva assumindo que o ambiente conectado é DEV
sem verificar.

---

## 24. Padrão de branches

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

## 25. Durante o desenvolvimento

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

## 26. Formatação

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

## 27. Análise

Execute:

```bash
flutter analyze
```

Novos erros não devem ser introduzidos.

Warnings relevantes também devem ser avaliados.

---

## 28. Testes

Execute:

```bash
flutter test
```

Consulte:

```text
docs/TESTING.md
```

para a estratégia completa de testes.

Quando disponível, consulte também:

```text
docs/TESTING_ROADMAP.md
```

para os cenários que ainda precisam ser validados.

---

## 29. Build local

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

## 30. Commits

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

## 31. Antes do commit

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
- service role keys;
- dumps;
- logs;
- builds;
- dados pessoais;
- arquivos temporários.

---

## 32. Pull Requests

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

## 33. GitHub CLI

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

## 34. Segurança

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
service_role keys
database passwords
```

Se um secret for commitado por engano, removê-lo do arquivo não é suficiente.

Ele deve ser considerado comprometido e rotacionado.

---

## 35. Sobre a Publishable Key DEV

A chave:

```text
SUPABASE_PUBLISHABLE_KEY
```

utilizada pelo aplicativo cliente não deve ser confundida com uma credencial
administrativa.

A segurança dos dados não deve depender de esconder essa chave.

A proteção deve ocorrer principalmente através de:

- autenticação;
- autorização;
- Row Level Security;
- políticas adequadas;
- validações no backend;
- isolamento entre usuários.

Por isso, qualquer tabela contendo dados privados deve possuir políticas RLS
adequadas.

---

## 36. Limpeza Flutter

Quando houver comportamento inconsistente de build:

```bash
flutter clean
flutter pub get
```

Não utilize `flutter clean` automaticamente para qualquer problema.

Primeiro tente identificar a causa.

---

## 37. Problemas comuns

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

### Ambiente Supabase incorreto

Confirme que o aplicativo está utilizando:

```text
SUPABASE_URL=https://unlsxswbdugdnywkgvzd.supabase.co
```

durante o desenvolvimento compartilhado.

### Mudanças locais antes de trocar de branch

```bash
git status
```

Faça commit ou stash somente quando entender quais arquivos serão preservados.

---

## 38. Onboarding de um novo colaborador

Fluxo simplificado:

```text
Clonar repositório
      ↓
Selecionar branch correta
      ↓
cd app
      ↓
flutter pub get
      ↓
criar .env
      ↓
configurar Supabase DEV
      ↓
flutter doctor
      ↓
flutter run
```

Comandos:

```bash
git clone https://github.com/joao01020/ghost-core.git
cd ghost-core
git fetch --all --prune
cd app
flutter pub get
cp .env.example .env
```

No `.env`:

```env
SUPABASE_URL=https://unlsxswbdugdnywkgvzd.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_PeoQ1pPBpHQeKhIjJdi97A_Zc6vx5iz
```

Depois:

```bash
flutter doctor -v
flutter run
```

No Linux:

```bash
flutter run -d linux
```

No macOS:

```bash
flutter run -d macos
```

No Windows:

```powershell
flutter run -d windows
```

---

## 39. Antes de pedir ajuda

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

## 40. Definition of Done

Uma tarefa não está pronta apenas porque funciona na máquina do autor.

Antes de concluir:

- [ ] código formatado;
- [ ] `flutter analyze` executado;
- [ ] testes executados;
- [ ] build validado quando aplicável;
- [ ] ambiente DEV utilizado;
- [ ] sem secrets administrativos;
- [ ] documentação atualizada;
- [ ] migration validada quando aplicável;
- [ ] segurança avaliada;
- [ ] PR aberto;
- [ ] CI aprovado;
- [ ] revisão concluída;
- [ ] feedback crítico resolvido.

---

## 41. Documentação relacionada

Consulte também:

```text
README.md
.github/CONTRIBUTING.md
docs/ARCHITECTURE.md
docs/TESTING.md
docs/TESTING_ROADMAP.md
docs/SECURITY_ARCHITECTURE.md
docs/RELEASE.md
```

A documentação deve refletir o processo real do projeto.

---

## 42. Regra principal de ambientes

Durante desenvolvimento:

```text
Colaboradores
     ↓
Supabase DEV
```

Em produção:

```text
Aplicativo publicado
     ↓
Supabase PROD
```

Não misture os ambientes.

O ambiente DEV existe para permitir desenvolvimento, testes e erros controlados
sem colocar os dados de produção em risco.
