# EVRYLUX Web — Fase 4

Objetivo desta fase:

- remover **Treinar**, **Rotina** e **Evolução** somente da home Web;
- manter **Estudar** usando a `StudyScreen` real;
- manter o **Cérebro real** da Fase 3;
- abrir **Financeiro** usando a `FinanceScreen` real do aplicativo;
- preservar o comportamento desktop;
- retirar SQLite/FFI do caminho Web do Financeiro.

## Arquitetura do Financeiro

Desktop:

`FinanceScreen -> finance_runtime_native -> app_dependencies -> FinanceRepository native -> SQLite/SyncQueue`

Web:

`FinanceScreen -> finance_runtime_web -> FinanceRepository web -> SharedPreferences + Supabase`

O cache de histórico, objetivo e preços também possui implementação Web via SharedPreferences.

## Instalação

```bash
cd ~/Downloads
rm -rf evrylux_phase4_web_focus
unzip -o EVRYLUX_WEB_FASE_4_ESTUDAR_FINANCEIRO.zip -d .
chmod +x evrylux_phase4_web_focus/INSTALL.sh
evrylux_phase4_web_focus/INSTALL.sh ~/Documentos/PlatformIO/Projects/ghost-core/app
```

## Validação

```bash
cd ~/Documentos/PlatformIO/Projects/ghost-core/app
./scripts/check_phase4.sh
```

Depois:

```bash
./scripts/run_web.sh
```
