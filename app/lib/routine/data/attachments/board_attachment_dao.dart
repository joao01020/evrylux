// ============================================================
// BOARD ATTACHMENT DAO - ROUTINE DATA BRIDGE
// ============================================================
//
// A implementação SQLite real fica em:
//
// lib/core/database/daos/board_attachment_dao.dart
//
// Este arquivo existe para manter o módulo routine/data isolado
// da estrutura física do core.
//
// Assim, telas/repositories do módulo Routine podem importar:
//
// routine/data/attachments/board_attachment_dao.dart
//
// sem duplicar a implementação do banco.
//
// ============================================================

export '../../../core/database/daos/board_attachment_dao.dart';
