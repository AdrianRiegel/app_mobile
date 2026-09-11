import 'package:app_mobile/Screens/exam_statistics_screen.dart';
import 'package:app_mobile/Screens/report_screen.dart';
import 'package:app_mobile/Screens/statistics_screen.dart';
import 'package:app_mobile/models/statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('estatísticas gerais listam turmas e abrem a prova', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StatisticsScreen()));

    expect(find.text('3º Ano A - Matemática'), findsOneWidget);
    expect(find.text('2º Ano B - Física'), findsOneWidget);

    await tester.tap(find.text('Avaliação bimestral — Cap. 4'));
    await tester.pumpAndSettle();

    expect(find.text('Estatísticas · Cap. 4'), findsOneWidget);
    expect(find.text('Acerto médio'), findsOneWidget);
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('Questão mais errada'), findsOneWidget);
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
    await tester.pumpWidget(const MaterialApp(home: ReportScreen()));

    expect(find.text('Prévia do relatório em PDF'), findsOneWidget);

    await tester.tap(find.text('Gerar e baixar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Prévia do relatório em PDF'), findsNothing);
    expect(find.text('Relatório de desempenho'), findsOneWidget);
    expect(find.text('Provas incluídas'), findsOneWidget);
  });
}
