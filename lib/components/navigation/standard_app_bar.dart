import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.showDivider = true,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  final bool showDivider;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (showDivider ? 1 : 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 20),
        color: AppColors.text,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      bottom: showDivider
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            )
          : null,
    );
  }
}
