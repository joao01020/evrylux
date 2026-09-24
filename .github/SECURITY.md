# Política de Segurança

## Reportando uma vulnerabilidade

Não abra uma issue pública para relatar vulnerabilidades de segurança.

Isso evita que detalhes de uma falha explorável fiquem disponíveis publicamente
antes que uma correção possa ser desenvolvida e distribuída.

## Canal recomendado

Utilize o **GitHub Private Vulnerability Reporting** deste repositório para
enviar relatórios de segurança de forma privada.

Acesse:

```text
https://github.com/joao01020/evrylux/security/advisories/new
```

Se futuramente o projeto disponibilizar outros canais privados oficiais, eles
serão documentados nesta política.

> Não envie vulnerabilidades por issues, Pull Requests, Discussions ou outros
> canais públicos.

---

## Versões suportadas

O projeto prioriza correções de segurança para a versão atualmente mantida.

| Versão               | Suporte de segurança        |
| -------------------- | --------------------------- |
| Versão atual         | ✅ Suportada                |
| Versões anteriores   | ⚠️ Avaliadas caso a caso    |
| Versões não mantidas | ❌ Sem garantia de correção |

Esta política pode ser atualizada conforme o projeto passar a manter múltiplas
versões simultaneamente.

---

## O que enviar

Inclua informações suficientes para permitir a reprodução e análise do problema:

- componente afetado;
- versão, branch ou commit afetado;
- descrição da vulnerabilidade;
- passos para reprodução;
- impacto observado ou potencial;
- pré-condições necessárias;
- prova de conceito mínima, quando necessária;
- logs ou mensagens de erro relevantes;
- sugestão de correção, se houver.

Quando possível, informe também:

- sistema operacional;
- plataforma afetada;
- configuração relevante;
- se o problema acontece de forma consistente;
- se existe alguma solução temporária conhecida.

Evite enviar:

- dados pessoais reais;
- credenciais válidas;
- dumps desnecessários;
- informações de usuários não relacionadas ao problema;
- material obtido sem autorização;
- quantidade de dados maior que a necessária para demonstrar a vulnerabilidade.

---

## Exemplo de relatório

```text
Título:
Possível bypass de autorização ao atualizar tarefas

Componente:
API de tarefas

Versão/commit:
abc1234

Descrição:
Um usuário autenticado consegue alterar uma tarefa pertencente a outro usuário em determinada condição.

Passos para reproduzir:
1. autenticar como usuário A;
2. identificar uma tarefa pertencente ao usuário B;
3. executar a operação afetada;
4. observar que a alteração é aceita indevidamente.

Impacto:
Alteração não autorizada de dados.

Comportamento esperado:
O servidor deve rejeitar qualquer tentativa de modificar uma tarefa que não pertença ao usuário autenticado.

Sugestão:
Validar autorização e ownership no servidor antes de executar a atualização.
```

Não inclua dados reais de terceiros em uma prova de conceito.

---

## O que acontece depois do reporte

Após receber um relato, os mantenedores devem:

1. confirmar o recebimento;
2. validar a vulnerabilidade;
3. avaliar impacto e versões afetadas;
4. definir prioridade;
5. preparar uma correção;
6. adicionar ou atualizar testes;
7. validar a correção;
8. disponibilizar uma versão corrigida quando necessário;
9. publicar informações adequadas após a mitigação, quando apropriado.

Detalhes sensíveis devem permanecer privados enquanto a vulnerabilidade ainda
puder ser explorada.

---

## Divulgação responsável

Pedimos que pesquisadores e colaboradores:

- não divulguem publicamente a vulnerabilidade antes da correção;
- não acessem dados além do mínimo necessário para demonstrar o problema;
- não alterem ou excluam dados de terceiros;
- não degradem deliberadamente a disponibilidade do serviço;
- não utilizem a vulnerabilidade para obter vantagem indevida;
- limitem os testes ao mínimo necessário;
- preservem evidências sem coletar dados desnecessários;
- interrompam o teste caso percebam risco de dano, perda de dados ou
  indisponibilidade significativa.

---

## Testes autorizados

Esta política não concede autorização ampla para testar sistemas, contas ou
infraestrutura pertencentes a terceiros.

Testes devem permanecer limitados aos componentes do projeto sobre os quais o
pesquisador possui autorização legítima.

Não são autorizados, entre outros:

- engenharia social;
- phishing;
- acesso a contas de terceiros;
- destruição ou alteração intencional de dados;
- ataques de negação de serviço;
- testes físicos sem autorização;
- instalação de malware;
- persistência não autorizada;
- movimentação lateral em infraestrutura.

---

## Escopo

Esta política se aplica ao código e aos componentes mantidos diretamente por
este projeto.

Exemplos:

- aplicação Flutter;
- website;
- APIs mantidas pelo projeto;
- funções backend;
- banco e policies mantidas pelo projeto;
- mecanismos de autenticação e autorização;
- sincronização;
- criptografia implementada pelo projeto.

Dependências e serviços de terceiros podem exigir reporte diretamente ao
fornecedor responsável.

---

## Relatórios fora do escopo

Problemas que não representam risco de segurança devem ser enviados pelos canais
normais do projeto.

Exemplos:

- bugs visuais;
- erros de tradução;
- solicitações de funcionalidade;
- problemas de usabilidade;
- falhas sem impacto relevante de confidencialidade, integridade ou
  disponibilidade;
- problemas já públicos e corrigidos na versão atualmente suportada.

---

## Informações sensíveis

Nunca publique em:

- issues;
- Pull Requests;
- commits;
- Discussions;
- screenshots;
- documentação pública;
- logs públicos;

informações como:

- senhas;
- access tokens;
- refresh tokens;
- API keys privadas;
- secrets;
- chaves privadas;
- credenciais de banco;
- cookies de sessão;
- arquivos `.env`;
- dados pessoais;
- dumps de produção;
- detalhes técnicos de uma vulnerabilidade ainda não corrigida.

---

## Secrets expostos

Se uma credencial ou secret for exposto acidentalmente, não basta apagar o
arquivo ou commit.

A resposta deve incluir, quando aplicável:

1. revogar a credencial;
2. gerar uma nova credencial;
3. atualizar os ambientes afetados;
4. verificar possíveis usos indevidos;
5. remover a informação do código;
6. avaliar se o histórico Git precisa de tratamento adicional;
7. documentar a causa para evitar recorrência.

Um secret comprometido deve ser considerado inseguro mesmo após ser removido do
repositório.

---

## Para mantenedores

Os mantenedores devem:

- manter o Private Vulnerability Reporting habilitado;
- limitar o acesso aos relatórios;
- evitar compartilhar detalhes sensíveis desnecessariamente;
- validar correções antes de divulgação;
- manter dependências atualizadas;
- revisar autenticação e autorização;
- revisar policies RLS quando aplicável;
- tratar secrets comprometidos como incidentes;
- registrar correções de segurança relevantes no `CHANGELOG.md`.

Evite prometer prazos que a equipe não consegue garantir.

---

## Divulgação após correção

Após a mitigação, os mantenedores podem publicar informações como:

- componente afetado;
- versões afetadas;
- impacto;
- versão corrigida;
- orientações de atualização;
- créditos ao pesquisador, quando autorizado.

Detalhes que aumentem desnecessariamente o risco de exploração podem ser
omitidos ou publicados somente após tempo adequado para atualização.

---

## Princípio geral

A prioridade é permitir que vulnerabilidades sejam reportadas de forma privada,
analisadas com responsabilidade e corrigidas antes da divulgação pública.
