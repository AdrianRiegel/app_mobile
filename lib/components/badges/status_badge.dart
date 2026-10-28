import 'package:flutter/material.dart';

import '../../models/assessment.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.fontSize = 9,
    this.fontWeight = FontWeight.w600,
    this.horizontalPadding = 7,
    this.verticalPadding = 3,
    this.borderRadius = 20,
  });

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
    return StatusBadge(
      key: key,
      label: label ?? status.label,
      background: status.badgeBackground,
      foreground: status.badgeForeground,
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
  }) =>
      StatusBadge.assessment(
        status,
        key: key,
        label: label,
        fontSize: fontSize,
        fontWeight: fontWeight,
        horizontalPadding: horizontalPadding,
        verticalPadding: verticalPadding,
        borderRadius: borderRadius,
      );

  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;
  final FontWeight fontWeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
