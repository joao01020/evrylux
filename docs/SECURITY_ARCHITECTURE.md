# Arquitetura de Segurança

## 1. Objetivo

Este documento descreve princípios, fronteiras de confiança e controles técnicos
utilizados para reduzir riscos no projeto.

Ele não substitui:

```text
.github/SECURITY.md
```

que define como vulnerabilidades devem ser reportadas.

Este documento trata da arquitetura interna de segurança do sistema.

---

## 2. Princípios

O projeto deve seguir, quando aplicável:

- least privilege;
- defense in depth;
- secure by default;
- deny by default;
- segregação de ambientes;
- secrets fora do código;
- validação no servidor;
- minimização de dados;
- autenticação independente de autorização;
- redução da superfície de ataque.

Nenhum controle individual deve ser considerado proteção absoluta.

---

## 3. Modelo de confiança

O aplicativo cliente deve ser considerado um ambiente que pode ser inspecionado
ou modificado.

Portanto:

```text
Flutter Client
     │
     │ não é confiável para decisões de autorização
     ▼
Backend / Supabase
     │
     │ aplica regras de acesso
     ▼
Database
```

Não confie no cliente para garantir:

- identidade;
- ownership;
- permissões;
- valores administrativos;
- regras críticas de negócio.

O cliente pode auxiliar na experiência do usuário, mas decisões críticas devem
ser validadas no backend.

---

## 4. Fronteiras de confiança

Principais fronteiras:

```text
Usuário
   ↓
Flutter App
   ↓
Rede
   ↓
Supabase / Backend
   ↓
PostgreSQL
```

Cada fronteira deve ser tratada como potencial ponto de entrada de dados não
confiáveis.

Dados recebidos devem ser:

- validados;
- autorizados;
- limitados;
- tratados conforme o contexto.

---

## 5. Ameaças principais

Exemplos de ameaças consideradas:

- acesso indevido a dados de outro usuário;
- bypass de autorização;
- roubo de sessão;
- vazamento de secrets;
- exposição de dados em logs;
- manipulação de sync;
- replay;
- alteração de dados locais;
- corrupção de dados;
- migrations inseguras;
- dependências comprometidas;
- configuração incorreta de RLS;
- exposição acidental de plaintext;
- uso indevido de credenciais administrativas.

Este documento deve evoluir conforme novas ameaças forem identificadas.

---

## 6. Classificação de dados

Dados devem ser avaliados conforme sua sensibilidade.

Uma classificação simples pode utilizar:

### Público

Informações que podem ser publicadas sem impacto relevante.

### Interno

Informações destinadas à operação do projeto.

### Sensível

Informações que exigem proteção adicional.

Exemplos:

- dados pessoais;
- conteúdo privado do usuário;
- tokens;
- informações de autenticação.

### Secret

Informações que nunca devem ser expostas publicamente.

Exemplos:

- service role key;
- private keys;
- passwords;
- credenciais administrativas.

Controles devem ser proporcionais à classificação.

---

## 7. Autenticação

Autenticação identifica o usuário.

Ela não substitui autorização.

Após autenticação, cada operação ainda deve verificar se aquele usuário possui
permissão para acessar o recurso solicitado.

Fluxo conceitual:

```text
Credencial
   ↓
Autenticação
   ↓
Identidade
   ↓
Autorização
   ↓
Recurso
```

---

## 8. Sessões

Sessões devem ser tratadas como informações sensíveis.

Não registrar em logs:

- access tokens;
- refresh tokens;
- cookies de sessão;
- headers de autorização.

Sessões expiradas ou inválidas devem ser rejeitadas corretamente.

Logout deve remover ou invalidar o estado local necessário.

---

## 9. Autorização

Regras críticas devem existir no backend.

Não confiar somente em verificações da interface como:

```dart
if (currentUser.id == ownerId) {
  // permitir alteração
}
```

Esse tipo de validação pode melhorar a interface, mas não deve ser a única
barreira.

O backend também deve validar acesso.

---

## 10. Row Level Security

Tabelas contendo dados privados por usuário devem utilizar RLS quando aplicável.

Exemplo conceitual:

```sql
auth.uid() = user_id
```

As policies devem ser avaliadas separadamente para:

```text
SELECT
INSERT
UPDATE
DELETE
```

Não assuma que uma policy de leitura protege automaticamente escrita.

RLS deve ser testada com usuários diferentes.

---

## 11. Ownership

Nunca aceite `user_id` enviado pelo cliente como prova de ownership.

Exemplo inseguro conceitualmente:

```text
cliente envia:

user_id = "usuario-a"

backend assume:

"portanto pertence ao usuário A"
```

O backend deve relacionar a operação com a identidade autenticada.

---

## 12. Secrets

Secrets nunca devem ser armazenados em:

- Git;
- commits antigos;
- screenshots;
- logs;
- documentação pública;
- código Flutter;
- issues;
- Pull Requests;
- fixtures de teste;
- arquivos de exemplo.

Utilize mecanismos próprios para secrets em cada ambiente.

---

## 13. Aplicações cliente e secrets

Aplicações distribuídas ao usuário não conseguem manter permanentemente secreto
um valor embutido no binário.

Portanto, não colocar no aplicativo Flutter:

- service role keys;
- chaves administrativas;
- credenciais privadas permanentes;
- private keys do backend;
- tokens administrativos.

Operações privilegiadas devem permanecer no backend.

---

## 14. Configuração pública

Nem toda chave encontrada no aplicativo é necessariamente um secret.

Configurações destinadas ao cliente podem existir no aplicativo quando foram
projetadas para isso.

Mesmo nesses casos, a segurança deve depender de:

- autenticação;
- autorização;
- RLS;
- policies;
- limites do backend.

Nunca trate uma chave presente no cliente como barreira de segurança.

---

## 15. E2EE

Quando dados forem protegidos por E2EE:

```text
plaintext
   ↓
criptografia no cliente
   ↓
ciphertext
   ↓
sync
   ↓
backend
```

O backend deve receber ciphertext quando a arquitetura exigir confidencialidade
ponta a ponta.

No retorno:

```text
backend
   ↓
ciphertext
   ↓
cliente
   ↓
decrypt
   ↓
plaintext
```

---

## 16. Chaves criptográficas

Chaves criptográficas devem ser tratadas separadamente dos dados protegidos.

Requisitos:

- não registrar em logs;
- não colocar no Git;
- não enviar sem proteção;
- permitir versionamento do formato;
- permitir rotação quando aplicável;
- proteger armazenamento local.

Perda de chave pode significar perda de acesso aos dados E2EE.

Esse risco deve ser considerado explicitamente no desenho do sistema.

---

## 17. Criptografia

Não implemente algoritmos criptográficos próprios.

Utilize:

- bibliotecas mantidas;
- primitivas modernas;
- algoritmos autenticados;
- geração segura de nonce/IV;
- geração segura de chaves.

A implementação deve possuir testes específicos.

---

## 18. Armazenamento local

Dados locais sensíveis devem ser avaliados quanto a:

- criptografia;
- permissões;
- backups;
- arquivos temporários;
- caches;
- logs;
- exportação;
- restauração.

Dados considerados removidos da UI podem continuar existindo em caches ou
backups.

Isso deve ser considerado quando houver requisitos de exclusão.

---

## 19. Sync

O sync deve verificar:

- identidade;
- ownership;
- versão;
- estado de exclusão;
- integridade;
- duplicação;
- autorização;
- replay quando relevante.

Operações devem ser idempotentes quando possível.

O sync não deve permitir que dados de um usuário sejam associados a outro devido
a campos manipulados pelo cliente.

---

## 20. Tombstones

Tombstones devem conter apenas as informações necessárias para propagar
exclusões.

Evite manter conteúdo sensível completo.

Exemplo conceitual:

```text
id
deleted_at
version
sync metadata
```

em vez de preservar todo o conteúdo excluído sem necessidade.

---

## 21. Migrations

Migrations podem afetar segurança.

Antes de aplicar uma migration:

- revisar RLS;
- revisar constraints;
- revisar defaults;
- revisar ownership;
- revisar dados existentes;
- avaliar operações destrutivas;
- testar em ambiente não produtivo.

Não altere silenciosamente uma migration já aplicada em produção.

---

## 22. Logging

Nunca registrar:

```text
Authorization header
access token
refresh token
password
encryption key
private key
service role key
plaintext sensível
```

Logs devem coletar somente o necessário para diagnóstico.

Quando possível, utilize identificadores técnicos em vez de conteúdo sensível.

---

## 23. Tratamento de erros

Mensagens internas podem possuir mais detalhes que mensagens apresentadas ao
usuário.

Evite revelar:

- stack traces internos;
- estrutura de banco;
- nomes de tabelas desnecessários;
- secrets;
- dados de outros usuários;
- detalhes de infraestrutura sem necessidade.

---

## 24. Dependências

Automatize quando possível:

- Dependabot;
- Dependency Review;
- secret scanning;
- atualização de GitHub Actions.

Novas dependências devem ser avaliadas quanto a:

- manutenção;
- reputação;
- licença;
- necessidade;
- permissões;
- histórico de vulnerabilidades;
- impacto na superfície de ataque.

Evite adicionar uma dependência grande para resolver um problema trivial.

---

## 25. GitHub Actions e CI/CD

Pipelines devem utilizar permissões mínimas.

Exemplo:

```yaml
permissions:
   contents: read
```

Conceda permissões adicionais apenas quando necessárias.

Actions de terceiros também fazem parte da cadeia de confiança do projeto e
devem ser revisadas.

---

## 26. Ambientes

Quando possível, mantenha separação entre:

```text
development
staging
production
```

Cada ambiente deve possuir credenciais próprias.

Credenciais de produção não devem ser utilizadas durante desenvolvimento comum.

---

## 27. Banco de desenvolvimento

Ambientes de desenvolvimento não devem utilizar dados pessoais reais sem
necessidade.

Prefira:

- dados fictícios;
- seeds;
- contas de teste;
- banco separado.

Isso reduz o impacto de erros durante desenvolvimento.

---

## 28. Backups

Backups podem conter os mesmos dados sensíveis presentes no sistema principal.

Portanto devem receber proteção adequada.

Considere:

- acesso;
- retenção;
- criptografia;
- restauração;
- exclusão;
- isolamento entre ambientes.

Uma política de backup não está completa sem teste de restauração.

---

## 29. Arquivos e uploads

Uploads devem ser considerados entrada não confiável.

Quando aplicável, valide:

- tamanho;
- tipo;
- extensão;
- nome;
- ownership;
- permissões;
- local de armazenamento.

O nome fornecido pelo usuário não deve ser utilizado cegamente para decisões de
segurança.

---

## 30. Notificações

Notificações podem expor informações em:

- tela bloqueada;
- sistema operacional;
- histórico;
- logs.

Evite enviar conteúdo sensível desnecessário no texto da notificação.

Prefira mensagens como:

```text
Você recebeu uma nova tarefa.
```

quando o conteúdo detalhado não precisa aparecer fora do aplicativo.

---

## 31. Incidentes

Em caso de secret vazado:

1. revogar;
2. rotacionar;
3. analisar logs;
4. identificar sistemas afetados;
5. remover do código;
6. avaliar histórico Git;
7. atualizar os ambientes;
8. documentar a causa;
9. criar prevenção contra recorrência.

Apagar apenas o arquivo atual não invalida um secret comprometido.

---

## 32. Vulnerabilidades

Não abra issue pública para vulnerabilidades.

Consulte:

```text
.github/SECURITY.md
```

O reporte deve utilizar o canal privado definido pelo projeto.

---

## 33. Revisão de segurança

Mudanças relacionadas às áreas abaixo merecem atenção especial:

- Auth;
- RLS;
- E2EE;
- sync;
- storage;
- migrations;
- permissões;
- API;
- arquivos;
- compartilhamento;
- notificações;
- dependências;
- integrações externas.

PRs nessas áreas devem receber revisão adicional quando possível.

---

## 34. Checklist para mudanças críticas

Antes do merge, pergunte:

- [ ] Esta mudança altera autenticação?
- [ ] Altera autorização?
- [ ] Altera RLS?
- [ ] Altera dados sensíveis?
- [ ] Altera criptografia?
- [ ] Altera sync?
- [ ] Altera armazenamento local?
- [ ] Adiciona nova dependência?
- [ ] Adiciona novo secret?
- [ ] Altera migration?
- [ ] Expõe novos dados em logs?
- [ ] Cria uma nova superfície de entrada?

Se alguma resposta for positiva, a mudança merece revisão de segurança
proporcional ao risco.

---

## 35. Segurança por camadas

A estratégia deve funcionar em várias camadas:

```text
Cliente
  ↓
Validação
  ↓
Autenticação
  ↓
Autorização
  ↓
RLS
  ↓
Criptografia
  ↓
Banco
  ↓
Backups
```

Nenhuma camada deve depender exclusivamente da anterior.

---

## 36. Evolução

Este documento deve ser atualizado quando:

- novas integrações forem adicionadas;
- arquitetura de autenticação mudar;
- E2EE mudar;
- sync mudar;
- novos tipos de dados sensíveis forem armazenados;
- infraestrutura mudar;
- novas ameaças forem identificadas;
- um incidente revelar uma lacuna arquitetural.

Segurança é um processo contínuo, não uma configuração concluída uma única vez.
