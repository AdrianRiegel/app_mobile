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
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double verticalPadding;
  final double? horizontalPadding;
  final double fontSize;

  /// Exibe um spinner no lugar do ícone e desabilita o botão.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: context.colors.accent,
      foregroundColor: Colors.white,
      // Durante o carregamento o botão mantém a cor de destaque.
      disabledBackgroundColor:
          loading ? context.colors.accent : context.colors.accentLight,
      disabledForegroundColor: loading ? Colors.white : null,
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
    final callback = loading ? null : onPressed;

    final Widget button;
    if (loading) {
      button = ElevatedButton.icon(
        onPressed: null,
        style: style,
        icon: const ButtonSpinner(color: Colors.white),
        label: labelWidget,
      );
    } else if (icon == null) {
      button = ElevatedButton(onPressed: callback, style: style, child: labelWidget);
    } else {
      button = ElevatedButton.icon(
        onPressed: callback,
        style: style,
        icon: Icon(icon, size: 18),
        label: labelWidget,
      );
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Spinner pequeno do tamanho de um ícone de botão.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
