# Processo de Release

## 1. Objetivo

Este documento define um processo previsível, auditável e seguro para preparar e
publicar versões do projeto.

Toda release deve corresponder a um estado versionado do repositório.

---

## 2. Versionamento

Utilize Semantic Versioning quando aplicável:

```text
MAJOR.MINOR.PATCH
```

Exemplos:

```text
1.0.0
1.1.0
1.1.1
2.0.0
```

### MAJOR

Utilize quando houver mudanças incompatíveis ou alterações estruturais que
exijam adaptação de quem utiliza o projeto.

Exemplo:

```text
1.8.0 → 2.0.0
```

### MINOR

Utilize para novas funcionalidades compatíveis.

Exemplo:

```text
1.8.0 → 1.9.0
```

### PATCH

Utilize para correções compatíveis.

Exemplo:

```text
1.8.0 → 1.8.1
```

---

## 3. Antes de iniciar uma release

Confirme:

- escopo da versão;
- funcionalidades que entrarão;
- bugs bloqueadores resolvidos;
- Pull Requests necessários integrados;
- CI aprovado;
- dependências revisadas;
- migrations revisadas;
- documentação atualizada;
- segurança revisada;
- changelog atualizado.

Evite adicionar novas funcionalidades durante a preparação final da release.

---

## 4. Branch de release

Quando necessário, utilize:

```text
release/1.4.0
```

Criação:

```bash
git checkout main
git pull origin main
git checkout -b release/1.4.0
```

A branch de release deve conter apenas alterações necessárias para preparar a
versão.

Exemplos:

- número da versão;
- changelog;
- correções bloqueadoras;
- documentação;
- ajustes de build.

---

## 5. Atualização da versão

No Flutter, revise:

```text
app/pubspec.yaml
```

Exemplo:

```yaml
version: 1.4.0+140
```

O número após `+` representa o build number quando aplicável.

Antes de alterar, confirme a política adotada pelo projeto.

---

## 6. Changelog

Mova as mudanças relevantes de:

```text
## [Unreleased]
```

para a versão correspondente.

Exemplo:

```markdown
## [1.4.0] - 2026-09-23

### Added

- Nova funcionalidade X.

### Changed

- Fluxo Y atualizado.

### Fixed

- Correção Z.

### Security

- Validação adicional de autorização.
```

Depois deixe `Unreleased` disponível para o próximo ciclo.

---

## 7. Validação Flutter

A partir da raiz do repositório:

```bash
cd app
```

Execute:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Se qualquer etapa falhar, a release não deve prosseguir até a causa ser
entendida e corrigida.

---

## 8. Builds

Gere builds para as plataformas efetivamente suportadas.

### Linux

```bash
flutter build linux --release
```

### macOS

```bash
flutter build macos --release
```

### Windows

```powershell
flutter build windows --release
```

### Android

Quando aplicável:

```bash
flutter build apk --release
```

ou:

```bash
flutter build appbundle --release
```

Não gere artefatos para plataformas que o projeto ainda não suporta oficialmente
apenas para completar uma checklist.

---

## 9. Validação manual

Além dos testes automatizados, valide manualmente os fluxos críticos.

Exemplos:

- aplicação inicia;
- login funciona;
- logout funciona;
- dados carregam;
- criação funciona;
- edição funciona;
- exclusão funciona;
- sync funciona;
- comportamento offline funciona;
- reconexão funciona;
- notificações funcionam quando aplicável.

---

## 10. Banco de dados

Antes de aplicar migrations:

- revisar SQL;
- verificar RLS;
- analisar impacto;
- testar em desenvolvimento;
- verificar compatibilidade com dados existentes;
- revisar índices;
- revisar constraints;
- fazer backup quando a política exigir;
- documentar alterações destrutivas.

Evite mudanças destrutivas sem estratégia de recuperação.

---

## 11. Migrations

Nunca altere silenciosamente uma migration já aplicada em produção.

Se uma migration antiga possuir problema, prefira criar uma nova migration
corretiva.

Documente:

```text
Migration:
Objetivo:
Impacto:
Rollback:
Dados afetados:
```

---

## 12. Segurança

Antes da release, revise quando aplicável:

- autenticação;
- autorização;
- RLS;
- E2EE;
- armazenamento local;
- sync;
- permissões;
- secrets;
- dependências;
- uploads;
- logs.

Nenhuma credencial de produção deve estar presente no repositório ou artefato.

---

## 13. Checklist pré-release

Antes do merge final:

- [ ] número da versão atualizado;
- [ ] `CHANGELOG.md` atualizado;
- [ ] `flutter analyze` aprovado;
- [ ] testes aprovados;
- [ ] build aprovado;
- [ ] CI aprovado;
- [ ] migrations revisadas;
- [ ] RLS revisada quando aplicável;
- [ ] documentação atualizada;
- [ ] sem secrets;
- [ ] sem arquivos temporários;
- [ ] sem bugs bloqueadores conhecidos;
- [ ] rollback considerado para mudanças críticas.

---

## 14. Merge da release

Quando a preparação estiver concluída, abra um Pull Request para `main`.

O PR deve seguir o processo normal de:

```text
review
↓
CI
↓
aprovação
↓
merge
```

Evite bypassar os checks apenas por se tratar de uma release.

---

## 15. Tag

Após merge e validação:

```bash
git checkout main
git pull origin main
```

Crie a tag:

```bash
git tag -a v1.4.0 -m "Release v1.4.0"
```

Envie:

```bash
git push origin v1.4.0
```

A tag deve apontar exatamente para o commit da release.

---

## 16. GitHub Release

Crie uma GitHub Release utilizando a tag correspondente.

Inclua:

- versão;
- data;
- resumo;
- funcionalidades;
- mudanças relevantes;
- correções;
- breaking changes;
- migrations;
- alterações de segurança;
- limitações conhecidas;
- instruções de atualização;
- artefatos quando aplicável.

---

## 17. Artefatos

Se a release distribuir binários, confirme:

- plataforma;
- arquitetura;
- versão;
- build;
- origem;
- integridade.

Exemplo de nomenclatura:

```text
evrylux-1.4.0-linux-x64.tar.gz
evrylux-1.4.0-windows-x64.zip
```

Evite nomes genéricos como:

```text
final.zip
build-new.zip
versao-certa.zip
```

---

## 18. Pós-release

Após publicar, valide novamente o ambiente distribuído.

Verifique:

- aplicativo inicia;
- autenticação funciona;
- dados carregam;
- sync funciona;
- migrations foram aplicadas corretamente;
- logs não apresentam erros críticos;
- download dos artefatos funciona;
- versão exibida está correta.

---

## 19. Monitoramento pós-release

Nas primeiras horas ou dias após uma release importante, observe:

- novos bugs;
- erros recorrentes;
- falhas de autenticação;
- falhas de sync;
- migrations;
- regressões;
- relatos de usuários.

Problemas críticos podem exigir hotfix.

---

## 20. Rollback

Nem toda mudança permite rollback simples.

Antes de release com risco elevado, documente:

```text
Plano de rollback:
Impacto:
Dados afetados:
Migration reversível:
Versão anterior:
Ação emergencial:
Responsável:
```

Migrations destrutivas exigem cuidado adicional.

Nunca assuma que fazer downgrade do aplicativo também reverte automaticamente
mudanças no banco.

---

## 21. Hotfix

Para erro crítico em produção:

```text
hotfix/descricao
```

Fluxo:

```text
main
  ↓
hotfix
  ↓
correção mínima
  ↓
testes
  ↓
Pull Request
  ↓
CI
  ↓
review
  ↓
merge
  ↓
PATCH release
```

Exemplo:

```text
1.4.0
↓
hotfix
↓
1.4.1
```

Hotfixes devem ser pequenos e focados.

Evite adicionar novas funcionalidades junto com um hotfix.

---

## 22. Releases de desenvolvimento

Se futuramente o projeto utilizar versões de teste, considere convenções como:

```text
1.5.0-alpha.1
1.5.0-beta.1
1.5.0-rc.1
```

Essas versões não devem ser confundidas com releases estáveis.

---

## 23. Regra principal

Não publique uma release a partir de código local não versionado.

Toda release deve corresponder a:

```text
commit
+
tag
+
changelog
+
artefatos identificáveis
```

O objetivo é permitir que qualquer versão publicada possa ser rastreada até seu
código-fonte correspondente.
