# EVRYLUX CÉREBRO — Backup `.evbrain`

## Status

Fase 04 — Backup / Restauração

Estado atual:

- estrutura de backup criada;
- exportação em `.evbrain`;
- compressão com GZIP;
- criptografia do archive;
- restauração validada;
- tombstones preservados;
- versões locais mais novas protegidas;
- testes passando.

---

## Objetivo

O `.evbrain` é o formato portátil de backup do EVRYLUX Cérebro.

A finalidade desta camada é permitir que o usuário gere um arquivo de backup do Vault sem expor o conteúdo armazenado.

O fluxo é:

```text
Vault local
↓
objetos .evobj já criptografados
↓
serialização
↓
archive interno
↓
compressão GZIP
↓
criptografia
↓
arquivo .evbrain
```

Na restauração:

```text
.evbrain
↓
validação do header
↓
localização da Master Key autorizada
↓
descriptografia
↓
descompressão
↓
desserialização
↓
restauração dos objetos
```

---

## Regra de segurança principal

A Master Key NÃO é salva dentro do `.evbrain`.

O arquivo contém apenas:

- metadados técnicos não sensíveis;
- payload criptografado;
- objetos do Vault já protegidos.

Nunca armazenar no backup:

- Master Key em plaintext;
- senha;
- token Supabase;
- email;
- user_id como segredo;
- pergunta em plaintext;
- resposta em plaintext;
- conteúdo de anotação em plaintext.

---

## Limitação atual

Na Fase 04, o `.evbrain` pode ser transportado como arquivo, mas só pode ser restaurado em um ambiente que já possua acesso autorizado à mesma Master Key do Vault.

A transferência segura da chave será tratada posteriormente em:

```text
Fase 07 — Dispositivos autorizados
Fase 16 — Recovery Device
```

Portanto:

```text
arquivo .evbrain ≠ Master Key
```

O arquivo sozinho não deve ser suficiente para abrir o conteúdo.

---

## Estrutura de arquivos

```text
lib/study/brain/backup/
├── exceptions/
│   └── brain_backup_exception.dart
├── models/
│   ├── brain_backup_header.dart
│   ├── brain_backup_package.dart
│   └── brain_backup_restore_result.dart
└── services/
    ├── brain_backup_compression_service.dart
    ├── brain_backup_serializer.dart
    └── brain_backup_service.dart

test/study/brain/backup/
├── brain_backup_compression_service_test.dart
├── brain_backup_serializer_test.dart
└── brain_backup_service_test.dart
```

---

## Componentes

### `BrainBackupHeader`

Responsável pelos metadados técnicos do arquivo.

Campos principais:

```text
format
format_version
vault_id
crypto_version
key_version
object_count
created_at
```

Esses dados não devem conter conteúdo sensível do usuário.

---

### `BrainBackupPackage`

Representa o pacote externo `.evbrain`.

Contém:

```text
header
encrypted_payload_object
```

O `encrypted_payload_object` contém o wrapper criptografado do archive.

---

### `BrainBackupRestoreResult`

Retorna o resultado da restauração.

Campos:

```text
vaultId
totalInBackup
restored
skippedNewerLocal
```

Isso permite saber:

- quantos objetos existiam no backup;
- quantos foram restaurados;
- quantos foram ignorados porque o Vault local já possuía versão mais nova.

---

### `BrainBackupCompressionService`

Responsável por:

```text
String
↓
UTF-8
↓
GZIP
↓
Base64
```

E pelo caminho inverso na restauração.

A compressão acontece antes da criptografia.

---

### `BrainBackupSerializer`

Responsável por:

- serializar o package externo;
- desserializar o `.evbrain`;
- serializar o archive interno;
- validar formato;
- validar versão.

Formato externo:

```text
evrylux-brain-backup
```

Formato interno:

```text
evrylux-brain-backup-archive
```

Versão atual:

```text
1
```

---

### `BrainBackupService`

Orquestrador principal da Fase 04.

Responsabilidades:

```text
exportToString()
exportToFile()
importFromString()
importFromFile()
```

Fluxo de exportação:

```text
BrainVaultService.openVault()
↓
BrainKeyService.requireKeyBundle()
↓
BrainVaultService.loadAllEncryptedObjects()
↓
BrainVaultSerializer.serializeObject()
↓
BrainBackupSerializer.serializeArchive()
↓
BrainBackupCompressionService.compressString()
↓
BrainCryptoService.encryptString()
↓
BrainBackupPackage
↓
.evbrain
```

Fluxo de importação:

```text
ler .evbrain
↓
BrainBackupSerializer.deserializePackage()
↓
BrainKeyService.requireKeyBundle()
↓
BrainCryptoService.decryptString()
↓
BrainBackupCompressionService.decompressString()
↓
BrainBackupSerializer.deserializeArchive()
↓
BrainVaultSerializer.deserializeObject()
↓
BrainVaultStorage.saveObject()
```

---

## Proteção de versões

Durante a restauração existe uma proteção importante.

Se o backup tiver:

```text
objeto versão 1
```

e o Vault local já possuir:

```text
objeto versão 2
```

o restore NÃO deve substituir a versão 2 pela versão 1.

Regra:

```text
local.version > backup.version
→ manter local
```

Isso evita perda de alterações mais recentes.

---

## Tombstones

Objetos excluídos também fazem parte do backup.

Exemplo:

```text
objeto
↓
delete
↓
tombstone
↓
.evbrain
↓
restore
↓
tombstone continua existindo
```

Isso será importante futuramente para sincronização e múltiplos dispositivos.

---

## Testes

### Compressão

```bash
flutter test \
test/study/brain/backup/brain_backup_compression_service_test.dart
```

Valida:

- round-trip;
- Unicode;
- erro em payload inválido.

### Serializer

```bash
flutter test \
test/study/brain/backup/brain_backup_serializer_test.dart
```

Valida:

- header;
- package;
- archive interno;
- round-trip de serialização.

### Backup Service

```bash
flutter test \
test/study/brain/backup/brain_backup_service_test.dart
```

Valida:

- exportação;
- restauração;
- ausência de plaintext;
- tombstones;
- proteção contra downgrade;
- recuperação do conteúdo original.

### Toda a pasta

```bash
flutter test \
test/study/brain/backup
```

### Regressão do Brain

```bash
flutter test \
test/study/brain
```

---

## Definition of Done — Fase 04

```text
[x] formato .evbrain definido
[x] header versionado
[x] archive interno definido
[x] compressão implementada
[x] criptografia implementada
[x] Master Key fora do arquivo
[x] exportToString
[x] exportToFile
[x] importFromString
[x] importFromFile
[x] tombstones preservados
[x] versões locais mais novas protegidas
[x] conteúdo não aparece em plaintext
[x] testes passando
```

---

## Próxima etapa

```text
Fase 05 — Local / Cloud
```

A Fase 05 não sincroniza ainda.

Ela define apenas se o Cérebro está em:

```text
LOCAL
ou
CLOUD
```

O Supabase E2EE só entra na Fase 06.
