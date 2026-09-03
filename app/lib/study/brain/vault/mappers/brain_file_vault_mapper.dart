import '../../models/brain_concept.dart';
import '../../models/brain_file.dart';
import '../../models/brain_source.dart';

// ============================================================
// BRAIN FILE VAULT MAPPER
// ============================================================
//
// Faz a ponte entre:
//
// BrainFile
//    ↓
// Map<String, dynamic>
//    ↓
// BrainVaultService
//
// e:
//
// BrainVaultDecodedPayload.data
//    ↓
// BrainFile
//
// IMPORTANTE:
//
// Este mapper NÃO:
//
// - criptografa;
// - grava arquivos;
// - acessa Supabase;
// - acessa SyncQueue;
// - gera objectId.
//
// Ele apenas converte modelos.
//
// FASE 13:
//
// - concepts continuam serializados dentro da nota;
// - sources também passam a ser serializadas dentro da nota;
// - payloads antigos sem sources continuam válidos;
// - sources ficam dentro do payload criptografado do Vault.
//
// ============================================================

class BrainFileVaultMapper {
  const BrainFileVaultMapper();

  // ============================================================
  // MODEL VERSION
  // ============================================================
  //
  // Mantemos modelVersion = 1 porque sources é um campo opcional
  // e retrocompatível.
  //
  // Payload antigo:
  //
  // {
  //   ...
  //   "concepts": [...]
  // }
  //
  // continua válido e será interpretado com:
  //
  // sources = []
  //
  // NÃO confundir com:
  //
  // crypto_version
  // object_version
  // vault format version
  //
  // ============================================================

  static const int modelVersion = 1;

  // ============================================================
  // TO VAULT DATA
  // ============================================================

  Map<String, dynamic> toVaultData(BrainFile file) {
    final createdAt = file.createdAt.toUtc();

    final updatedAt = file.updatedAt.toUtc();

    return {
      'model': 'brain_file',
      'model_version': modelVersion,

      // ========================================================
      // LEGACY / CURRENT MODEL
      // ========================================================
      //
      // topic ainda existe por compatibilidade.
      //
      // Mais tarde ele deixará de ser obrigatório.
      //
      // ========================================================
      'topic': file.topic,

      'title': file.title,

      'content': file.content,

      // ========================================================
      // LEGACY PATH
      // ========================================================
      //
      // O path NÃO é identidade do Vault.
      //
      // Ele é preservado temporariamente porque controllers,
      // reviews e código legado ainda dependem dele.
      //
      // Como este Map será criptografado, o caminho não fica
      // exposto no .evobj.
      //
      // ========================================================
      'legacy_path': file.path,

      // ========================================================
      // DATES
      // ========================================================
      'created_at': createdAt.toIso8601String(),

      'updated_at': updatedAt.toIso8601String(),

      // ========================================================
      // CONCEPTS
      // ========================================================
      'concepts': file.concepts
          .map((concept) {
            return concept.toJson();
          })
          .toList(growable: false),

      // ========================================================
      // SOURCES
      // ========================================================
      //
      // FASE 13 — FONTES DO CONHECIMENTO
      //
      // title/reference/author/note ficam apenas dentro do payload
      // do Vault, que será criptografado pelo BrainVaultService.
      //
      // ========================================================
      'sources': file.sources
          .map((source) {
            return source.toJson();
          })
          .toList(growable: false),
    };
  }

  // ============================================================
  // FROM VAULT DATA
  // ============================================================

  BrainFile fromVaultData(Map<String, dynamic> data) {
    _validateModel(data);

    final topic = _parseString(data['topic']);

    final title = _parseString(data['title']);

    final content = _parseString(data['content']);

    final path = _parseString(data['legacy_path']);

    final createdAt = _parseRequiredDate(
      data['created_at'],
      fieldName: 'created_at',
    );

    final updatedAt = _parseRequiredDate(
      data['updated_at'],
      fieldName: 'updated_at',
    );

    final concepts = _parseConcepts(data['concepts']);

    final sources = _parseSources(data['sources']);

    if (updatedAt.isBefore(createdAt)) {
      throw const FormatException(
        'BrainFile inválido: updated_at é anterior a created_at.',
      );
    }

    return BrainFile(
      topic: topic,
      title: title,
      path: path,
      content: content,
      concepts: concepts,
      sources: sources,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // VALIDATE MODEL
  // ============================================================

  void _validateModel(Map<String, dynamic> data) {
    final model = _parseString(data['model']);

    if (model != 'brain_file') {
      throw FormatException('Payload não representa BrainFile: $model');
    }

    final version = _parseInt(
      data['model_version'],
      fieldName: 'model_version',
    );

    if (version != modelVersion) {
      throw FormatException('Versão de BrainFile não suportada: $version');
    }
  }

  // ============================================================
  // PARSE CONCEPTS
  // ============================================================

  List<BrainConcept> _parseConcepts(dynamic raw) {
    if (raw == null) {
      return const <BrainConcept>[];
    }

    if (raw is! List) {
      throw const FormatException('Campo concepts do BrainFile é inválido.');
    }

    final result = <BrainConcept>[];

    for (final item in raw) {
      if (item is! Map) {
        throw const FormatException(
          'BrainConcept inválido dentro do BrainFile.',
        );
      }

      final concept = BrainConcept.fromJson(Map<String, dynamic>.from(item));

      result.add(concept);
    }

    return List<BrainConcept>.unmodifiable(result);
  }

  // ============================================================
  // PARSE SOURCES
  // ============================================================
  //
  // Compatibilidade:
  //
  // payload antigo sem "sources"
  //
  // -> []
  //
  // ============================================================

  List<BrainSource> _parseSources(dynamic raw) {
    if (raw == null) {
      return const <BrainSource>[];
    }

    if (raw is! List) {
      throw const FormatException('Campo sources do BrainFile é inválido.');
    }

    final result = <BrainSource>[];

    for (final item in raw) {
      if (item is! Map) {
        throw const FormatException(
          'BrainSource inválida dentro do BrainFile.',
        );
      }

      final source = BrainSource.fromJson(Map<String, dynamic>.from(item));

      if (!source.isValid) {
        throw const FormatException(
          'BrainSource inválida dentro do BrainFile.',
        );
      }

      result.add(source);
    }

    return List<BrainSource>.unmodifiable(result);
  }

  // ============================================================
  // PARSE STRING
  // ============================================================

  String _parseString(dynamic value) {
    return value?.toString() ?? '';
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  int _parseInt(dynamic value, {required String fieldName}) {
    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(value?.toString().trim() ?? '');

    if (parsed == null) {
      throw FormatException('$fieldName inválido no BrainFile.');
    }

    return parsed;
  }

  // ============================================================
  // PARSE REQUIRED DATE
  // ============================================================

  DateTime _parseRequiredDate(dynamic value, {required String fieldName}) {
    final parsed = DateTime.tryParse(value?.toString().trim() ?? '');

    if (parsed == null) {
      throw FormatException('$fieldName inválido no BrainFile.');
    }

    return parsed.toLocal();
  }
}
