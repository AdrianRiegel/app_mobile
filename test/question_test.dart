import 'package:app_mobile/Screens/new_proof_screen.dart';
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

  group('NewProofScreen - Adicionar Questão', () {
    const turma = Turma(
      id: 'turma-1',
      descricao: '3º Ano A - Matemática',
      semestre: 1,
      ano: 2026,
    );

    testWidgets('abre o modal, valida campos obrigatórios e adiciona questão', (
      tester,
    ) async {
      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: NewProofScreen(turma: turma)),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 questões'), findsOneWidget);
      expect(find.text('Adicionar questão'), findsOneWidget);

      // Abre o modal de nova questão
      await tester.tap(find.text('Adicionar questão'));
      await tester.pumpAndSettle();

      expect(find.text('Questão 3'), findsOneWidget);
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

      // Preenche as 4 alternativas
      await tester.enterText(
        find.widgetWithText(TextField, 'Alternativa A'),
        'H2O',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Alternativa B'),
        'CO2',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Alternativa C'),
        'NaCl',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Alternativa D'),
        'O2',
      );

      // Submete a questão
      await tester.tap(find.text('Adicionar à prova'));
      await tester.pumpAndSettle();

      // Confirma que o modal fechou e a lista tem 3 questões
      expect(find.text('3 questões'), findsOneWidget);
      expect(find.text('3. Qual é a fórmula da água?'), findsOneWidget);
      expect(find.text('Questão 3 adicionada com sucesso'), findsOneWidget);
    });
  });
}
