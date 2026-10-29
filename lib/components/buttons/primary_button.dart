import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.verticalPadding = 16,
    this.horizontalPadding,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double verticalPadding;
  final double? horizontalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: context.colors.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: context.colors.accentLight,
      elevation: 0,
      padding: horizontalPadding == null
          ? EdgeInsets.symmetric(vertical: verticalPadding)
          : EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    final labelWidget = Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
    );

    final button = icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: labelWidget)
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: labelWidget,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
