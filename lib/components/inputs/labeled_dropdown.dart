import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Combo com rótulo acima, no mesmo visual do [LabeledTextField].
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.dense = false,
  });

  final String label;
  final T? value;

  /// Opções do combo: valor → texto exibido.
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: dense ? 11 : 13,
            fontWeight: FontWeight.w500,
            color: context.colors.muted,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: context.colors.surface,
          borderRadius: BorderRadius.circular(10),
          icon: Icon(Icons.keyboard_arrow_down, color: context.colors.muted),
          style: TextStyle(
            fontSize: dense ? 13 : 14,
            color: context.colors.text,
          ),
          items: [
            for (final MapEntry(:key, value: texto) in items.entries)
              DropdownMenuItem<T>(value: key, child: Text(texto)),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.input,
            isDense: dense,
            contentPadding: dense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
