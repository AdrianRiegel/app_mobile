import 'package:app_mobile/Screens/omr_review_screen.dart';
import 'package:app_mobile/services/omr/omr_processor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OmrProcessor Algoritmo OMR', () {
    test('processa matriz com respostas nítidas e alta confiança', () {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', 'C', 'E', 'B'],
      );

      final result = OmrProcessor.processDensityMatrix(matrix);

      expect(result.isSuccessful, isTrue);
      expect(result.needsManualReview, isFalse);
      expect(result.overallConfidence, greaterThanOrEqualTo(0.80));
      expect(result.formattedAnswers, ['A', 'C', 'E', 'B']);
      expect(result.questions.every((q) => !q.isAmbiguous), isTrue);
      expect(result.questions.every((q) => !q.isMultipleMarked), isTrue);
    });

    test('detecta questão em branco sem penalizar como erro de leitura', () {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', null, 'C'],
      );

      final result = OmrProcessor.processDensityMatrix(matrix);

      expect(result.questions[1].isBlank, isTrue);
      expect(result.questions[1].detectedLetter, isNull);
      expect(result.formattedAnswers, ['A', null, 'C']);
    });

    test('identifica dupla marcação e sinaliza revisão manual obrigatória', () {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', 'B'],
        duplicateMarks: {1: 'C'}, // Questão 1 marcada com A e C
      );

      final result = OmrProcessor.processDensityMatrix(matrix);

      expect(result.needsManualReview, isTrue);
      expect(result.questions[0].isMultipleMarked, isTrue);
      expect(result.reviewReason, contains('múltiplas'));
    });

    test('identifica rasura/ambiguidade e reduz índice de confiança', () {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', 'B'],
        ambiguousQuestions: {2}, // Questão 2 com preenchimento fraco
      );

      final result = OmrProcessor.processDensityMatrix(matrix);

      expect(result.needsManualReview, isTrue);
      expect(result.questions[1].isAmbiguous, isTrue);
      expect(result.reviewReason, contains('ambíguas'));
    });

    test('trata matriz vazia graciosamente', () {
      final result = OmrProcessor.processDensityMatrix([]);
      expect(result.isSuccessful, isFalse);
      expect(result.needsManualReview, isTrue);
      expect(result.questions, isEmpty);
    });
  });

  group('OmrReviewScreen Widget', () {
    testWidgets('exibe questões sinalizadas e permite confirmação após ajuste', (
      tester,
    ) async {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', 'B'],
        duplicateMarks: {1: 'C'}, // Dupla marcação na questão 1
      );
      final omrResult = OmrProcessor.processDensityMatrix(matrix);

      List<String?>? confirmedAnswers;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmedAnswers = await Navigator.push<List<String?>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OmrReviewScreen(
                      result: omrResult,
                      studentName: 'Ana Beatriz',
                    ),
                  ),
                );
              },
              child: const Text('Abrir Revisão'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Revisão'));
      await tester.pumpAndSettle();

      expect(find.text('Revisão do Cartão'), findsOneWidget);
      expect(find.text('Revisão manual necessária'), findsOneWidget);
      expect(find.text('Dupla marcação'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Professor corrige a questão 1 escolhendo a alternativa C
      await tester.tap(find.widgetWithText(ChoiceChip, 'C').first);
      await tester.pumpAndSettle();

      // Confirma a revisão
      await tester.tap(find.text('Confirmar respostas e continuar'));
      await tester.pumpAndSettle();

      expect(confirmedAnswers, isNotNull);
      expect(confirmedAnswers, ['C', 'B']);
    });
  });
}
