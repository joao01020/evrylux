import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/models/brain_concept.dart';
import 'package:EVRYLUX/study/brain/models/brain_file.dart';
import 'package:EVRYLUX/study/brain/models/brain_source.dart';
import 'package:EVRYLUX/study/brain/vault/mappers/brain_file_vault_mapper.dart';

void main() {
  group('BrainFileVaultMapper', () {
    const mapper = BrainFileVaultMapper();

    test('converte BrainFile para Map corretamente', () {
      final createdAt = DateTime(2026, 9, 2, 10, 30);

      final updatedAt = DateTime(2026, 9, 2, 11, 45);

      final file = BrainFile(
        topic: 'Negociação',
        title: 'Perguntas abertas',
        path: '/tmp/ghost_brain/negociacao/perguntas.md',
        content: 'Perguntas abertas ajudam a entender melhor a outra pessoa.',
        concepts: const [],
        sources: const [],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final data = mapper.toVaultData(file);

      expect(data['model'], 'brain_file');

      expect(data['model_version'], BrainFileVaultMapper.modelVersion);

      expect(data['topic'], 'Negociação');

      expect(data['title'], 'Perguntas abertas');

      expect(data['content'], file.content);

      expect(data['legacy_path'], file.path);

      expect(data['created_at'], createdAt.toUtc().toIso8601String());

      expect(data['updated_at'], updatedAt.toUtc().toIso8601String());

      expect(data['concepts'], isA<List>());

      expect(data['sources'], isA<List>());
    });

    test('round trip preserva BrainFile', () {
      final createdAt = DateTime(2026, 8, 20, 9);

      final updatedAt = DateTime(2026, 8, 25, 15, 30);

      final original = BrainFile(
        topic: 'Hábitos',
        title: 'Ambiente',
        path: '/tmp/ghost_brain/habitos/ambiente.md',
        content: 'O ambiente influencia o comportamento.',
        concepts: const [],
        sources: const [],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final data = mapper.toVaultData(original);

      final restored = mapper.fromVaultData(data);

      expect(restored.topic, original.topic);

      expect(restored.title, original.title);

      expect(restored.path, original.path);

      expect(restored.content, original.content);

      expect(restored.createdAt.toUtc(), original.createdAt.toUtc());

      expect(restored.updatedAt.toUtc(), original.updatedAt.toUtc());

      expect(restored.concepts.length, original.concepts.length);

      expect(restored.sources.length, original.sources.length);
    });

    test('round trip preserva conceitos', () {
      final concept = BrainConcept(
        id: 'concept-001',
        title: 'Pergunta aberta',
        description:
            'Perguntas que não podem ser respondidas apenas com sim ou não.',
        type: BrainConceptType.concept,
      );

      final original = BrainFile(
        topic: 'Vendas',
        title: 'Negociação',
        path: '/tmp/negociacao.md',
        content: 'Conteúdo da nota.',
        concepts: [concept],
        sources: const [],
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 2),
      );

      final restored = mapper.fromVaultData(mapper.toVaultData(original));

      expect(restored.concepts.length, 1);

      final restoredConcept = restored.concepts.first;

      expect(restoredConcept.id, concept.id);

      expect(restoredConcept.title, concept.title);

      expect(restoredConcept.description, concept.description);

      expect(restoredConcept.type, concept.type);
    });

    test('round trip preserva fontes do conhecimento', () {
      final createdAt = DateTime(2026, 9, 3, 8);

      final updatedAt = DateTime(2026, 9, 3, 9);

      final publishedAt = DateTime(2025, 4, 10);

      final source = BrainSource(
        id: 'source-001',
        type: BrainSourceType.url,
        title: 'cppreference - Pointers',
        reference: 'https://en.cppreference.com/w/cpp/language/pointer',
        author: 'cppreference',
        publishedAt: publishedAt,
        note: 'Referência usada para revisar ponteiros.',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final original = BrainFile(
        topic: '',
        title: 'Ponteiros em C++',
        path: '/tmp/ponteiros.md',
        content: 'Ponteiros armazenam endereços de memória.',
        concepts: const [],
        sources: [source],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final data = mapper.toVaultData(original);

      expect(data['sources'], isA<List>());

      expect((data['sources'] as List).length, 1);

      final restored = mapper.fromVaultData(data);

      expect(restored.sources.length, 1);

      final restoredSource = restored.sources.first;

      expect(restoredSource.id, source.id);

      expect(restoredSource.type, source.type);

      expect(restoredSource.title, source.title);

      expect(restoredSource.reference, source.reference);

      expect(restoredSource.author, source.author);

      expect(restoredSource.publishedAt?.toUtc(), source.publishedAt?.toUtc());

      expect(restoredSource.note, source.note);

      expect(restoredSource.createdAt.toUtc(), source.createdAt.toUtc());

      expect(restoredSource.updatedAt.toUtc(), source.updatedAt.toUtc());
    });

    test('aceita payload antigo sem sources', () {
      final restored = mapper.fromVaultData({
        'model': 'brain_file',
        'model_version': BrainFileVaultMapper.modelVersion,
        'topic': '',
        'title': 'Nota antiga',
        'content': 'Conteúdo legado.',
        'legacy_path': '/tmp/nota_antiga.md',
        'created_at': DateTime(2026, 8, 1).toUtc().toIso8601String(),
        'updated_at': DateTime(2026, 8, 2).toUtc().toIso8601String(),
        'concepts': [],
      });

      expect(restored.sources, isEmpty);
    });

    test('rejeita sources com formato inválido', () {
      expect(() {
        mapper.fromVaultData({
          'model': 'brain_file',
          'model_version': BrainFileVaultMapper.modelVersion,
          'topic': '',
          'title': 'Teste',
          'content': 'Teste',
          'legacy_path': '/tmp/teste.md',
          'created_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'updated_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'concepts': [],
          'sources': 'isso não é uma lista',
        });
      }, throwsA(isA<FormatException>()));
    });

    test('rejeita source inválida dentro da lista', () {
      expect(() {
        mapper.fromVaultData({
          'model': 'brain_file',
          'model_version': BrainFileVaultMapper.modelVersion,
          'topic': '',
          'title': 'Teste',
          'content': 'Teste',
          'legacy_path': '/tmp/teste.md',
          'created_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'updated_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'concepts': [],
          'sources': ['source inválida'],
        });
      }, throwsA(isA<FormatException>()));
    });

    test('aceita topic vazio para futura remoção do Tema', () {
      final original = BrainFile(
        topic: '',
        title: 'Anotação sem tema',
        path: '/tmp/anotacao.md',
        content: 'Conteúdo sem tema obrigatório.',
        concepts: const [],
        sources: const [],
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      );

      final restored = mapper.fromVaultData(mapper.toVaultData(original));

      expect(restored.topic, '');

      expect(restored.title, original.title);
    });

    test('rejeita model incorreto', () {
      expect(() {
        mapper.fromVaultData({'model': 'outro_model', 'model_version': 1});
      }, throwsA(isA<FormatException>()));
    });

    test('rejeita model_version não suportada', () {
      expect(() {
        mapper.fromVaultData({'model': 'brain_file', 'model_version': 999});
      }, throwsA(isA<FormatException>()));
    });

    test('rejeita concepts com formato inválido', () {
      expect(() {
        mapper.fromVaultData({
          'model': 'brain_file',
          'model_version': BrainFileVaultMapper.modelVersion,
          'topic': '',
          'title': 'Teste',
          'content': 'Teste',
          'legacy_path': '/tmp/teste.md',
          'created_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'updated_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'concepts': 'isso não é uma lista',
          'sources': [],
        });
      }, throwsA(isA<FormatException>()));
    });

    test('rejeita updatedAt anterior a createdAt', () {
      expect(() {
        mapper.fromVaultData({
          'model': 'brain_file',
          'model_version': BrainFileVaultMapper.modelVersion,
          'topic': '',
          'title': 'Teste',
          'content': 'Teste',
          'legacy_path': '/tmp/teste.md',
          'created_at': DateTime(2026, 9, 3).toUtc().toIso8601String(),
          'updated_at': DateTime(2026, 9, 2).toUtc().toIso8601String(),
          'concepts': [],
          'sources': [],
        });
      }, throwsA(isA<FormatException>()));
    });

    test('preserva Unicode', () {
      final source = BrainSource(
        id: 'source-unicode',
        type: BrainSourceType.other,
        title: 'Fonte Русский / 日本語',
        reference: 'Referência çãõ — Привет — 日本語',
        author: 'Autor 🧠',
        note: 'Observação 🔐',
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      );

      final original = BrainFile(
        topic: 'Idiomas',
        title: 'Português / Русский / 日本語',
        path: '/tmp/unicode.md',
        content: 'Olá çãõ — Привет — 日本語 — 🧠🔐',
        concepts: const [],
        sources: [source],
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      );

      final restored = mapper.fromVaultData(mapper.toVaultData(original));

      expect(restored.title, original.title);

      expect(restored.content, original.content);

      expect(restored.sources.single.title, source.title);

      expect(restored.sources.single.reference, source.reference);

      expect(restored.sources.single.note, source.note);
    });
  });
}
