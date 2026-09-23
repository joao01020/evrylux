# Pull Request

## Resumo

Descreva de forma objetiva o que este Pull Request altera.

Exemplo:

- adiciona notificações para tarefas atribuídas;
- corrige destaque inconsistente na pesquisa;
- melhora o carregamento inicial do dashboard.

---

## Motivação

Explique por que esta alteração é necessária.

- Qual problema está sendo resolvido?
- Qual comportamento anterior estava incorreto ou incompleto?
- Existe uma issue relacionada?

---

## O que foi alterado

Liste as principais mudanças realizadas.

-
-
-

---

## Como testar

Descreva um passo a passo simples para validar esta alteração.

1.
2.
3.

---

## Resultado esperado

Explique o comportamento esperado após aplicar este PR.

---

## Evidências

Quando houver mudança visual, inclua:

- screenshots;
- GIF;
- vídeo curto;
- logs relevantes.

> Não publique tokens, credenciais, dados pessoais ou informações sensíveis.

---

## Issue relacionada

Use uma das opções abaixo, quando aplicável:

```text
Closes #123
Fixes #123
Related to #123
```

---

## Impacto

Marque o que esta alteração afeta:

- [ ] Interface
- [ ] Banco de dados
- [ ] Autenticação
- [ ] Sincronização
- [ ] API
- [ ] Segurança
- [ ] Performance
- [ ] Build
- [ ] Infraestrutura
- [ ] Documentação
- [ ] Testes
- [ ] Outro

Se necessário, explique:

---

## Nível de risco

Marque a opção mais adequada:

- [ ] Baixo — alteração isolada e de baixo impacto
- [ ] Médio — altera fluxo existente ou componente importante
- [ ] Alto — afeta autenticação, banco, sync, segurança, criptografia ou dados
      do usuário

Explique quando necessário:

---

## Breaking changes

- [ ] Este PR não introduz breaking changes.
- [ ] Este PR introduz breaking changes.

Se houver breaking changes, explique:

- o que deixa de ser compatível;
- quem será impactado;
- como migrar;
- se existe plano de rollback.

---

## Banco de dados / migrations

- [ ] Este PR não altera o banco de dados.
- [ ] Este PR adiciona ou altera migrations.
- [ ] Este PR exige configuração manual após o merge.

Se houver migration, explique:

```text
Migration:
Impacto:
Rollback:
```

Nunca altere silenciosamente uma migration já aplicada em produção.

---

## Configuração / ambiente

- [ ] Não exige alteração de `.env`.
- [ ] Exige novas variáveis de ambiente.
- [ ] Exige alteração de configuração externa.

Se houver nova variável de ambiente, documente apenas o nome:

```text
EXEMPLO_VARIAVEL=
```

Nunca inclua o valor real de secrets.

---

## Segurança

Marque quando aplicável:

- [ ] Esta alteração não afeta segurança.
- [ ] Esta alteração afeta autenticação.
- [ ] Esta alteração afeta autorização/RLS.
- [ ] Esta alteração afeta criptografia/E2EE.
- [ ] Esta alteração afeta armazenamento de dados.
- [ ] Esta alteração afeta sync.
- [ ] Esta alteração adiciona ou altera permissões.
- [ ] Esta alteração adiciona dependência externa.

Se houver impacto de segurança, explique:

---

## Testes realizados

- [ ] `flutter pub get`
- [ ] `dart format --set-exit-if-changed .`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Teste manual do fluxo alterado
- [ ] Teste em mais de uma plataforma, quando aplicável
- [ ] Teste offline, quando aplicável
- [ ] Teste de sincronização, quando aplicável

Plataformas testadas:

- [ ] Linux
- [ ] macOS
- [ ] Windows
- [ ] Android
- [ ] iOS
- [ ] Web

---

## Regressões verificadas

Informe quais fluxos relacionados foram testados para garantir que continuam
funcionando.

Exemplo:

- criação;
- edição;
- exclusão;
- pesquisa;
- sync;
- autenticação;
- carregamento inicial.

---

## Checklist final

Antes de solicitar revisão:

- [ ] Minha branch contém apenas mudanças relacionadas à tarefa.
- [ ] Revisei meu próprio `git diff`.
- [ ] Não incluí `.env`, tokens, senhas ou credenciais.
- [ ] Não incluí arquivos gerados ou temporários desnecessários.
- [ ] O projeto compila.
- [ ] Os testes aplicáveis passam.
- [ ] `flutter analyze` não introduz novos erros.
- [ ] Atualizei documentação quando necessário.
- [ ] Adicionei screenshots quando houve mudança visual.
- [ ] Expliquei claramente como testar.
- [ ] Relacionei a issue correspondente, quando aplicável.
- [ ] Avaliei impacto em banco, migrations, sync e segurança.
- [ ] O PR está pronto para revisão.

---

## Pontos para o revisor

Informe partes que merecem atenção especial:

-
-
-

---

## Observações adicionais

Inclua qualquer contexto que possa ajudar na revisão.
