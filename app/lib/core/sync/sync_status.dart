enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  syncing,
  error;

  String get value {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pendingCreate:
        return 'pending_create';
      case SyncStatus.pendingUpdate:
        return 'pending_update';
      case SyncStatus.pendingDelete:
        return 'pending_delete';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.error:
        return 'error';
    }
  }

  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.pendingCreate:
        return 'Aguardando envio';
      case SyncStatus.pendingUpdate:
        return 'Alteração pendente';
      case SyncStatus.pendingDelete:
        return 'Exclusão pendente';
      case SyncStatus.syncing:
        return 'Sincronizando';
      case SyncStatus.error:
        return 'Erro de sincronização';
    }
  }

  bool get isPending {
    return this ==
            SyncStatus.pendingCreate ||
        this ==
            SyncStatus.pendingUpdate ||
        this ==
            SyncStatus.pendingDelete;
  }

  bool get isSynced =>
      this ==
      SyncStatus.synced;

  bool get hasError =>
      this ==
      SyncStatus.error;

  static SyncStatus fromValue(
    String? value,
  ) {
    switch (value) {
      case 'pending_create':
        return SyncStatus.pendingCreate;
      case 'pending_update':
        return SyncStatus.pendingUpdate;
      case 'pending_delete':
        return SyncStatus.pendingDelete;
      case 'syncing':
        return SyncStatus.syncing;
      case 'error':
        return SyncStatus.error;
      case 'synced':
      default:
        return SyncStatus.synced;
    }
  }
}
