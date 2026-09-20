import 'package:flutter/material.dart';

// ============================================================
// BODY MAP LEGEND
// ============================================================

class BodyMapLegend
    extends
        StatelessWidget {
  const BodyMapLegend({
    super.key,
  });

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _available = Color(
    0xFFDDF3D8,
  );

  static const Color _hover = Color(
    0xFFBCF0B4,
  );

  static const Color _configured = Color(
    0xFF9EDB94,
  );

  static const Color _selected = Color(
    0xFF72C56B,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: _available,
          label: 'Disponível',
        ),
        _LegendItem(
          color: _hover,
          label: 'Hover',
        ),
        _LegendItem(
          color: _configured,
          label: 'Configurada',
        ),
        _LegendItem(
          color: _selected,
          label: 'Selecionada',
        ),
      ],
    );
  }
}

class _LegendItem
    extends
        StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: BodyMapLegend._border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: const TextStyle(
              color: BodyMapLegend._muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
