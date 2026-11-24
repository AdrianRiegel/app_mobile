// Verifica no navegador o infinite scroll das listas de turmas e de alunos,
// com o banco em memória dos testes (não acessa o Firebase real).
//
//   chromedriver --port=4444 &
//   flutter drive -d web-server --browser-name=chrome \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/infinite_scroll_test.dart
//
// Os prints ficam em build/integration_screenshots/.
import 'package:app_mobile/Screens/classes_screen.dart';
import 'package:app_mobile/components/components.dart';
import 'package:app_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/fake_database.dart';

late final IntegrationTestWidgetsFlutterBinding _binding;

void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('listas de turmas e alunos com infinite scroll', (tester) async {
    final db = await configurarBancoFalso();
    for (var i = 0; i < 40; i++) {
      final n = i.toString().padLeft(2, '0');
      await db.collection('turmas').doc('extra-$n').set({
        'professorId': professorId,
        'descricao': 'Turma $n',
        'semestre': 1,
        'ano': 2026,
      });
      await db.collection('alunos').doc('extra-$n').set({
        'professorId': professorId,
        'turmaId': 'turma-1',
        'nome': 'Estudante $n',
        'matricula': 'extra-$n',
      });
    }

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ClassesScreen()),
    );
    await _aguardar(tester, find.text('Turma 00'));

    // Turmas: o fim da lista só aparece rolando; sem paginação por botões.
    expect(find.text('Turma 39'), findsNothing);
    expect(find.textContaining('Página'), findsNothing);
    await _print('01_turmas_inicio');
    await _rolarAte(tester, find.text('Turma 39'));
    await _print('02_turmas_fim');

    // A busca recomeça do topo.
    await tester.enterText(find.byType(TextField).first, 'Matemática');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3º Ano A - Matemática'), findsOneWidget);
    expect(find.text('Turma 39'), findsNothing);

    // Alunos da turma.
    await tester.tap(find.text('3º Ano A - Matemática'));
    await _aguardar(tester, find.text('42 alunos'));
    expect(find.text('Estudante 39'), findsNothing);
    expect(find.textContaining('Página'), findsNothing);
    await _print('03_alunos_inicio');
    await _rolarAte(tester, find.text('Estudante 39'));
    await _print('04_alunos_fim');
  });
}

Future<void> _print(String nome) =>
    _binding.takeScreenshot('infinite_scroll_$nome');

/// Arrasta a lista para cima, como o usuário, até [finder] aparecer.
Future<void> _rolarAte(WidgetTester tester, Finder finder) async {
  final lista = find
      .descendant(
        of: find.byType(InfiniteScrollList),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(lista, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(finder, findsOneWidget);
}

Future<void> _aguardar(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump(const Duration(milliseconds: 300));
  expect(finder, findsOneWidget);
}
