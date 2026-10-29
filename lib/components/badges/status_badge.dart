import 'package:flutter/material.dart';

import '../../models/assessment.dart';
import '../../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required Color this.background,
    required Color this.foreground,
    this.fontSize = 9,
    this.fontWeight = FontWeight.w600,
    this.horizontalPadding = 7,
    this.verticalPadding = 3,
    this.borderRadius = 20,
  }) : status = null;

  /// Construtor padronizado para a situação/status de uma avaliação/prova.
  factory StatusBadge.assessment(
    AssessmentStatus status, {
    Key? key,
    String? label,
    double fontSize = 9,
    FontWeight fontWeight = FontWeight.w600,
    double horizontalPadding = 7,
    double verticalPadding = 3,
    double borderRadius = 20,
  }) {
    return StatusBadge._status(
      status,
      key: key,
      label: label ?? status.label,
      fontSize: fontSize,
      fontWeight: fontWeight,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      borderRadius: borderRadius,
    );
  }

  /// Alias semântico em português para a situação da prova.
  factory StatusBadge.situacao(
    AssessmentStatus status, {
    Key? key,
    String? label,
    double fontSize = 9,
    FontWeight fontWeight = FontWeight.w600,
    double horizontalPadding = 7,
    double verticalPadding = 3,
    double borderRadius = 20,
  }) => StatusBadge.assessment(
    status,
    key: key,
    label: label,
    fontSize: fontSize,
    fontWeight: fontWeight,
    horizontalPadding: horizontalPadding,
    verticalPadding: verticalPadding,
    borderRadius: borderRadius,
  );

  /// Cores definidas pela situação da prova, resolvidas no tema atual.
  const StatusBadge._status(
    AssessmentStatus this.status, {
    super.key,
    required this.label,
    required this.fontSize,
    required this.fontWeight,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  }) : background = null,
       foreground = null;

  final String label;
  final AssessmentStatus? status;
  final Color? background;
  final Color? foreground;
  final double fontSize;
  final FontWeight fontWeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: background ?? status!.badgeBackground(colors),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground ?? status!.badgeForeground(colors),
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
