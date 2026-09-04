# EVRYLUX Brain Backup UI — final

This patch connects the existing `.evbrain` backup engine to the Profile UI.

## Export
- Uses FilePicker save dialog.
- Forces `.evbrain` extension.
- Calls `BrainBackupService.exportToFile()`.
- The service already performs temp-file + rename atomic write.

## Import
- Selects only `.evbrain`.
- Shows explicit confirmation.
- Calls `BrainBackupService.importFromFile()`.
- Existing service validates package, Vault ID, Master Key/key version and objects.
- Newer local object versions are preserved.
- BrainController is reloaded after restore.

## Security
The `.evbrain` file does not contain the Master Key in plaintext. A compatible Master Key must already be available locally, normally through the authorized-device / Recovery Device flow.
