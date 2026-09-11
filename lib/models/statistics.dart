/// Modelos de dados usados nas telas de Estatísticas e Relatórios.
///
/// Assim como o restante da primeira entrega, os valores são simulados
/// (ver [../data/mock_statistics.dart]). Nenhuma informação vem de backend.
library;

/// Percentual de acertos de uma questão específica de uma prova.
class QuestionStat {
  const QuestionStat({required this.number, required this.correctRate})
    : assert(correctRate >= 0 && correctRate <= 100);

  /// Número da questão exibido como `Q{number}`.
  final int number;

  /// Percentual de alunos que acertaram a questão (0 a 100).
  final int correctRate;
}

/// Estatísticas consolidadas de uma prova/avaliação.
class ExamStatistics {
  const ExamStatistics({
    required this.assessmentTitle,
    required this.shortLabel,
    required this.className,
    required this.subject,
    required this.averageScore,
    required this.hardestQuestion,
    required this.questions,
  });

  /// Cria estatísticas simuladas a partir dos dados de uma avaliação,
  /// para quando não há um registro fixo em [mockClassStatistics].
  factory ExamStatistics.demo({
    required String assessmentTitle,
    required String shortLabel,
    required String className,
    required String subject,
    required int totalQuestions,
    int seed = 7,
  }) {
    final questions = List<QuestionStat>.generate(totalQuestions, (index) {
      final number = index + 1;
      final rate = 45 + ((number * 37 + seed * 13) % 55); // 45..99
      return QuestionStat(number: number, correctRate: rate);
    });
    return ExamStatistics(
      assessmentTitle: assessmentTitle,
      shortLabel: shortLabel,
      className: className,
      subject: subject,
      averageScore: _average(questions),
      hardestQuestion: 'Q${_hardest(questions).number}',
      questions: questions,
    );
  }

  /// Título completo da avaliação (ex.: `Avaliação bimestral — Cap. 4`).
  final String assessmentTitle;

  /// Rótulo curto usado no cabeçalho da tela (ex.: `Cap. 4`).
  final String shortLabel;

  /// Turma à qual a prova pertence (ex.: `3º Ano A`).
  final String className;

  /// Disciplina da prova (ex.: `Matemática`).
  final String subject;

  /// Percentual médio de acerto considerando todas as questões (0 a 100).
  final int averageScore;

  /// Rótulo da questão com menor índice de acerto (ex.: `Q7`).
  final String hardestQuestion;

  /// Desempenho por questão, na ordem da prova.
  final List<QuestionStat> questions;

  static int _average(List<QuestionStat> questions) {
    if (questions.isEmpty) return 0;
    final total = questions.fold<int>(0, (sum, q) => sum + q.correctRate);
    return (total / questions.length).round();
  }

  static QuestionStat _hardest(List<QuestionStat> questions) {
    return questions.reduce(
      (a, b) => a.correctRate <= b.correctRate ? a : b,
    );
  }
}

/// Agrupa as provas de uma mesma turma para a tela de estatísticas gerais.
class ClassStatistics {
  const ClassStatistics({
    required this.className,
    required this.subject,
    required this.exams,
  });

  final String className;
  final String subject;
  final List<ExamStatistics> exams;

  /// Nome exibido na lista (ex.: `3º Ano A - Matemática`).
  String get displayName => '$className - $subject';

  /// Média de acerto da turma considerando todas as provas cadastradas.
  int get averageScore {
    if (exams.isEmpty) return 0;
    final total = exams.fold<int>(0, (sum, e) => sum + e.averageScore);
    return (total / exams.length).round();
  }
}
