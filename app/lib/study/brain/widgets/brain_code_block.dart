import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrainCodeBlock extends StatefulWidget {
  const BrainCodeBlock({super.key, required this.language, required this.code});

  final String language;
  final String code;

  @override
  State<BrainCodeBlock> createState() => _BrainCodeBlockState();
}

class _BrainCodeBlockState extends State<BrainCodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF111315)
        : const Color(0xFFF7F8FA);
    final headerBackground = isDark
        ? const Color(0xFF191B1E)
        : const Color(0xFFEEF0F3);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);
    final textColor = isDark
        ? const Color(0xFFE9EAEC)
        : const Color(0xFF202124);
    final mutedColor = isDark
        ? const Color(0xFFA7ABB2)
        : const Color(0xFF60646C);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(left: 14, right: 7),
            decoration: BoxDecoration(
              color: headerBackground,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.language,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _copy,
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16,
                  ),
                  label: Text(_copied ? 'Copiado!' : 'Copiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: _copied ? Colors.green : mutedColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
