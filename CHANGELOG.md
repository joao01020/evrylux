# Changelog

Todas as mudanças relevantes deste projeto devem ser documentadas neste arquivo.

O formato segue os princípios de [Keep a Changelog](https://keepachangelog.com/)
e Semantic Versioning quando aplicável.

---

## [Unreleased]

### Added

- Estrutura profissional de documentação do repositório.
- `CODE_OF_CONDUCT.md` com diretrizes de comportamento e colaboração.
- `CONTRIBUTING.md` com fluxo de contribuição, branches, commits, Pull Requests
  e revisão.
- `SECURITY.md` com processo privado para reporte de vulnerabilidades.
- `CODEOWNERS` para definição de responsáveis por áreas do repositório.
- Template padronizado de Pull Request.
- Template estruturado para reporte de bugs.
- Template estruturado para solicitação de funcionalidades.
- Configuração da página de criação de issues.
- Configuração inicial do Dependabot.
- Labels adicionais para dependências, Flutter e CI.
- Workflow de CI para Flutter.
- Workflow de validação de build Linux.
- Workflow de verificações de segurança.
- Verificação automatizada de formatação.
- Verificação automatizada com `flutter analyze`.
- Execução automatizada de testes Flutter.
- Verificação automatizada de build Linux.
- Verificação de secrets com Gitleaks.
- Dependency Review no fluxo de segurança.
- Documentação de arquitetura do projeto.
- Documentação completa do ambiente de desenvolvimento.
- Documentação da estratégia de testes.
- Roadmap específico de testes.
- Documentação da arquitetura de segurança.
- Documentação do processo de release.
- Documentação da estrutura e configuração do repositório.
- Documento de suporte para colaboradores e usuários.
- Roadmap de evolução do produto.
- ADR 0001 documentando a decisão arquitetural offline-first.
- ADR 0002 documentando o uso do Supabase como backend principal.
- ADR 0003 documentando a estratégia de criptografia e E2EE.
- Documentação do ambiente Supabase DEV compartilhado.
- Separação documentada entre ambientes de desenvolvimento e produção.
- Configuração documentada para onboarding de novos colaboradores.
- Fluxo documentado de Supabase local, DEV remoto e produção.
- Diretrizes para migrations versionadas.
- Diretrizes para testes de RLS.
- Estratégia de testes de isolamento entre usuários.
- Diretrizes de testes de tombstones.
- Diretrizes de testes de sincronização offline-first.
- Diretrizes de testes de conflitos entre dispositivos.
- Diretrizes de testes de E2EE.
- Diretrizes de testes de autenticação e sessões.
- Diretrizes para testes de upgrades e migrations.
- Plano de testes para performance e grandes volumes de dados.
- Planejamento de testes para Linux, macOS e Windows.
- Planejamento de testes para billing, quotas e assinaturas.
- Planejamento de sistema de armazenamento por usuário.
- Planejamento de limite gratuito inicial de 1 GB.
- Planejamento de plano pago de US$ 9 por mês.
- Planejamento de plano pago de US$ 29 por mês.
- Planejamento de upgrade, downgrade e cancelamento.
- Planejamento de controle de quotas de armazenamento.
- Planejamento de comportamento quando o limite de armazenamento for atingido.
- Planejamento de proteção contra manipulação de plano pelo cliente.
- Planejamento de integração segura com webhooks de pagamento.
- Planejamento de recursos de IA para organização do Brain.
- Planejamento de IA para identificação de relações entre conhecimentos.
- Planejamento de IA para sugestões de próximos assuntos de estudo.
- Planejamento de IA para identificação de lacunas de conhecimento.
- Planejamento de IA para evolução do mapa de conhecimento.
- Planejamento de IA para auxílio em revisões.
- Estratégia de processamento incremental de IA.
- Estratégia de retrieval seletivo para IA.
- Estratégia de contexto mínimo para chamadas de IA.
- Planejamento de JSON compacto como entrada para IA.
- Planejamento de medição de custo e tokens por operação de IA.
- Planejamento de cache e redução de chamadas duplicadas de IA.
- Planejamento de colaboração através de atribuição de tarefas.
- Planejamento de notificações para tarefas atribuídas.
- Planejamento de exibição de tarefas recebidas no dashboard.
- Planejamento de histórico de atividade e permissões entre colaboradores.

### Changed

- Processo de colaboração documentado e padronizado.
- Processo de revisão de código formalizado.
- Processo de Pull Request padronizado.
- Processo de criação de branches documentado.
- Convenção de commits formalizada.
- Processo de desenvolvimento atualizado para utilizar branches dedicadas.
- Fluxo de desenvolvimento atualizado para evitar alterações diretas na `main`.
- Processo de CI estruturado para validar mudanças antes do merge.
- Processo de segurança do repositório ampliado.
- Processo de reporte de vulnerabilidades direcionado para GitHub Private
  Vulnerability Reporting.
- Diretrizes de segurança e reporte privado formalizadas.
- Documentação do ambiente de desenvolvimento ampliada.
- Ambiente DEV definido como ambiente padrão para colaboradores.
- Uso do banco Supabase DEV formalizado para desenvolvimento compartilhado.
- Ambiente de produção separado formalmente do ambiente de desenvolvimento.
- Processo de onboarding atualizado para incluir configuração do `.env`.
- Estratégia de `.env` documentada.
- Uso de `.env.example` documentado.
- Regras de `.gitignore` para arquivos de ambiente formalizadas.
- Processo de uso do Supabase CLI documentado.
- Processo de migrations documentado e reforçado.
- Processo de validação de RLS incluído no desenvolvimento.
- Arquitetura do projeto expandida para separar UI, controllers, lógica de
  aplicação, repositories e data sources.
- Responsabilidades das camadas da aplicação Flutter formalizadas.
- Arquitetura offline-first definida como restrição arquitetural.
- Armazenamento local definido como parte essencial da arquitetura e não apenas
  como cache.
- Estratégia de sincronização documentada.
- Requisitos de idempotência adicionados ao desenho de sync.
- Uso de IDs estáveis formalizado.
- Estratégia de tombstones documentada.
- Necessidade de política explícita de conflitos formalizada.
- Comportamento em falhas de conexão documentado.
- Supabase definido formalmente como backend remoto principal.
- Fronteira de confiança entre Flutter e backend documentada.
- Autenticação e autorização separadas conceitualmente.
- Uso de RLS formalizado como camada de autorização próxima aos dados.
- Regras de ownership no backend documentadas.
- Uso de Supabase Functions definido para operações privilegiadas.
- Regras para Supabase Storage documentadas.
- Publishable key diferenciada de credenciais administrativas.
- Proibição de `service_role` no aplicativo cliente explicitada.
- Arquitetura de criptografia e E2EE ampliada.
- Escopo de dados candidatos a E2EE documentado.
- Modelo de ameaça da camada E2EE documentado.
- Gestão de chaves tratada como parte do ciclo de vida da criptografia.
- Envelopes de chave documentados como estratégia para múltiplos dispositivos.
- Revogação e rotação de chaves incluídas na arquitetura.
- Recuperação de chaves tratada como decisão explícita.
- Versionamento de payload criptográfico formalizado.
- Requisitos de nonce/IV documentados.
- Necessidade de criptografia autenticada formalizada.
- Regras para armazenamento de plaintext reduzido ao mínimo documentadas.
- Relação entre E2EE e persistência local documentada.
- Relação entre E2EE e offline-first documentada.
- Limitações de busca remota em dados criptografados documentadas.
- Relação entre E2EE e uso de IA documentada.
- Minimização de contexto enviado para IA adicionada como princípio.
- IA reposicionada como camada de organização e apoio ao estudo, não como
  substituta do conteúdo do usuário.
- Conteúdo original do Brain definido como fonte principal.
- Alterações automáticas pela IA limitadas por princípio de confirmação do
  usuário.
- Processamento de IA planejado para evitar envio do Brain completo.
- Roadmap ampliado para incluir monetização e sustentabilidade financeira.
- Roadmap ampliado para incluir planos de assinatura.
- Roadmap ampliado para incluir quotas e armazenamento.
- Roadmap ampliado para incluir custos de IA.
- Roadmap ampliado para incluir processamento incremental.
- Roadmap ampliado para incluir colaboração futura.
- Processo de release documentado com preparação, validação, tag, GitHub Release
  e rollback.
- Política de hotfix formalizada.
- Validação pré-release ampliada.
- Documentação do repositório reorganizada para refletir a configuração real da
  pasta `.github`.
- Estratégia de testes ampliada para incluir cenários funcionais, integração,
  segurança e regressão.
- Definition of Done ampliada para incluir CI, segurança, migrations e
  documentação.

### Fixed

- Corrigida ambiguidade na documentação sobre chaves privadas e chaves
  administrativas.
- Corrigida distinção entre Supabase DEV remoto e Supabase local.
- Corrigida distinção entre autenticação e autorização.
- Corrigida interpretação de chave publishable como mecanismo de segurança.
- Corrigida documentação para evitar dependência de filtros no Flutter como
  mecanismo de autorização.
- Corrigida documentação de E2EE para deixar explícito que o backend não deve
  possuir capacidade de descriptografar conteúdo protegido.
- Corrigida documentação de offline-first para deixar explícito que dados locais
  pendentes não são cache descartável.
- Corrigida documentação do processo de desenvolvimento para considerar branches
  diferentes da `main`.
- Corrigida documentação de paths para refletir a estrutura real do repositório.
- Corrigida padronização de Markdown nos arquivos de documentação.

### Security

- Criado processo privado para reporte de vulnerabilidades.
- GitHub Private Vulnerability Reporting adotado como canal recomendado.
- Diretrizes para proteção de secrets e credenciais adicionadas.
- Gitleaks adicionado às verificações automatizadas.
- Dependency Review adicionado ao fluxo de segurança.
- Dependabot configurado para acompanhar dependências Flutter e GitHub Actions.
- Diretrizes de proteção da branch `main` documentadas.
- Recomendação de aprovação obrigatória para Pull Requests adicionada.
- Recomendação de status checks obrigatórios documentada.
- Bloqueio de force push e exclusão da `main` recomendado.
- Política para secrets comprometidos documentada.
- Proibição de credenciais administrativas no cliente reforçada.
- Proibição de `service_role` no Flutter documentada.
- RLS definido como mecanismo principal de autorização para dados privados no
  Supabase.
- Testes de isolamento entre usuários adicionados ao roadmap de segurança.
- Testes de `SELECT`, `INSERT`, `UPDATE` e `DELETE` em políticas RLS planejados.
- Testes com usuário A, usuário B e usuário anônimo adicionados.
- Ownership baseado apenas em valores enviados pelo cliente desencorajado.
- Separação entre ambientes DEV e PROD formalizada.
- Uso de dados fictícios no ambiente DEV recomendado.
- Dados reais de produção desencorajados em desenvolvimento.
- E2EE definido como componente arquitetural crítico.
- Criptografia autenticada definida como requisito.
- Versionamento do formato criptográfico definido como requisito.
- Gestão de nonce/IV documentada.
- Gestão de chaves documentada.
- Estratégia de envelopes de chave documentada.
- Revogação de dispositivos considerada na arquitetura.
- Rotação de chaves considerada na arquitetura.
- Recuperação de chaves documentada como decisão crítica.
- Logs proibidos de armazenar chaves, tokens, senhas e plaintext sensível.
- Testes de corrupção de ciphertext adicionados.
- Testes de chave incorreta adicionados.
- Testes de múltiplos dispositivos adicionados.
- Minimização de dados enviados a serviços de IA adicionada.
- Envio do Brain completo para IA desencorajado por padrão.
- Estratégia de retrieval seletivo adicionada para reduzir exposição de dados.
- JSON compacto planejado para reduzir contexto enviado a modelos de IA.
- Quotas e planos definidos como informações que não devem ser controladas
  apenas pelo cliente.
- Webhooks de billing definidos como eventos que exigem validação backend.
- Dados completos de cartão definidos como responsabilidade de provedor
  especializado.
- Downgrade planejado para não causar exclusão imediata de dados do usuário.

---

<!--

Exemplo de release futura:

## [1.0.0] - 2026-10-15

### Added

- Primeira versão estável do projeto.

### Changed

- Fluxos principais estabilizados.

### Fixed

- Correções encontradas durante validação pré-release.

### Security

- Revisão final de RLS, autenticação e E2EE.

-->

## Convenções

Utilize as categorias:

```text id="o8w3tn"
Added
Changed
Deprecated
Removed
Fixed
Security
```

### Added

Novas funcionalidades, arquivos, recursos ou capacidades.

### Changed

Alterações relevantes em funcionalidades existentes, comportamento, arquitetura
ou processos.

### Deprecated

Funcionalidades que ainda existem, mas serão removidas futuramente.

### Removed

Funcionalidades removidas do projeto.

### Fixed

Correções de bugs.

### Security

Mudanças relacionadas à segurança, vulnerabilidades, autenticação, autorização,
proteção de dados ou secrets.

---

## Como registrar uma nova versão

Ao preparar uma release, mova as mudanças relevantes de `Unreleased` para uma
seção versionada.

Exemplo:

```markdown id="u8xo4z"
## [1.2.0] - 2026-10-15

### Added

- Nova funcionalidade X.

### Fixed

- Correção do problema Y.
```

Depois deixe `Unreleased` novamente disponível para as próximas mudanças.

Exemplo:

```markdown id="48vxds"
## [Unreleased]

### Added

### Changed

### Fixed

### Security

---

## [1.2.0] - 2026-10-15
```

---

## O que deve entrar no changelog

Registre mudanças relevantes para:

- usuários;
- desenvolvedores;
- colaboradores;
- mantenedores;
- segurança;
- arquitetura;
- compatibilidade;
- deploy;
- banco de dados;
- configuração;
- testes;
- releases.

Exemplos:

- novas funcionalidades;
- mudanças de comportamento;
- breaking changes;
- correções importantes;
- migrations relevantes;
- mudanças de segurança;
- remoção de funcionalidades;
- alterações que exigem ação manual após atualização;
- mudanças arquiteturais importantes;
- alterações relevantes no processo de desenvolvimento;
- mudanças em infraestrutura ou CI.

---

## O que não deve entrar

Não registre cada commit individualmente.

Normalmente não é necessário incluir:

- pequenas correções de texto;
- formatação isolada;
- reorganizações internas sem impacto;
- commits intermediários;
- mudanças temporárias;
- arquivos de teste descartáveis;
- alterações que não tenham efeito relevante fora da implementação.

---

## Regra

O changelog deve explicar **o que mudou para o projeto**, e não simplesmente
reproduzir o histórico de commits.

Ele deve ser legível por alguém que queira entender rapidamente:

```text id="mnl4an"
o que foi adicionado
o que mudou
o que foi corrigido
o que mudou em segurança
```

entre diferentes versões.

Durante o desenvolvimento, novas mudanças relevantes devem ser adicionadas em:

```text id="wqeygi"
## [Unreleased]
```

Quando uma versão for publicada, essas mudanças devem ser movidas para a versão
correspondente.
