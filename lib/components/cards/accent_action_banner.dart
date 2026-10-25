import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AccentActionBanner extends StatelessWidget {
  const AccentActionBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.qr_code_scanner,
    this.padding = 12,
    this.titleFontSize = 12,
    this.iconSize = 26,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final double padding;
  final double titleFontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.onAccentMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: iconSize),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
