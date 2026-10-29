import 'package:app_mobile/Screens/new_assessment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  testWidgets('nova avaliação abre sem data nem quantidade de questões', (
    tester,
  ) async {
    await configurarBancoFalso();

    await tester.pumpWidget(const MaterialApp(home: NewAssessmentScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar data'), findsOneWidget);
    final campos = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((campo) => campo.controller!.text);
    // Título e quantidade vazios; só a disciplina vem da turma escolhida.
    expect(campos.where((texto) => texto.isNotEmpty), ['Matemática']);
  });
}
