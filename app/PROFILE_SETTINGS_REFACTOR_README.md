# Refatoração Profile Settings — Senior Split

Objetivo:
- `profile_settings_page.dart` fica responsável apenas por estado principal, lifecycle e orquestração.
- Ações foram separadas por responsabilidade.
- Seções visuais foram separadas por domínio.
- Widgets reutilizáveis saíram da página principal.
- Nenhuma regra funcional foi removida.

Estrutura:

lib/profile/screens/
├── profile_settings_page.dart
└── settings/
    ├── actions/
    │   ├── preferences_actions.dart
    │   ├── security_actions.dart
    │   └── brain_actions.dart
    ├── sections/
    │   ├── profile_settings_shell.dart
    │   ├── security_section.dart
    │   ├── brain_section.dart
    │   └── about_section.dart
    └── widgets/
        └── profile_settings_widgets.dart

Observação:
Foi usado `part / part of` deliberadamente para manter os membros privados
(`_...`) encapsulados dentro da mesma library Dart, evitando transformar
detalhes internos da tela em API pública apenas por causa da refatoração.


## v2 — correção Dart State/extension

A primeira divisão usava extensions para manter os membros privados
dentro da mesma library Dart, mas duas regras precisavam ser tratadas:

1. `State.setState()` é protegido e não deve ser chamado diretamente
   por uma extension.
2. membros `static` do tipo estendido precisam ser qualificados pelo
   nome do tipo.

A v2 corrige isso desta forma:

- as extensions chamam `_updateProfileState(...)`;
- somente `_ProfileSettingsPageState` chama `setState(...)`;
- as cores estáticas são referenciadas como
  `_ProfileSettingsPageState._surface`,
  `_ProfileSettingsPageState._border`, etc.

Nenhuma funcionalidade da tela foi removida.
