import 'package:flutter/material.dart';

import 'brain_code_block.dart';

class BrainRichContent extends StatelessWidget {
  const BrainRichContent({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final segments = BrainRichContentParser.parse(content);
    if (segments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < segments.length; index++) ...[
          _buildSegment(context, segments[index]),
          if (index != segments.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildSegment(BuildContext context, BrainRichContentSegment segment) {
    if (segment is BrainCodeSegment) {
      return BrainCodeBlock(language: segment.language, code: segment.code);
    }

    final text = (segment as BrainTextSegment).text;
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(height: 1.55);

    return SelectableText.rich(
      TextSpan(
        children: BrainInlineTextParser.parseBold(text, baseStyle: baseStyle),
      ),
    );
  }
}

class BrainInlineTextParser {
  const BrainInlineTextParser._();

  static List<InlineSpan> parseBold(String input, {TextStyle? baseStyle}) {
    if (input.isEmpty) return const <InlineSpan>[];

    final spans = <InlineSpan>[];
    var cursor = 0;

    while (cursor < input.length) {
      final open = input.indexOf('**', cursor);
      if (open == -1) {
        spans.add(TextSpan(text: input.substring(cursor), style: baseStyle));
        break;
      }

      if (open > cursor) {
        spans.add(
          TextSpan(text: input.substring(cursor, open), style: baseStyle),
        );
      }

      final close = input.indexOf('**', open + 2);
      if (close == -1) {
        spans.add(TextSpan(text: input.substring(open), style: baseStyle));
        break;
      }

      final boldText = input.substring(open + 2, close);
      if (boldText.isEmpty) {
        spans.add(TextSpan(text: '****', style: baseStyle));
      } else {
        spans.add(
          TextSpan(
            text: boldText,
            style:
                baseStyle?.copyWith(fontWeight: FontWeight.w700) ??
                const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }

      cursor = close + 2;
    }

    return spans;
  }
}

sealed class BrainRichContentSegment {
  const BrainRichContentSegment();
}

class BrainTextSegment extends BrainRichContentSegment {
  const BrainTextSegment(this.text);
  final String text;
}

class BrainCodeSegment extends BrainRichContentSegment {
  const BrainCodeSegment({required this.language, required this.code});

  final String language;
  final String code;
}

class BrainRichContentParser {
  const BrainRichContentParser._();

  static const Set<String> supportedLanguages = {
    'bash',
    'sh',
    'shell',
    'dart',
    'python',
    'py',
    'javascript',
    'js',
    'typescript',
    'ts',
    'json',
    'sql',
    'html',
    'css',
    'cpp',
    'c',
    'java',
    'kotlin',
    'swift',
    'yaml',
    'yml',
    'text',
  };

  static List<BrainRichContentSegment> parse(String input) {
    if (input.isEmpty) return const <BrainRichContentSegment>[];

    final slashSegments = _parseSlashSyntax(input);
    final result = <BrainRichContentSegment>[];

    for (final segment in slashSegments) {
      if (segment is BrainCodeSegment) {
        result.add(segment);
      } else {
        result.addAll(_parseLegacyTags((segment as BrainTextSegment).text));
      }
    }

    return List<BrainRichContentSegment>.unmodifiable(result);
  }

  static List<BrainRichContentSegment> _parseSlashSyntax(String input) {
    final normalized = input.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final result = <BrainRichContentSegment>[];
    final textBuffer = StringBuffer();
    final codeBuffer = StringBuffer();
    String? currentLanguage;

    void flushText() {
      if (textBuffer.isEmpty) return;
      var value = textBuffer.toString();
      if (value.endsWith('\n')) value = value.substring(0, value.length - 1);
      if (value.isNotEmpty) result.add(BrainTextSegment(value));
      textBuffer.clear();
    }

    void flushCode() {
      final language = currentLanguage;
      if (language == null) return;
      var code = codeBuffer.toString();
      if (code.endsWith('\n')) code = code.substring(0, code.length - 1);
      result.add(
        BrainCodeSegment(language: _displayLanguage(language), code: code),
      );
      codeBuffer.clear();
      currentLanguage = null;
    }

    for (final line in lines) {
      final trimmed = line.trim();

      if (currentLanguage != null) {
        if (trimmed.toLowerCase() == '/end') {
          flushCode();
          continue;
        }
        codeBuffer.writeln(line);
        continue;
      }

      if (trimmed.startsWith('/') &&
          trimmed.length > 1 &&
          !trimmed.contains(' ')) {
        final language = trimmed.substring(1).toLowerCase();
        if (supportedLanguages.contains(language)) {
          flushText();
          currentLanguage = language;
          continue;
        }
      }

      textBuffer.writeln(line);
    }

    if (currentLanguage != null) {
      textBuffer.write('/$currentLanguage\n');
      textBuffer.write(codeBuffer.toString());
      currentLanguage = null;
      codeBuffer.clear();
    }

    flushText();
    return result;
  }

  static List<BrainRichContentSegment> _parseLegacyTags(String input) {
    if (input.isEmpty) return const <BrainRichContentSegment>[];

    final result = <BrainRichContentSegment>[];
    var cursor = 0;
    final openTag = RegExp(
      r'<([a-zA-Z][a-zA-Z0-9_-]*)(?:\s+([^>\n]+))?>',
      multiLine: true,
    );

    while (cursor < input.length) {
      final match = openTag.firstMatch(input.substring(cursor));
      if (match == null) {
        _addText(result, input.substring(cursor));
        break;
      }

      final absoluteStart = cursor + match.start;
      final absoluteEnd = cursor + match.end;

      if (absoluteStart > cursor) {
        _addText(result, input.substring(cursor, absoluteStart));
      }

      final rawLanguage = (match.group(1) ?? '').toLowerCase();
      final inlineCode = match.group(2)?.trim();

      if (!supportedLanguages.contains(rawLanguage)) {
        _addText(result, input.substring(absoluteStart, absoluteEnd));
        cursor = absoluteEnd;
        continue;
      }

      if (inlineCode != null && inlineCode.isNotEmpty) {
        result.add(
          BrainCodeSegment(
            language: _displayLanguage(rawLanguage),
            code: inlineCode,
          ),
        );
        cursor = absoluteEnd;
        continue;
      }

      final closeToken = '</$rawLanguage>';
      final closeIndex = input.toLowerCase().indexOf(closeToken, absoluteEnd);
      if (closeIndex == -1) {
        _addText(result, input.substring(absoluteStart, absoluteEnd));
        cursor = absoluteEnd;
        continue;
      }

      var code = input.substring(absoluteEnd, closeIndex);
      if (code.startsWith('\n')) code = code.substring(1);
      if (code.endsWith('\n')) code = code.substring(0, code.length - 1);

      result.add(
        BrainCodeSegment(language: _displayLanguage(rawLanguage), code: code),
      );

      cursor = closeIndex + closeToken.length;
    }

    return result;
  }

  static void _addText(List<BrainRichContentSegment> result, String text) {
    if (text.isNotEmpty) result.add(BrainTextSegment(text));
  }

  static String _displayLanguage(String value) {
    switch (value) {
      case 'sh':
      case 'shell':
        return 'bash';
      case 'py':
        return 'python';
      case 'js':
        return 'javascript';
      case 'ts':
        return 'typescript';
      case 'yml':
        return 'yaml';
      default:
        return value;
    }
  }
}
