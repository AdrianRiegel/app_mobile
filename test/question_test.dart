import 'package:app_mobile/Screens/new_proof_screen.dart';
import 'package:app_mobile/Screens/question_form_screen.dart';
import 'package:app_mobile/services/csv_import_service.dart';
import 'package:app_mobile/models/question.dart';
import 'package:app_mobile/models/turma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Question Model', () {
    test('cria questão, converte para Map e de volta', () {
      const q = Question(
        statement: 'Qual é a capital da França?',
        options: ['Londres', 'Paris', 'Berlim', 'Madrid'],
        correctIndex: 1,
      );

      expect(q.correctLetter, 'B');

      final map = q.toMap();
      expect(map['statement'], 'Qual é a capital da França?');
      expect(map['options'], ['Londres', 'Paris', 'Berlim', 'Madrid']);
      expect(map['correctIndex'], 1);

      final fromMap = Question.fromMap(map);
      expect(fromMap.statement, q.statement);
      expect(fromMap.correctLetter, 'B');
      expect(fromMap.options.length, 4);
    });

    test('copyWith atualiza propriedades', () {
      const q = Question(
        statement: '2 + 2?',
        options: ['3', '4'],
        correctIndex: 1,
      );

      final updated = q.copyWith(statement: 'Quanto é 2 + 2?');
      expect(updated.statement, 'Quanto é 2 + 2?');
      expect(updated.options, q.options);
      expect(updated.correctIndex, 1);
    });
  });

  group('CsvImportService.parseProofQuestions', () {
    test('lê CSV com cabeçalho em qualquer ordem', () {
      const csv =
          'correta;Alternativa A;alternativa_b;Opção C;d;Enunciado\n'
          'b;H2O;CO2;NaCl;O2;Qual é a fórmula do gás carbônico?';
      final res = CsvImportService.parseProofQuestions(csv);
      expect(res.erros, isEmpty);
      final q = res.questoes.single;
      expect(q.statement, 'Qual é a fórmula do gás carbônico?');
      expect(q.options, ['H2O', 'CO2', 'NaCl', 'O2']);
      expect(q.correctLetter, 'B');
    });

    test('sem cabeçalho usa a ordem enunciado,a,b,c,d,correta', () {
      const csv =
          '"Quanto é 1,5 + 1,5?",2,3,4,5,B\n'
          'Capital da França?,Londres,Berlim,Madri,Paris,D';
      final res = CsvImportService.parseProofQuestions(csv);
      expect(res.erros, isEmpty);
      expect(res.questoes, hasLength(2));
      // Vírgula dentro de aspas não separa colunas.
      expect(res.questoes.first.statement, 'Quanto é 1,5 + 1,5?');
      expect(res.questoes.last.correctIndex, 3);
    });

    test('ignora linhas inválidas e informa o motivo', () {
      const csv =
          'enunciado;a;b;c;d;correta\n'
          'Válida;1;2;3;4;A\n'
          ';1;2;3;4;A\n'
          'Sem alternativa;1;;3;4;A\n'
          'Correta inválida;1;2;3;4;E\n'
          '\n';
      final res = CsvImportService.parseProofQuestions(csv);
      expect(res.questoes.single.statement, 'Válida');
      expect(res.erros, [
        'Linha 3: enunciado vazio',
        'Linha 4: preencha as 4 alternativas',
        'Linha 5: alternativa correta "E" inválida (use A, B, C ou D)',
      ]);
    });

    test('cabeçalho incompleto é recusado', () {
      final res = CsvImportService.parseProofQuestions(
        'enunciado;a;b;c\nX;1;2;3',
      );
      expect(res.temQuestoes, isFalse);
      expect(res.erros.single, contains('enunciado, a, b, c, d e correta'));
    });
  });

  group('NewProofScreen - Adicionar Questão', () {
    const turma = Turma(
      id: 'turma-1',
      descricao: '3º Ano A - Matemática',
      semestre: 1,
      ano: 2026,
    );

    testWidgets('abre em branco, sem título, data ou questões', (tester) async {
      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      final titulo = tester.widget<TextField>(find.byType(TextField).first);
      expect(titulo.controller!.text, isEmpty);
      expect(find.text('Selecionar data'), findsOneWidget);
      expect(find.text('0 questões'), findsOneWidget);
      expect(find.textContaining('Nenhuma questão adicionada'), findsOneWidget);

      // Não salva sem título nem sem questões.
      await _salvarProva(tester);
      expect(find.text('Informe um título para salvar a prova'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Prova 1');
      await _salvarProva(tester);
      expect(find.text('Adicione ao menos uma questão à prova'), findsOneWidget);
    });

    testWidgets('abre o modal, valida campos obrigatórios e adiciona questão', (
      tester,
    ) async {
      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      await _abrirNovaQuestao(tester);
      expect(find.text('Questão 1'), findsOneWidget);
      expect(find.text('Adicionar à prova'), findsOneWidget);

      // Tenta submeter vazio
      await tester.tap(find.text('Adicionar à prova'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o enunciado da questão'), findsOneWidget);

      // Preenche o enunciado
      await tester.enterText(
        find.widgetWithText(TextField, 'Ex: Qual é a fórmula da água?'),
        'Qual é a fórmula da água?',
      );

      // Tenta submeter sem alternativas preenchidas
      await tester.tap(find.text('Adicionar à prova'));
      await tester.pumpAndSettle();

      expect(find.text('Preencha todas as 4 alternativas'), findsOneWidget);

      await _preencherAlternativas(tester, ['H2O', 'CO2', 'NaCl', 'O2']);

      // Submete a questão
      await tester.tap(find.text('Adicionar à prova'));
      await tester.pumpAndSettle();

      // Confirma que o modal fechou e a lista tem 1 questão
      expect(find.text('1 questão'), findsOneWidget);
      expect(find.text('1. Qual é a fórmula da água?'), findsOneWidget);
      expect(find.text('Questão 1 adicionada com sucesso'), findsOneWidget);
      expect(find.textContaining('Nenhuma questão adicionada'), findsNothing);
    });

    testWidgets('abre o modal de edição, altera questão e preserva integridade sem duplicar', (
      tester,
    ) async {
      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      await _adicionarQuestao(
        tester,
        'Qual é o resultado de 7 × 8?',
        ['54', '56', '58', '60'],
      );
      await _adicionarQuestao(
        tester,
        'Qual fração equivale a 0,5?',
        ['1/2', '1/4', '2/3', '3/4'],
      );
      expect(find.text('2 questões'), findsOneWidget);
      expect(find.text('1. Qual é o resultado de 7 × 8?'), findsOneWidget);

      // Clica no botão de editar da primeira questão
      final editButtons = find.byTooltip('Editar questão');
      expect(editButtons, findsNWidgets(2));
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Confirma abertura do modal pré-preenchido
      expect(find.text('Editar questão 1'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(find.text('Qual é o resultado de 7 × 8?'), findsOneWidget);

      // Altera o enunciado e uma alternativa
      await tester.enterText(
        find.widgetWithText(TextField, 'Qual é o resultado de 7 × 8?'),
        'Qual é o resultado de 8 × 9?',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '56'),
        '72',
      );

      // Salva a alteração
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      // Confirma atualização na lista
      expect(find.text('Questão 1 atualizada com sucesso'), findsOneWidget);
      expect(find.text('1. Qual é o resultado de 8 × 9?'), findsOneWidget);
      expect(find.textContaining('72'), findsOneWidget);
      // Garante que o total de questões continua sendo 2 (não foi duplicada)
      expect(find.text('2 questões'), findsOneWidget);
    });

    testWidgets('abre como página com abas Preencher e Importar CSV', (
      tester,
    ) async {
      await configurarBancoFalso();
      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      await _abrirNovaQuestao(tester);
      expect(find.byType(QuestionFormScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Preencher'), findsOneWidget);
      expect(find.text('Importar CSV'), findsOneWidget);

      // Voltar sem salvar não adiciona nada.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('0 questões'), findsOneWidget);
    });

    testWidgets('importa várias questões colando o CSV', (tester) async {
      await configurarBancoFalso();
      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      await _abrirNovaQuestao(tester);
      await tester.tap(find.text('Importar CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Importar questões'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        'enunciado;a;b;c;d;correta\n'
        'Quanto é 7 × 8?;54;56;58;60;B\n'
        'Qual fração equivale a 0,5?;1/2;1/4;2/3;3/4;A\n'
        'Linha ruim;1;2;3;4;Z',
      );
      await tester.pumpAndSettle();
      expect(find.text('2 questões prontas para importar'), findsOneWidget);
      expect(find.text('1 linha ignorada'), findsOneWidget);

      await tester.tap(find.text('Importar 2 questões'));
      await tester.pumpAndSettle();

      expect(find.text('2 questões'), findsOneWidget);
      expect(find.text('1. Quanto é 7 × 8?'), findsOneWidget);
      expect(find.text('2. Qual fração equivale a 0,5?'), findsOneWidget);
      expect(find.text('2 questões importadas com sucesso'), findsOneWidget);
    });

    testWidgets('importa questões de um arquivo CSV', (tester) async {
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
                      csvPicker: () async => const CsvFile(
                        name: 'questoes.csv',
                        sizeInBytes: 40,
                        content: 'Capital da França?;Londres;Berlim;Madri;Paris;D',
                      ),
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
      await tester.tap(find.text('Importar CSV'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecionar arquivo CSV'));
      await tester.pumpAndSettle();
      expect(find.text('questoes.csv'), findsOneWidget);
      expect(find.text('1 questão pronta para importar'), findsOneWidget);

      await tester.tap(find.text('Importar 1 questão'));
      await tester.pumpAndSettle();
      expect(resultado!.single.statement, 'Capital da França?');
      expect(resultado!.single.correctLetter, 'D');
    });

    testWidgets('edição abre só o formulário, sem importação', (tester) async {
      await configurarBancoFalso();
      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();
      await _adicionarQuestao(tester, 'Primeira', ['a', 'b', 'c', 'd']);

      await tester.tap(find.byTooltip('Editar questão'));
      await tester.pumpAndSettle();
      expect(find.text('Editar questão 1'), findsOneWidget);
      expect(find.text('Importar CSV'), findsNothing);
    });

    testWidgets('remove questão, renumera as seguintes e permite desfazer', (
      tester,
    ) async {
      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      await _adicionarQuestao(tester, 'Primeira', ['a', 'b', 'c', 'd']);
      await _adicionarQuestao(tester, 'Segunda', ['a', 'b', 'c', 'd']);
      expect(find.text('2 questões'), findsOneWidget);

      await tester.tap(find.byTooltip('Remover questão').first);
      await tester.pumpAndSettle();

      expect(find.text('1 questão'), findsOneWidget);
      expect(find.text('1. Primeira'), findsNothing);
      expect(find.text('1. Segunda'), findsOneWidget);
      expect(find.text('Questão 1 removida'), findsOneWidget);

      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();

      expect(find.text('2 questões'), findsOneWidget);
      expect(find.text('1. Primeira'), findsOneWidget);
      expect(find.text('2. Segunda'), findsOneWidget);
    });
  });
}

/// O botão fica abaixo da área visível do teste (800x600).
Future<void> _abrirNovaQuestao(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Adicionar questão'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Adicionar questão'));
  await tester.pumpAndSettle();
}

Future<void> _preencherAlternativas(
  WidgetTester tester,
  List<String> alternativas,
) async {
  for (final (i, texto) in alternativas.indexed) {
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Alternativa ${String.fromCharCode(65 + i)}',
      ),
      texto,
    );
  }
}

Future<void> _adicionarQuestao(
  WidgetTester tester,
  String enunciado,
  List<String> alternativas,
) async {
  await _abrirNovaQuestao(tester);
  await tester.enterText(
    find.widgetWithText(TextField, 'Ex: Qual é a fórmula da água?'),
    enunciado,
  );
  await _preencherAlternativas(tester, alternativas);
  await tester.tap(find.text('Adicionar à prova'));
  await tester.pumpAndSettle();
  // Espera o aviso "Questão N adicionada" sumir: ele cobre o fim da lista.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _salvarProva(WidgetTester tester) async {
  await tester.tap(find.text('Salvar prova'));
  await tester.pumpAndSettle();
}
