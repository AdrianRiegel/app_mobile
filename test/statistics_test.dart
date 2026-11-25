import 'package:app_mobile/Screens/exam_statistics_screen.dart';
import 'package:app_mobile/Screens/statistics_screen.dart';
import 'package:app_mobile/components/components.dart';
import 'package:app_mobile/models/statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  testWidgets('estatísticas gerais calculam o acerto a partir dos resultados', (
    tester,
  ) async {
    final firestore = await configurarBancoFalso();
    // Q1 e Q2: 100% de acerto; Q3 e Q4: 50%.
    await adicionarResultado(
      firestore,
      alunoId: 'aluno-1',
      acertos: [true, true, true, true],
    );
    await adicionarResultado(
      firestore,
      alunoId: 'aluno-2',
      acertos: [true, true, false, false],
    );

    await tester.pumpWidget(const MaterialApp(home: StatisticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('3º Ano A - Matemática'), findsOneWidget);
    await tester.tap(find.text('Avaliação bimestral — Cap. 4'));
    await tester.pumpAndSettle();

    expect(find.text('Estatísticas · Cap. 4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Q3'), findsNWidgets(2)); // card e linha da questão
  });

  testWidgets('estatísticas mostram estado vazio sem correções', (
    tester,
  ) async {
    await configurarBancoFalso();
    await tester.pumpWidget(const MaterialApp(home: StatisticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ainda não há estatísticas'), findsOneWidget);
  });

  testWidgets('botão de voltar das estatísticas retorna à tela anterior', (
    tester,
  ) async {
    await configurarBancoFalso();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              ),
              child: const Text('Abrir estatísticas'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir estatísticas'));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsNothing);
    expect(find.text('Abrir estatísticas'), findsOneWidget);
  });

  testWidgets('tela da prova mostra uma barra por questão', (tester) async {
    final stats = ExamStatistics.demo(
      assessmentTitle: 'Prova teste',
      shortLabel: 'Teste',
      className: '1º Ano C',
      subject: 'Química',
      totalQuestions: 6,
    );

    await tester.pumpWidget(
      MaterialApp(home: ExamStatisticsScreen(statistics: stats)),
    );

    expect(find.text('Acertos por questão'), findsOneWidget);
    expect(find.byType(VerticalBarChartCard), findsOneWidget);
    expect(find.byType(PerformanceDonutCard), findsOneWidget);
    // Uma barra de progresso (FractionallySizedBox) para cada questão.
    expect(find.byType(FractionallySizedBox), findsNWidgets(6));
  });

  testWidgets('estatísticas gerais exibem gráficos de turma e evolução', (
    tester,
  ) async {
    final firestore = await configurarBancoFalso();
    await adicionarResultado(
      firestore,
      alunoId: 'aluno-1',
      acertos: [true, true, true, false],
    );
    await firestore.collection('avaliacoes').doc('aval-2').set({
      'professorId': professorId,
      'turmaId': 'turma-1',
      'disciplina': 'Matemática',
      'titulo': 'Simulado — Cap. 5',
      'status': 'concluida',
      'gabarito': [
        {'questao': 1, 'alternativaCorreta': 'A', 'peso': 1.0},
        {'questao': 2, 'alternativaCorreta': 'B', 'peso': 1.0},
        {'questao': 3, 'alternativaCorreta': 'C', 'peso': 1.0},
        {'questao': 4, 'alternativaCorreta': 'D', 'peso': 1.0},
      ],
    });
    await firestore.collection('resultados').doc('aval-2_aluno-1').set({
      'avaliacaoId': 'aval-2',
      'turmaId': 'turma-1',
      'professorId': professorId,
      'alunoId': 'aluno-1',
      'respostasAluno': [
        for (var i = 1; i <= 4; i++)
          {'questao': i, 'alternativaMarcada': 'A', 'correta': true},
      ],
      'totalAcertos': 4,
      'notaCalculada': 10.0,
    });

    await tester.pumpWidget(const MaterialApp(home: StatisticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Desempenho médio por turma'), findsOneWidget);
    expect(find.text('Evolução nas provas'), findsOneWidget);
  });

  // A geração do PDF da tela de relatório é testada em relatorio_pdf_test.dart.
}
