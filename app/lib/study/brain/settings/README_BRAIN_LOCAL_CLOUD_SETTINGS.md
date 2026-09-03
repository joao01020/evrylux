# EVRYLUX CÉREBRO — Local / Cloud

## Status

Fase 05 — Modo de Dados

Estado atual:

- `BrainDataMode` criado;
- storage persistente criado;
- service criado;
- controller criado;
- modo local como padrão;
- cloud exige autenticação;
- testes criados.

---

## Objetivo

Esta fase define como o Cérebro deve se comportar em relação à nuvem.

Existem dois modos:

```text
LOCAL
CLOUD
```

A Fase 05 NÃO implementa sincronização com Supabase.

Ela apenas cria o gate que será usado pela Fase 06.

---

## Regra principal

```text
LOCAL
→ nunca enviar Brain para nuvem

CLOUD
→ permite entrar no fluxo de sync
→ exige autenticação
→ somente ciphertext
```

Mesmo em modo Cloud:

```text
plaintext
→ nunca pode entrar na SyncQueue
```

A decisão de Cloud não significa autorização para enviar dados abertos.

---

## Estrutura de arquivos

```text
lib/study/brain/settings/
├── models/
│   └── brain_data_mode.dart
├── storage/
│   └── brain_data_mode_storage.dart
├── services/
│   └── brain_data_mode_service.dart
└── controllers/
    └── brain_data_mode_controller.dart

test/study/brain/settings/
├── brain_data_mode_test.dart
├── brain_data_mode_service_test.dart
└── brain_data_mode_controller_test.dart
```

---

## `BrainDataMode`

Enum principal:

```dart
enum BrainDataMode {
  local,
  cloud,
}
```

Regras associadas:

```text
local
- allowsCloudSync = false
- requiresAuthentication = false
- isLocalOnly = true

cloud
- allowsCloudSync = true
- requiresAuthentication = true
- isLocalOnly = false
```

Também possui:

```text
storageValue
label
description
tryParse()
```

---

## `BrainDataModeStorage`

Contrato de persistência:

```text
load()
save()
clear()
```

Implementações atuais:

```text
SharedPreferencesBrainDataModeStorage
InMemoryBrainDataModeStorage
```

### SharedPreferences

SharedPreferences é usado apenas porque o valor armazenado é uma preferência não sensível:

```text
local
ou
cloud
```

Não salvar aqui:

- Master Key;
- conteúdo;
- ciphertext;
- perguntas;
- respostas;
- tokens;
- credenciais.

Chave atual:

```text
evrylux.brain.data_mode.v1
```

---

## Fail closed

Se o storage contiver um valor desconhecido:

```text
"modo_invalido"
```

o sistema NÃO deve assumir Cloud.

Regra:

```text
valor desconhecido
↓
local
```

Isso evita habilitar sincronização por erro de configuração.

---

## `BrainDataModeService`

Fonte de verdade da decisão operacional.

API principal:

```text
initialize()
setMode()
useLocalMode()
useCloudMode()
canUseCloudSync()
reset()
```

### Modo padrão

Primeira execução:

```text
nenhuma preferência salva
↓
BrainDataMode.local
```

O Cérebro começa local por segurança.

---

## Gate de Cloud

Uso:

```dart
service.canUseCloudSync(
  isAuthenticated: true,
);
```

Resultados:

```text
LOCAL + autenticado
→ false

LOCAL + não autenticado
→ false

CLOUD + não autenticado
→ false

CLOUD + autenticado
→ true
```

Este gate será usado na Fase 06 antes de enfileirar qualquer objeto E2EE.

---

## `BrainDataModeController`

Controller voltado para UI e integração com Settings.

API:

```text
initialize()
setMode()
useLocalMode()
useCloudMode()
canUseCloudSync()
clearError()
```

Estado:

```text
isLoading
isSaving
isBusy
mode
isInitialized
errorMessage
isLocalMode
isCloudMode
allowsCloudSync
```

---

## Fluxo futuro de UI

Exemplo conceitual:

```text
Settings
↓
Cérebro
↓
Modo dos dados

(●) Local
( ) Cloud
```

### Local

Texto sugerido:

```text
Seus dados permanecem somente neste dispositivo.
Nenhuma sincronização do Cérebro é realizada.
```

### Cloud

Texto sugerido:

```text
O Cérebro continua local-first e poderá sincronizar
somente objetos criptografados entre dispositivos.
```

---

## Arquitetura

```text
UI
↓
BrainDataModeController
↓
BrainDataModeService
↓
BrainDataModeStorage
↓
SharedPreferences
```

Na Fase 06:

```text
BrainDataModeService
↓
canUseCloudSync()
↓
BrainSyncQueueService
↓
ciphertext
↓
Supabase
```

---

## Relação com o Vault

O modo de dados NÃO muda a origem da verdade.

Nos dois modos:

```text
Vault local
= fonte principal
```

Cloud nunca deve substituir a arquitetura local-first.

### Local

```text
Vault
↓
fica local
```

### Cloud

```text
Vault
↓
ciphertext
↓
SyncQueue E2EE
↓
Supabase
```

---

## Relação com autenticação

Modo Local:

```text
login não é necessário para o Cérebro local
```

Modo Cloud:

```text
login necessário
```

Mas:

```text
conta != Master Key
```

Autenticação identifica o usuário.

A Master Key protege os dados.

Nunca derivar Master Key de:

- user_id;
- email;
- senha Supabase;
- token;
- username.

---

## Testes

### Model

```bash
flutter test \
test/study/brain/settings/brain_data_mode_test.dart
```

Valida:

- regras Local;
- regras Cloud;
- parse;
- valores desconhecidos.

### Service

```bash
flutter test \
test/study/brain/settings/brain_data_mode_service_test.dart
```

Valida:

- Local como padrão;
- persistência;
- reabertura;
- Cloud exige autenticação;
- Local bloqueia Cloud;
- reset.

### Controller

```bash
flutter test \
test/study/brain/settings/brain_data_mode_controller_test.dart
```

Valida:

- inicialização;
- mudança para Cloud;
- persistência;
- gate de autenticação;
- bloqueio no modo Local.

### Todos

```bash
flutter test \
test/study/brain/settings
```

---

## Próxima integração

Depois dos testes, registrar instâncias globais em:

```text
lib/app/dependencies/app_dependencies.dart
```

Fluxo esperado:

```text
SharedPreferencesBrainDataModeStorage
↓
BrainDataModeService
↓
BrainDataModeController
```

E inicializar no startup:

```text
await brainDataModeController.initialize();
```

ou diretamente:

```text
await brainDataModeService.initialize();
```

A escolha deve manter uma única instância global.

---

## Definition of Done — Fase 05

A Fase 05 só deve ser marcada como concluída quando:

```text
[x] BrainDataMode
[x] storage
[x] service
[x] controller
[x] Local como padrão
[x] Cloud exige autenticação
[x] Local bloqueia sync
[x] persistência testada
[x] testes unitários
[ ] wiring no app_dependencies.dart
[ ] inicialização no startup
[ ] gate disponível para a Fase 06
```

Neste momento a fundação está criada, mas o wiring global ainda precisa ser feito antes de fechar a Fase 05.

---

## Próxima fase

```text
Fase 06 — Supabase E2EE
```

Nela será criado o fluxo:

```text
Vault
↓
BrainSyncPayload
↓
BrainSyncQueueService
↓
ciphertext
↓
brain_objects
↓
Supabase
```

Sem plaintext em nenhuma etapa de sincronização.
