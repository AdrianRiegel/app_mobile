/// Leitura individual de uma alternativa (bolha) do cartão.
class BubbleReading {
  const BubbleReading({
    required this.questao,
    required this.alternativa,
    required this.fillRatio,
    required this.isMarked,
  });

  final int questao;
  final String alternativa;
  final double fillRatio;
  final bool isMarked;
}

/// Leitura consolidada de uma questão do cartão de respostas.
class QuestionReading {
  const QuestionReading({
    required this.questao,
    this.detectedLetter,
    this.isAmbiguous = false,
    this.isMultipleMarked = false,
    this.isBlank = false,
    this.confidence = 1.0,
    required this.bubbles,
  });

  final int questao;
  final String? detectedLetter;
  final bool isAmbiguous;
  final bool isMultipleMarked;
  final bool isBlank;
  final double confidence;
  final List<BubbleReading> bubbles;

  bool get needsReview => isAmbiguous || isMultipleMarked || confidence < 0.70;

  QuestionReading copyWith({
    String? detectedLetter,
    bool? isAmbiguous,
    bool? isMultipleMarked,
    bool? isBlank,
    double? confidence,
  }) {
    return QuestionReading(
      questao: questao,
      detectedLetter: detectedLetter ?? this.detectedLetter,
      isAmbiguous: isAmbiguous ?? this.isAmbiguous,
      isMultipleMarked: isMultipleMarked ?? this.isMultipleMarked,
      isBlank: isBlank ?? this.isBlank,
      confidence: confidence ?? this.confidence,
      bubbles: bubbles,
    );
  }
}

/// Resultado do processamento de um cartão de respostas inteiro.
class OmrProcessingResult {
  const OmrProcessingResult({
    required this.isSuccessful,
    required this.overallConfidence,
    required this.questions,
    required this.needsManualReview,
    this.reviewReason,
  });

  final bool isSuccessful;
  final double overallConfidence;
  final List<QuestionReading> questions;
  final bool needsManualReview;
  final String? reviewReason;

  List<String?> get formattedAnswers =>
      questions.map((q) => q.detectedLetter).toList();
}
