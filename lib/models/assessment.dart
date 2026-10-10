import 'question.dart';

enum AssessmentStatus { draft, scheduled, completed }

class Assessment {
  const Assessment({
    this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.dateLabel,
    required this.status,
    required this.totalQuestions,
    required this.correctedStudents,
    required this.totalStudents,
    this.questions = const [], // Adicionado como opcional com lista vazia por defeito
  });

  final String? id; 
  final String title;
  final String subject;
  final String className;
  final String dateLabel;
  final AssessmentStatus status;
  final int totalQuestions;
  final int correctedStudents;
  final int totalStudents;
  final List<Question> questions; // Adicionada a lista de questões

  factory Assessment.fromMap(String id, Map<String, dynamic> map) {
    return Assessment(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      className: map['className'] ?? '',
      dateLabel: map['dateLabel'] ?? '',
      status: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AssessmentStatus.draft,
      ),
      totalQuestions: map['totalQuestions']?.toInt() ?? 0,
      correctedStudents: map['correctedStudents']?.toInt() ?? 0,
      totalStudents: map['totalStudents']?.toInt() ?? 0,
      questions: map['questions'] != null 
          ? (map['questions'] as List).map((q) => Question.fromMap(q)).toList()
          : [], // Lê a lista do Firebase
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'className': className,
      'dateLabel': dateLabel,
      'status': status.name,
      'totalQuestions': totalQuestions,
      'correctedStudents': correctedStudents,
      'totalStudents': totalStudents,
      'questions': questions.map((q) => q.toMap()).toList(), // Grava a lista no Firebase
    };
  }

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