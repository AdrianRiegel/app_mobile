import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.verticalPadding = 14,
    this.horizontalPadding,
    this.foregroundColor = AppColors.accent,
    this.borderColor = AppColors.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double verticalPadding;
  final double? horizontalPadding;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: BorderSide(color: borderColor),
      padding: horizontalPadding == null
          ? EdgeInsets.symmetric(vertical: verticalPadding)
          : EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    final labelWidget = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );

    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: labelWidget)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: labelWidget,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
