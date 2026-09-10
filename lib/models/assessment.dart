enum AssessmentStatus { draft, scheduled, completed }

class Assessment {
  const Assessment({
    required this.title,
    required this.subject,
    required this.className,
    required this.dateLabel,
    required this.status,
    required this.totalQuestions,
    required this.correctedStudents,
    required this.totalStudents,
  });

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
