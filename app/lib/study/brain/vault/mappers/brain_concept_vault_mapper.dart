import '../../models/brain_concept.dart';

// ============================================================
// BRAIN CONCEPT VAULT MAPPER
// ============================================================
//
// Converte BrainConcept <-> Map lógico.
//
// IMPORTANTE:
//
// este Map existe SOMENTE antes/depois da criptografia local.
//
// Ele nunca deve ser colocado diretamente na SyncQueue.
//
// ============================================================

class BrainConceptVaultMapper {
  const BrainConceptVaultMapper();

  // ============================================================
  // TO VAULT DATA
  // ============================================================

  Map<String, dynamic> toVaultData({
    required BrainConcept concept,
    String? sourceNotePath,
  }) {
    final id = concept.id.trim();

    final title = concept.title.trim();

    final description = concept.description.trim();

    if (id.isEmpty) {
      throw const FormatException('Conceito sem ID.');
    }

    if (title.isEmpty) {
      throw const FormatException('Conceito sem título.');
    }

    if (description.isEmpty) {
      throw const FormatException('Conceito sem descrição.');
    }

    final cleanSourceNotePath = sourceNotePath?.trim();

    return <String, dynamic>{
      'model': 'brain_concept',
      'id': id,
      'title': title,
      'description': description,
      'type': concept.type.name,
      'review_enabled': concept.reviewEnabled,
      'source_note_path':
          cleanSourceNotePath == null || cleanSourceNotePath.isEmpty
          ? null
          : cleanSourceNotePath,
    };
  }

  // ============================================================
  // FROM VAULT DATA
  // ============================================================

  BrainConcept fromVaultData(Map<String, dynamic> data) {
    final id = data['id']?.toString().trim() ?? '';

    final title = data['title']?.toString().trim() ?? '';

    final description = data['description']?.toString().trim() ?? '';

    final typeName = data['type']?.toString().trim() ?? '';

    if (id.isEmpty) {
      throw const FormatException('Conceito do Vault sem ID.');
    }

    if (title.isEmpty) {
      throw const FormatException('Conceito do Vault sem título.');
    }

    if (description.isEmpty) {
      throw const FormatException('Conceito do Vault sem descrição.');
    }

    // ==========================================================
    // TYPE
    // ==========================================================
    //
    // BrainConceptType atual possui:
    //
    // - concept
    // - question
    // - example
    // - warning
    //
    // Não existe mais BrainConceptType.keep.
    //
    // Em caso de valor desconhecido ou legado, fazemos fallback
    // seguro para BrainConceptType.concept.
    //
    // ==========================================================

    final type = BrainConceptType.values.firstWhere(
      (value) {
        return value.name == typeName;
      },
      orElse: () {
        return BrainConceptType.concept;
      },
    );

    return BrainConcept(
      id: id,
      title: title,
      description: description,
      type: type,
      reviewEnabled: BrainConcept.parseReviewEnabled(
        data['review_enabled'],
      ),
    );
  }

  // ============================================================
  // SOURCE NOTE PATH
  // ============================================================

  String? sourceNotePathFromVaultData(Map<String, dynamic> data) {
    final value = data['source_note_path']?.toString().trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}
