# Suporte

## Onde pedir ajuda

Use o canal apropriado conforme o tipo de problema.

Este documento ajuda a direcionar bugs, dúvidas, sugestões e questões de
segurança para o lugar correto.

---

## Bug

Para reportar um bug, abra uma issue utilizando o template de bug disponível no
repositório.

Inclua, quando aplicável:

- descrição clara do problema;
- comportamento esperado;
- passos para reproduzir;
- frequência do problema;
- versão, branch ou commit;
- plataforma afetada;
- logs relevantes;
- screenshots ou vídeos;
- contexto adicional.

Antes de enviar, remova qualquer informação sensível.

---

## Nova funcionalidade

Para sugerir uma nova funcionalidade, utilize o template de Feature Request.

Descreva primeiro o problema que precisa ser resolvido.

Sempre que possível, inclua:

- contexto;
- problema atual;
- solução proposta;
- fluxo esperado;
- impacto;
- critérios de aceite;
- alternativas consideradas.

Uma boa Feature Request explica o problema antes de detalhar a implementação.

---

## Dúvidas de desenvolvimento

Antes de pedir ajuda:

1. consulte `README.md`;
2. consulte `docs/DEVELOPMENT.md`;
3. consulte a documentação relacionada ao componente;
4. procure por issues existentes;
5. verifique logs;
6. confirme a branch atual;
7. execute `flutter doctor -v` quando o problema estiver relacionado ao ambiente
   Flutter.

Ao pedir ajuda, inclua contexto suficiente para que outra pessoa consiga
entender e reproduzir o problema.

Informações úteis podem incluir:

```text
Sistema operacional:
Flutter:
Dart:
Branch:
Commit:
Comando executado:
Erro observado:
Comportamento esperado:
```

---

## Problemas com Flutter

Quando o problema estiver relacionado ao ambiente Flutter, inclua quando
necessário:

```bash
flutter doctor -v
```

Também podem ser úteis:

```bash
flutter --version
dart --version
flutter devices
```

Antes de enviar a saída, verifique se ela não contém caminhos, nomes ou
informações que você não deseja publicar.

---

## Problemas com Git

Ao pedir ajuda com Git, informe:

```bash
git status
git branch --show-current
```

Quando necessário:

```bash
git log --oneline --decorate -n 10
```

Evite executar comandos destrutivos sem entender o efeito.

---

## Problemas com banco ou Supabase

Ao reportar problemas relacionados ao backend, informe:

- migration envolvida;
- tabela ou componente afetado;
- ambiente utilizado;
- comportamento esperado;
- mensagem de erro;
- impacto observado.

Não publique:

- senha de banco;
- connection string privada;
- service role key;
- secrets;
- dumps contendo dados reais;
- informações de usuários.

---

## Segurança

Vulnerabilidades de segurança não devem ser reportadas por issue pública.

Consulte:

```text
.github/SECURITY.md
```

O canal privado do repositório é:

```text
https://github.com/joao01020/ghost-core/security/advisories/new
```

Use esse canal para reportar possíveis vulnerabilidades de forma privada.

---

## Informações que não devem ser publicadas

Nunca publique em issues, Pull Requests, Discussions, logs ou screenshots:

- senhas;
- access tokens;
- refresh tokens;
- API keys privadas;
- service role keys;
- secrets;
- `.env`;
- chaves privadas;
- cookies de sessão;
- credenciais de banco;
- connection strings privadas;
- dados pessoais;
- dumps de produção;
- conteúdo confidencial;
- detalhes exploráveis de vulnerabilidades ainda não corrigidas.

Se um secret for exposto acidentalmente, considere-o comprometido e faça a
rotação imediatamente.

---

## Qual canal utilizar

Use esta referência rápida:

```text
Bug
→ Issue / Bug Report

Nova funcionalidade
→ Issue / Feature Request

Dúvida de desenvolvimento
→ Issue ou canal de colaboração adotado pela equipe

Vulnerabilidade
→ Private Vulnerability Reporting

Problema em Pull Request
→ Comentários do próprio Pull Request

Decisão arquitetural
→ Discussão técnica + ADR quando necessário
```

---

## Suporte a versões

O projeto prioriza a versão atualmente mantida.

Versões antigas podem não receber correções, salvo quando explicitamente
informado.

Consulte também:

```text
.github/SECURITY.md
```

para informações relacionadas ao suporte de segurança.

---

## Tempo de resposta

O projeto não garante prazo específico para resposta.

O tempo necessário depende de fatores como:

- gravidade;
- possibilidade de reprodução;
- impacto;
- disponibilidade dos mantenedores;
- quantidade de contexto fornecido.

Relatos claros e reproduzíveis normalmente são mais fáceis de analisar.

---

## Antes de abrir uma issue

Verifique:

- [ ] já existe uma issue equivalente;
- [ ] identifiquei se é bug, feature ou dúvida;
- [ ] consigo explicar ou reproduzir o problema;
- [ ] estou utilizando a branch ou versão correta;
- [ ] removi informações sensíveis;
- [ ] incluí logs relevantes quando necessário;
- [ ] incluí screenshots quando ajudam;
- [ ] consultei a documentação existente.

---

## Boas práticas ao pedir ajuda

Prefira:

```text
Ao abrir a tela X e executar Y, recebo o erro Z.
Estou na branch dev-stable, commit abc1234.
Consigo reproduzir sempre seguindo estes passos...
```

em vez de:

```text
Não funciona.
```

Quanto melhor o contexto, mais fácil será diagnosticar o problema.

---

## Objetivo

O objetivo deste documento é garantir que cada tipo de solicitação chegue ao
canal correto, com contexto suficiente e sem exposição desnecessária de
informações sensíveis.
