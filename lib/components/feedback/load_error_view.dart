import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../buttons/secondary_button.dart';
import 'empty_state_view.dart';

/// Estado de erro ao carregar dados do banco, com botão para tentar de novo.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.cloud_off_outlined,
      iconBackground: context.colors.dangerLight,
      iconColor: context.colors.danger,
      iconSize: 32,
      title: 'Não foi possível carregar',
      message: 'Verifique sua conexão e tente novamente.',
      action: SecondaryButton(
        label: 'Tentar novamente',
        icon: Icons.refresh,
        fullWidth: false,
        verticalPadding: 13,
        horizontalPadding: 20,
        onPressed: onRetry,
      ),
    );
  }
}
