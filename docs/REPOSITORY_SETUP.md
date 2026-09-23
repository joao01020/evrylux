# Estrutura `.github`

Este documento descreve a configuração utilizada na pasta `.github` e os
recursos de colaboração, automação e segurança do repositório.

---

## Estrutura

```text
.github/
├── CODE_OF_CONDUCT.md
├── CODEOWNERS
├── CONTRIBUTING.md
├── PULL_REQUEST_TEMPLATE.md
├── SECURITY.md
├── dependabot.yml
│
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml
│   ├── feature_request.yml
│   └── config.yml
│
└── workflows/
    ├── flutter_ci.yml
    ├── tests.yml
    └── security.yml
```

---

## Templates de issues

Os templates ficam em:

```text
.github/ISSUE_TEMPLATE/
```

### `bug_report.yml`

Utilizado para reportar bugs de forma estruturada.

Solicita informações como:

- descrição;
- comportamento esperado;
- passos para reproduzir;
- frequência;
- plataforma;
- versão, branch ou commit;
- logs;
- evidências;
- contexto adicional.

### `feature_request.yml`

Utilizado para propostas de novas funcionalidades.

O objetivo é registrar:

- problema;
- solução proposta;
- fluxo esperado;
- área afetada;
- critérios de aceite;
- alternativas consideradas.

### `config.yml`

Configura o comportamento da página de criação de issues.

O projeto direciona vulnerabilidades para o canal privado:

```text
https://github.com/joao01020/ghost-core/security/advisories/new
```

Vulnerabilidades não devem ser abertas como issues públicas.

---

## Pull Requests

O arquivo:

```text
.github/PULL_REQUEST_TEMPLATE.md
```

define o padrão esperado para Pull Requests.

Ele inclui informações sobre:

- resumo;
- motivação;
- alterações;
- testes;
- impacto;
- risco;
- breaking changes;
- migrations;
- segurança;
- regressões;
- checklist para revisão.

---

## CODEOWNERS

O arquivo:

```text
.github/CODEOWNERS
```

define responsáveis por revisar áreas específicas do repositório.

Exemplos:

```text
/app/
/website/
/supabase/
/.github/
/docs/
/scripts/
```

Os usernames configurados devem corresponder a usuários reais do GitHub com
acesso adequado ao repositório.

---

## Dependabot

O arquivo:

```text
.github/dependabot.yml
```

configura verificações periódicas de dependências.

Atualmente são monitorados:

- pacotes Dart/Flutter em `/app`;
- GitHub Actions.

O Dependabot pode abrir Pull Requests automaticamente quando encontrar versões
mais recentes.

Esses PRs devem passar pelos mesmos testes e revisões utilizados nas demais
mudanças.

---

## Aplicação Flutter

Os workflows assumem que o projeto Flutter está localizado em:

```text
app/
```

Estrutura esperada:

```text
ghost-core/
└── app/
    ├── pubspec.yaml
    ├── lib/
    ├── test/
    └── ...
```

Por isso, os workflows utilizam:

```yaml
working-directory: app
```

Se a localização do aplicativo Flutter mudar, os workflows também deverão ser
atualizados.

---

## Flutter CI

O workflow:

```text
.github/workflows/flutter_ci.yml
```

executa verificações automáticas como:

```text
flutter pub get
dart format
flutter analyze
flutter test
```

O objetivo é detectar problemas antes do merge.

---

## Build Check

O workflow:

```text
.github/workflows/tests.yml
```

valida a compilação do aplicativo Flutter para Linux.

Ele é executado quando mudanças relevantes forem realizadas em:

```text
app/**
```

ou no próprio workflow.

Esse check ajuda a detectar problemas que não aparecem apenas no
`flutter analyze`.

---

## Security Checks

O workflow:

```text
.github/workflows/security.yml
```

executa verificações relacionadas a segurança e dependências.

Entre elas:

- Dependency Review;
- Gitleaks;
- auditoria das dependências Flutter.

O Gitleaks procura padrões que possam representar credenciais ou secrets
acidentalmente adicionados ao Git.

Qualquer alerta deve ser analisado antes de concluir que existe uma credencial
real exposta.

---

## GitHub Security

Recomenda-se manter habilitados os recursos disponíveis no repositório:

- Private Vulnerability Reporting;
- Dependabot Alerts;
- Dependabot Security Updates;
- secret scanning, quando disponível;
- branch protection ou rulesets para `main`.

---

## Proteção da `main`

A branch `main` deve ser protegida conforme o fluxo de colaboração adotado.

Configuração recomendada:

- exigir Pull Request antes do merge;
- impedir push direto;
- exigir pelo menos uma aprovação;
- exigir resolução das conversas;
- exigir status checks;
- bloquear force push;
- bloquear exclusão da branch.

Checks importantes podem incluir:

```text
Analyze and test
Linux desktop build
Secret scan
Dependency review
```

Os nomes exatos dependem dos jobs configurados nos workflows.

---

## Fluxo de colaboração

```text
Issue / tarefa
      ↓
Criar branch
      ↓
Desenvolver
      ↓
Testar localmente
      ↓
Commit
      ↓
Push
      ↓
Pull Request
      ↓
GitHub Actions
      ↓
Code Review
      ↓
Aprovação
      ↓
Merge
```

---

## Arquivos relacionados

A configuração do repositório deve ser lida em conjunto com:

```text
.github/CONTRIBUTING.md
.github/CODE_OF_CONDUCT.md
.github/SECURITY.md
docs/TESTING.md
docs/SECURITY_ARCHITECTURE.md
docs/RELEASE.md
```

Cada arquivo cobre uma parte diferente do processo.

---

## Manutenção

Sempre que a estrutura `.github` mudar, revise este documento.

Exemplos:

- novo workflow;
- mudança da branch principal;
- novo template;
- alteração do processo de segurança;
- alteração do diretório Flutter;
- mudanças no Dependabot;
- novos responsáveis no CODEOWNERS;
- novos status checks obrigatórios.

Este documento deve refletir a configuração real do repositório.

Não mantenha instruções antigas apenas porque já estiveram corretas
anteriormente.
