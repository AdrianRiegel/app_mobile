class Question {
  final String statement;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.statement,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      statement: map['statement'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex']?.toInt() ?? 0,
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