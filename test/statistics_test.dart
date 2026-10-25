import 'package:app_mobile/Screens/exam_statistics_screen.dart';
import 'package:app_mobile/Screens/report_screen.dart';
import 'package:app_mobile/Screens/statistics_screen.dart';
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
    // Uma barra de progresso (FractionallySizedBox) para cada questão.
    expect(find.byType(FractionallySizedBox), findsNWidgets(6));
  });

  testWidgets('relatório gera a prévia ao tocar em Gerar e baixar PDF', (
    tester,
  ) async {
    final firestore = await configurarBancoFalso();
    await adicionarResultado(
      firestore,
      alunoId: 'aluno-1',
      acertos: [true, true, true, false],
    );
    await tester.pumpWidget(const MaterialApp(home: ReportScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Prévia do relatório em PDF'), findsOneWidget);

    await tester.tap(find.text('Gerar e baixar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Prévia do relatório em PDF'), findsNothing);
    expect(find.text('Relatório de desempenho'), findsOneWidget);
    expect(find.text('Provas incluídas'), findsOneWidget);
    expect(find.text('75% · mais errada Q4'), findsOneWidget);
  });
}
