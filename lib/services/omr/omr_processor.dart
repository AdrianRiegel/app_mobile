import 'omr_models.dart';

abstract final class OmrProcessor {
  static const double fillThreshold = 0.45;
  static const double blankThreshold = 0.20;
  static const double minContrastMargin = 0.20;

  /// Processa uma matriz de densidades onde cada linha representa uma questão
  /// e cada coluna representa uma alternativa (A, B, C, D, E).
  static OmrProcessingResult processDensityMatrix(
    List<List<double>> matrix, {
    List<String> options = const ['A', 'B', 'C', 'D', 'E'],
  }) {
    if (matrix.isEmpty) {
      return const OmrProcessingResult(
        isSuccessful: false,
        overallConfidence: 0.0,
        questions: [],
        needsManualReview: true,
        reviewReason: 'Nenhuma questão encontrada na imagem do cartão',
      );
    }

    final questionReadings = <QuestionReading>[];
    var totalConfidence = 0.0;
    var hasMultipleMarked = false;
    var hasAmbiguous = false;

    for (var i = 0; i < matrix.length; i++) {
      final densities = matrix[i];
      final bubbles = <BubbleReading>[];

      for (var j = 0; j < densities.length && j < options.length; j++) {
        final ratio = densities[j].clamp(0.0, 1.0);
        bubbles.add(
          BubbleReading(
            questao: i + 1,
            alternativa: options[j],
            fillRatio: ratio,
            isMarked: ratio >= fillThreshold,
          ),
        );
      }

      // Ordena as bolhas por preenchimento decrescente
      final sorted = List<BubbleReading>.from(bubbles)
        ..sort((a, b) => b.fillRatio.compareTo(a.fillRatio));

      final highest = sorted.isNotEmpty ? sorted[0] : null;
      final secondHighest = sorted.length > 1 ? sorted[1] : null;

      String? detectedLetter;
      var isBlank = false;
      var isMultiple = false;
      var isAmbiguous = false;
      var confidence = 1.0;

      if (highest == null || highest.fillRatio < blankThreshold) {
        // Questão totalmente em branco
        isBlank = true;
        detectedLetter = null;
        confidence = 0.95;
      } else if (highest.fillRatio >= fillThreshold) {
        if (secondHighest != null && secondHighest.fillRatio >= fillThreshold) {
          // Marcação dupla detectada
          isMultiple = true;
          hasMultipleMarked = true;
          detectedLetter = highest.alternativa;
          confidence = 0.40;
        } else if (secondHighest != null &&
            (highest.fillRatio - secondHighest.fillRatio) < minContrastMargin) {
          // Contraste insuficiente / rasura
          isAmbiguous = true;
          hasAmbiguous = true;
          detectedLetter = highest.alternativa;
          confidence = 0.60;
        } else {
          // Marcação clara e unívoca
          detectedLetter = highest.alternativa;
          confidence = (highest.fillRatio * 0.5) + 0.5; // Entre 0.72 e 1.0
        }
      } else {
        // Marcação fraca/ambígua entre blankThreshold e fillThreshold
        isAmbiguous = true;
        hasAmbiguous = true;
        detectedLetter = highest.alternativa;
        confidence = 0.50;
      }

      final reading = QuestionReading(
        questao: i + 1,
        detectedLetter: detectedLetter,
        isAmbiguous: isAmbiguous,
        isMultipleMarked: isMultiple,
        isBlank: isBlank,
        confidence: confidence,
        bubbles: bubbles,
      );

      questionReadings.add(reading);
      totalConfidence += confidence;
    }

    final avgConfidence = totalConfidence / questionReadings.length;
    final needsReview =
        avgConfidence < 0.70 || hasMultipleMarked || hasAmbiguous;

    String? reviewReason;
    if (hasMultipleMarked) {
      reviewReason = 'Há questões com múltiplas alternativas marcadas';
    } else if (hasAmbiguous) {
      reviewReason = 'Há marcações ambíguas ou rasuras identificadas';
    } else if (avgConfidence < 0.70) {
      reviewReason = 'Confiança geral da leitura abaixo do limite seguro (70%)';
    }

    return OmrProcessingResult(
      isSuccessful: true,
      overallConfidence: (avgConfidence * 100).round() / 100,
      questions: questionReadings,
      needsManualReview: needsReview,
      reviewReason: reviewReason,
    );
  }

  /// Constrói uma matriz sintética baseada em respostas esperadas para testes e simulações.
  static List<List<double>> createDensityMatrix({
    required List<String?> answers,
    List<String> options = const ['A', 'B', 'C', 'D', 'E'],
    Map<int, String>? duplicateMarks,
    Set<int>? ambiguousQuestions,
  }) {
    final matrix = <List<double>>[];

    for (var i = 0; i < answers.length; i++) {
      final answer = answers[i];
      final isAmbiguous = ambiguousQuestions?.contains(i + 1) ?? false;
      final duplicateOption = duplicateMarks?[i + 1];

      final row = <double>[];
      for (final opt in options) {
        if (opt == answer) {
          row.add(isAmbiguous ? 0.35 : 0.85); // 0.35 = ambíguo, 0.85 = preenchido
        } else if (opt == duplicateOption) {
          row.add(0.80); // Marcação dupla
        } else {
          row.add(0.05); // Bolha em branco
        }
      }
      matrix.add(row);
    }

    return matrix;
  }
}
