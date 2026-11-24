import 'package:app_mobile/Screens/question_form_screen.dart';
import 'package:app_mobile/models/question.dart';
import 'package:app_mobile/services/csv_import_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Questões com quantidade variável de alternativas, de 2 a 5 (#64).
void main() {
  group('QuestionFormScreen — quantidade de alternativas', () {
    /// Abre a página e devolve uma função que lê o resultado ao fechar.
    Future<List<Question>? Function()> abrirPagina(
      WidgetTester tester, {
      Question? inicial,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      List<Question>? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado = await Navigator.push<List<Question>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionFormScreen(
                      questionNumber: 1,
                      initialQuestion: inicial,
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return () => resultado;
    }

    Future<void> preencher(
      WidgetTester tester,
      List<String> alternativas,
    ) async {
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Enunciado');
      for (final (i, texto) in alternativas.indexed) {
        await tester.enterText(campos.at(i + 1), texto);
      }
    }

    testWidgets('começa com 4 e permite chegar a 5 alternativas', (
      tester,
    ) async {
      final resultado = await abrirPagina(tester);
      expect(find.text('Alternativa D'), findsOneWidget);
      expect(find.text('Alternativa E'), findsNothing);

      await tester.tap(find.text('Adicionar alternativa E'));
      await tester.pumpAndSettle();
      expect(find.text('Alternativa E'), findsOneWidget);
      // Chegou ao máximo: não oferece uma 6ª.
      expect(find.textContaining('Adicionar alternativa'), findsNothing);

      await preencher(tester, ['1', '2', '3', '4', '5']);
      await tester.tap(find.byTooltip('Marcar alternativa E como correta'));
      await tester.tap(find.text('Adicionar à prova'));
      await tester.pumpAndSettle();

      final questao = resultado()!.single;
      expect(questao.options, ['1', '2', '3', '4', '5']);
      expect(questao.correctLetter, 'E');
    });

    testWidgets('permite reduzir até 2 alternativas', (tester) async {
      final resultado = await abrirPagina(tester);

      await tester.tap(find.byTooltip('Remover alternativa D'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remover alternativa C'));
      await tester.pumpAndSettle();
      // No mínimo não há mais botão de remover.
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);

      await preencher(tester, ['Verdadeiro', 'Falso']);
      await tester.tap(find.text('Adicionar à prova'));
      await tester.pumpAndSettle();

      expect(resultado()!.single.options, ['Verdadeiro', 'Falso']);
    });

    testWidgets('remover outra alternativa mantém a correta marcada', (
      tester,
    ) async {
      final resultado = await abrirPagina(
        tester,
        inicial: const Question(
          statement: 'Q',
          options: ['a', 'b', 'c', 'd'],
          correctIndex: 3,
        ),
      );

      await tester.tap(find.byTooltip('Remover alternativa A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      final questao = resultado()!.single;
      expect(questao.options, ['b', 'c', 'd']);
      expect(questao.options[questao.correctIndex], 'd');
    });

    testWidgets('remover a correta volta a marcação para a primeira', (
      tester,
    ) async {
      final resultado = await abrirPagina(
        tester,
        inicial: const Question(
          statement: 'Q',
          options: ['a', 'b', 'c'],
          correctIndex: 1,
        ),
      );

      await tester.tap(find.byTooltip('Remover alternativa B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      expect(resultado()!.single.correctIndex, 0);
    });

    testWidgets('edição de questão com 5 alternativas abre todas', (
      tester,
    ) async {
      await abrirPagina(
        tester,
        inicial: const Question(
          statement: 'Q',
          options: ['a', 'b', 'c', 'd', 'e'],
          correctIndex: 4,
        ),
      );
      expect(find.text('e'), findsOneWidget);
      expect(find.textContaining('Adicionar alternativa'), findsNothing);
    });
  });

  group('CsvImportService.parseProofQuestions — 5ª alternativa', () {
    test('com cabeçalho, a coluna e é opcional', () {
      const csv =
          'enunciado;a;b;c;d;e;correta\n'
          'Cinco;1;2;3;4;5;E\n'
          'Quatro;1;2;3;4;;D';
      final res = CsvImportService.parseProofQuestions(csv);
      expect(res.erros, isEmpty);
      expect(res.questoes.first.options, hasLength(5));
      expect(res.questoes.first.correctLetter, 'E');
      expect(res.questoes.last.options, hasLength(4));
    });

    test('sem cabeçalho, linhas com 7 colunas têm 5 alternativas', () {
      const csv =
          'Cinco;1;2;3;4;5;E\n'
          'Quatro;1;2;3;4;B';
      final res = CsvImportService.parseProofQuestions(csv);
      expect(res.erros, isEmpty);
      expect(res.questoes.first.options, ['1', '2', '3', '4', '5']);
      expect(res.questoes.first.correctLetter, 'E');
      expect(res.questoes.last.options, hasLength(4));
      expect(res.questoes.last.correctLetter, 'B');
    });

    test('correta E sem a 5ª alternativa continua inválida', () {
      const csv = 'enunciado;a;b;c;d;e;correta\nQ;1;2;3;4;;E';
      final res = CsvImportService.parseProofQuestions(csv);
      expect(res.questoes, isEmpty);
      expect(res.erros.single, contains('(use A, B, C ou D)'));
    });
  });
}
