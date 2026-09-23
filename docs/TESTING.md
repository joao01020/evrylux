# Estratégia de Testes

## 1. Objetivo

Os testes devem reduzir regressões, aumentar a confiança nas mudanças e permitir
que o projeto evolua sem quebrar funcionalidades existentes.

Nem todo código precisa do mesmo nível de teste.

A prioridade deve ser proporcional ao risco da funcionalidade.

Áreas relacionadas a dados, autenticação, autorização, sincronização e
criptografia devem receber atenção especial.

---

## 2. Princípios

Os testes devem ser:

- determinísticos;
- independentes;
- reproduzíveis;
- rápidos sempre que possível;
- fáceis de compreender;
- focados em comportamento;
- executáveis localmente e no CI.

Evite testes que dependam desnecessariamente:

- da ordem de execução;
- de conexão externa;
- de dados reais;
- de horário exato;
- do estado deixado por outro teste.

---

## 3. Pirâmide de testes

Estratégia recomendada:

```text
       E2E
      /   \
 Integration
   /       \
Widget Tests
 /         \
Unit Tests
```

A maior quantidade deve estar nos testes rápidos e específicos.

Testes de integração e E2E devem ser reservados para fluxos realmente
importantes.

---

## 4. Testes unitários

Indicados para:

- regras de negócio;
- parsers;
- validações;
- utilitários;
- repositories isolados;
- controllers;
- serviços;
- algoritmos de sync;
- regras de conflito;
- lógica de criptografia;
- transformação de dados.

Execute:

```bash
flutter test
```

Os testes normalmente ficam em:

```text
app/test/
```

Exemplo:

```text
app/
└── test/
    ├── brain/
    ├── sync/
    ├── auth/
    └── security/
```

---

## 5. Widget tests

Utilize Widget Tests quando for importante validar:

- renderização;
- interação;
- estados vazios;
- loading;
- erros;
- validação de formulário;
- navegação;
- componentes reutilizáveis;
- comportamento após eventos do usuário.

Exemplos:

```text
concept_form_test.dart
brain_search_test.dart
task_card_test.dart
```

Não tente reproduzir o aplicativo inteiro em um Widget Test.

---

## 6. Testes de integração

Testes de integração devem validar fluxos que atravessam múltiplas camadas.

Exemplos:

- criar conceito;
- persistir localmente;
- restaurar após reiniciar;
- sincronizar;
- editar;
- excluir;
- processar tombstone;
- atribuir tarefa;
- receber notificação;
- recuperar sessão.

Quando o projeto utilizar `integration_test`, os testes podem ficar em:

```text
app/integration_test/
```

---

## 7. Testes E2E

Testes end-to-end devem cobrir apenas jornadas importantes.

Exemplos:

```text
Login
  ↓
Dashboard
  ↓
Criar conhecimento
  ↓
Persistir
  ↓
Fechar aplicativo
  ↓
Abrir novamente
  ↓
Conhecimento continua disponível
```

E2E é mais caro e lento que testes unitários.

Não utilize E2E como substituto para testes menores.

---

## 8. Fluxos críticos

Possuem prioridade alta:

- autenticação;
- autorização;
- RLS;
- persistência local;
- sincronização;
- criação;
- edição;
- exclusão;
- tombstones;
- E2EE;
- migrations;
- recuperação após falha de rede;
- recuperação de sessão;
- isolamento entre usuários.

Uma regressão nessas áreas pode causar:

- perda de dados;
- vazamento de dados;
- inconsistência;
- indisponibilidade;
- acesso indevido.

---

## 9. Testes offline

Cenários mínimos:

1. iniciar o aplicativo com dados previamente armazenados;
2. remover conectividade;
3. consultar dados locais;
4. criar novo conteúdo;
5. editar conteúdo;
6. excluir conteúdo;
7. fechar e abrir novamente;
8. recuperar conectividade;
9. sincronizar;
10. verificar ausência de duplicações;
11. verificar ausência de perda de dados.

Também valide:

- sync interrompido;
- retry;
- aplicativo encerrado durante operação;
- conectividade instável.

---

## 10. Testes de sincronização

O mecanismo de sync deve possuir testes específicos.

Cenários importantes:

- criação local;
- atualização local;
- exclusão local;
- criação remota;
- atualização remota;
- exclusão remota;
- retry;
- operação duplicada;
- conexão perdida;
- reconexão;
- tombstone;
- operação já sincronizada.

Sempre que possível, operações devem ser idempotentes.

---

## 11. Testes de conflito

Quando versões diferentes do mesmo dado existirem simultaneamente:

- validar a política de conflito;
- garantir que dados não sejam descartados silenciosamente;
- testar timestamps ou versões;
- verificar comportamento offline;
- registrar decisões relevantes;
- criar teste de regressão para bugs encontrados.

A política de conflito deve ser documentada.

---

## 12. Banco de dados e RLS

Para tabelas contendo dados por usuário, teste pelo menos:

```text
Usuário A
→ pode acessar seus próprios dados

Usuário B
→ não pode acessar dados privados do usuário A

Usuário A
→ não pode alterar dados pertencentes ao usuário B

Usuário anônimo
→ não acessa operações protegidas
```

Valide separadamente:

- `SELECT`;
- `INSERT`;
- `UPDATE`;
- `DELETE`.

Não considere RLS testado apenas porque a interface não mostra os dados.

A tentativa deve ser feita diretamente contra a camada de dados quando possível.

---

## 13. Migrations

Migrations relevantes devem ser testadas.

Valide:

- aplicação da migration;
- schema final;
- dados existentes;
- constraints;
- índices;
- policies;
- compatibilidade com código existente.

Nunca teste migrations usando dados reais de produção sem autorização e proteção
adequada.

---

## 14. Criptografia

Testar:

- encrypt → decrypt;
- nonce/IV válido;
- nonce/IV diferente quando exigido;
- payload corrompido;
- chave incorreta;
- dados incompletos;
- versão do formato;
- migração de formato;
- recuperação de erro;
- ausência de plaintext persistido indevidamente.

Nunca coloque chaves reais de produção nos testes.

Utilize dados e chaves exclusivamente destinados ao ambiente de teste.

---

## 15. Autenticação

Testar:

- login válido;
- login inválido;
- logout;
- sessão expirada;
- token inválido;
- recuperação de sessão;
- usuário removido;
- estado autenticado após reiniciar o aplicativo.

---

## 16. Autorização

Autenticação não significa autorização.

Teste situações como:

```text
Usuário autenticado
+
recurso pertencente a outro usuário
=
acesso negado
```

Mudanças relacionadas a autorização devem receber atenção especial durante
revisão.

---

## 17. Dados de teste

Nunca utilizar dados pessoais reais quando dados fictícios forem suficientes.

Prefira:

```text
user-a@example.test
user-b@example.test
```

e dados gerados especificamente para testes.

Não coloque nos fixtures:

- tokens reais;
- senhas reais;
- chaves privadas;
- dados pessoais;
- credenciais de produção.

---

## 18. Testes de regressão

Todo bug relevante corrigido deve receber um teste de regressão quando
tecnicamente viável.

Fluxo recomendado:

```text
Bug identificado
      ↓
Teste reproduz o problema
      ↓
Teste falha
      ↓
Correção implementada
      ↓
Teste passa
      ↓
Regressão protegida
```

Isso reduz a chance do mesmo bug retornar posteriormente.

---

## 19. Testes antes de Pull Request

A partir da pasta `app`:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Quando houver alteração de dependências:

```bash
flutter pub get
```

Quando aplicável:

```bash
flutter build linux --debug
```

Também execute manualmente o fluxo alterado quando testes automatizados não
forem suficientes.

---

## 20. Formatação

Antes de abrir um PR:

```bash
dart format --set-exit-if-changed .
```

Se precisar formatar:

```bash
dart format .
```

Mudanças de formatação não relacionadas devem ser evitadas em PRs grandes, pois
dificultam revisão.

---

## 21. Nomenclatura

Arquivos de teste devem possuir nomes claros.

Exemplos:

```text
brain_repository_test.dart
sync_controller_test.dart
task_assignment_test.dart
encryption_service_test.dart
session_restore_test.dart
brain_search_test.dart
```

O nome deve indicar o componente ou comportamento testado.

---

## 22. Estrutura recomendada

Quando o volume de testes crescer:

```text
test/
├── auth/
├── brain/
├── database/
├── repositories/
├── security/
├── sync/
├── tasks/
└── widgets/
```

A estrutura pode acompanhar os módulos reais da aplicação.

---

## 23. Mocking

Mocks devem isolar dependências externas.

Utilize mocks para:

- backend;
- storage;
- network;
- clock;
- serviços externos.

Evite mocks tão complexos que reproduzam novamente toda a implementação real.

Se o mock possuir mais lógica que o componente testado, reavalie a estratégia.

---

## 24. Testes instáveis

Testes que falham aleatoriamente não devem ser ignorados.

Quando um teste for flaky:

1. identifique a causa;
2. corrija dependência de tempo, ordem ou ambiente;
3. evite simplesmente executar novamente até passar;
4. documente limitações temporárias quando necessário.

Um teste instável reduz a confiança no CI.

---

## 25. Cobertura

Cobertura percentual é uma métrica auxiliar.

Ela não deve ser utilizada isoladamente para medir qualidade.

Um projeto pode possuir:

```text
90% de cobertura
```

e ainda deixar um fluxo crítico sem teste.

Mais importante:

- autenticação está testada?
- autorização está testada?
- sync está testado?
- RLS está testado?
- criptografia está testada?
- bugs importantes possuem regressão?

---

## 26. CI

Pull Requests devem executar automaticamente verificações relevantes.

Exemplos:

```text
format
   ↓
analyze
   ↓
tests
   ↓
build
   ↓
security checks
```

PR com check crítico falhando não deve ser integrado sem justificativa técnica
documentada.

---

## 27. Quando criar novos testes

Considere adicionar teste quando:

- criar funcionalidade importante;
- corrigir bug;
- alterar regra de negócio;
- alterar sync;
- modificar RLS;
- alterar autenticação;
- alterar criptografia;
- criar migration importante;
- modificar persistência;
- encontrar regressão.

---

## 28. Definition of Done

Uma mudança crítica não deve ser considerada concluída somente porque funciona
manualmente.

Quando aplicável:

- [ ] testes foram adicionados ou atualizados;
- [ ] testes existentes continuam passando;
- [ ] regressões relacionadas foram verificadas;
- [ ] `flutter analyze` passa;
- [ ] CI passa;
- [ ] comportamento offline foi avaliado;
- [ ] autorização foi avaliada;
- [ ] dados sensíveis não aparecem nos testes.

---

## 29. Critério de qualidade

O objetivo da estratégia de testes não é atingir um número arbitrário.

O objetivo é conseguir alterar o sistema com confiança.

Perguntas importantes:

- uma mudança pequena pode quebrar dados existentes?
- conseguiremos detectar isso antes da release?
- um usuário consegue acessar dados de outro?
- um bug corrigido pode reaparecer silenciosamente?
- o aplicativo continua funcionando offline?
- uma atualização do banco preserva dados existentes?

Se essas respostas puderem ser verificadas automaticamente, o projeto se torna
progressivamente mais seguro para evoluir.
