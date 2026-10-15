import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StatSummaryCard extends StatelessWidget {
  const StatSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.showBorder = true,
    this.valueFontSize = 22,
    this.padding = const EdgeInsets.all(14),
  });

  final String label;
  final String value;
  final bool showBorder;
  final double valueFontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: showBorder ? Border.all(color: AppColors.border) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
