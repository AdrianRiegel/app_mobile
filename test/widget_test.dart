// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:app_mobile/main.dart';
import 'package:app_mobile/Screens/class_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navega do login até o gabarito de uma avaliação', (
    tester,
  ) async {
    await tester.pumpWidget(const EduTurmasApp());

    expect(find.text('EduTurmas'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Maria'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.assignment_turned_in_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Avaliações'), findsOneWidget);
    expect(find.text('Avaliações recentes'), findsOneWidget);
    await tester.tap(find.text('Avaliação bimestral — Cap. 4'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da avaliação'), findsOneWidget);
    await tester.tap(find.text('Configurar gabarito'));
    await tester.pumpAndSettle();

    expect(find.text('Configurar gabarito'), findsOneWidget);
    expect(find.text('Salvar gabarito'), findsOneWidget);
  });

  testWidgets('abre o modal para cadastrar aluno e adiciona na lista', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClassDetailScreen(titulo: '3º Ano A - Matemática'),
      ),
    );

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Novo aluno'), findsOneWidget);

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'João da Silva');
    await tester.enterText(textFields.at(1), '2026044');
    await tester.tap(find.text('Adicionar aluno'));
    await tester.pumpAndSettle();

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('Matrícula 2026044'), findsOneWidget);
  });
}
