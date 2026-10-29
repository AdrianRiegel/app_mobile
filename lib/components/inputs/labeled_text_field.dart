import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.dense = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool dense;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

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
        SizedBox(height: dense ? 6 : 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: dense ? 13 : 14,
            color: enabled ? context.colors.text : context.colors.muted,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(
              fontSize: dense ? 13 : null,
              color: context.colors.muted.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: enabled ? context.colors.input : context.colors.surface,
            isDense: dense,
            contentPadding: dense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: context.colors.border.withValues(alpha: 0.5),
              ),
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
