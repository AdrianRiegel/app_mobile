import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AssessmentStatus { draft, scheduled, completed }

extension AssessmentStatusBadge on AssessmentStatus {
  Color get badgeBackground {
    switch (this) {
      case AssessmentStatus.completed:
        return AppColors.successLight;
      case AssessmentStatus.scheduled:
        return AppColors.accentLight;
      case AssessmentStatus.draft:
        return AppColors.neutralLight;
    }
  }

  Color get badgeForeground {
    switch (this) {
      case AssessmentStatus.completed:
        return AppColors.success;
      case AssessmentStatus.scheduled:
        return AppColors.accent;
      case AssessmentStatus.draft:
        return AppColors.muted;
    }
  }
}

class Assessment {
  const Assessment({
    this.id = 'prova-demo',
    this.classId = 'turma-3a',
    required this.title,
    required this.subject,
    required this.className,
    required this.dateLabel,
    required this.status,
    required this.totalQuestions,
    required this.correctedStudents,
    required this.totalStudents,
  });

  final String id;
  final String classId;
  final String title;
  final String subject;
  final String className;
  final String dateLabel;
  final AssessmentStatus status;
  final int totalQuestions;
  final int correctedStudents;
  final int totalStudents;

  String get statusLabel {
    switch (status) {
      case AssessmentStatus.draft:
        return 'Rascunho';
      case AssessmentStatus.scheduled:
        return 'Agendada';
      case AssessmentStatus.completed:
        return 'Concluída';
    }
  }
}
