import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AssessmentStatus { draft, scheduled, completed }

extension AssessmentStatusBadge on AssessmentStatus {
  Color badgeBackground(AppColors colors) {
    switch (this) {
      case AssessmentStatus.completed:
        return colors.successLight;
      case AssessmentStatus.scheduled:
        return colors.accentLight;
      case AssessmentStatus.draft:
        return colors.neutralLight;
    }
  }

  Color badgeForeground(AppColors colors) {
    switch (this) {
      case AssessmentStatus.completed:
        return colors.success;
      case AssessmentStatus.scheduled:
        return colors.accent;
      case AssessmentStatus.draft:
        return colors.muted;
    }
  }

  /// Rótulo padronizado da situação da avaliação no singular.
  String get label {
    switch (this) {
      case AssessmentStatus.draft:
        return 'Rascunho';
      case AssessmentStatus.scheduled:
        return 'Agendada';
      case AssessmentStatus.completed:
        return 'Concluída';
    }
  }

  /// Rótulo padronizado no plural para filtros e listagens.
  String get pluralLabel {
    switch (this) {
      case AssessmentStatus.draft:
        return 'Rascunhos';
      case AssessmentStatus.scheduled:
        return 'Agendadas';
      case AssessmentStatus.completed:
        return 'Concluídas';
    }
  }

  bool get isDraft => this == AssessmentStatus.draft;
  bool get isScheduled => this == AssessmentStatus.scheduled;
  bool get isCompleted => this == AssessmentStatus.completed;
}

/// Resposta esperada de uma questão. [alternativaCorreta] fica `null`
/// enquanto o gabarito ainda não foi configurado.
class QuestaoGabarito {
  const QuestaoGabarito({
    required this.questao,
    this.alternativaCorreta,
    this.peso = 1.0,
  });

  final int questao;
  final String? alternativaCorreta;
  final double peso;
}

class Assessment {
  const Assessment({
    this.id = '',
    this.turmaId = '',
    this.gabarito = const [],
    required this.title,
    required this.subject,
    required this.className,
    required this.dateLabel,
    this.dataAplicacao,
    required this.status,
    required this.totalQuestions,
    required this.correctedStudents,
    required this.totalStudents,
  });

  final String id;
  final String turmaId;
  final List<QuestaoGabarito> gabarito;
  final String title;
  final String subject;
  final String className;
  final String dateLabel;
  final DateTime? dataAplicacao;
  final AssessmentStatus status;
  final int totalQuestions;
  final int correctedStudents;
  final int totalStudents;

  bool get isDraft => status.isDraft;
  bool get isScheduled => status.isScheduled;
  bool get isCompleted => status.isCompleted;

  bool get gabaritoConfigurado =>
      gabarito.isNotEmpty &&
      gabarito.every((questao) => questao.alternativaCorreta != null);

  /// Rótulo padronizado da situação da prova.
  String get statusLabel => status.label;

  /// Alias semântico em português para a situação da prova.
  String get situacao => status.label;
}
