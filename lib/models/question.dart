/// Representa uma questão com enunciado, alternativas e índice da correta.
class Question {
  const Question({
    required this.statement,
    required this.options,
    required this.correctIndex,
  });

  final String statement;
  final List<String> options;
  final int correctIndex;

  /// Retorna a letra correspondente à alternativa correta (A, B, C, D, ...).
  String get correctLetter => String.fromCharCode(65 + correctIndex);

  Question copyWith({
    String? statement,
    List<String>? options,
    int? correctIndex,
  }) {
    return Question(
      statement: statement ?? this.statement,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
    );
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      statement: map['statement'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? const []),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statement': statement,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}
