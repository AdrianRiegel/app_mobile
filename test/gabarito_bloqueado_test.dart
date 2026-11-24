import 'package:app_mobile/Screens/assessment_detail_screen.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

/// O gabarito deixa de ser editável quando a prova está pronta para a
/// leitura do QR Code e a correção (#67).
void main() {
  Future<Assessment> criarRascunho() async {
    final turma = await TurmaRepository().buscar('turma-1');
    final criada = await AvaliacaoRepository().criar(
      turma: turma,
      titulo: 'Recuperação',
      disciplina: 'Matemática',
      totalQuestoes: 3,
    );
    return AvaliacaoRepository().salvarGabarito(criada, ['A', 'B', 'C']);
  }

  group('AvaliacaoRepository.salvarGabarito', () {
    test('permite alterar o gabarito de um rascunho', () async {
      await configurarBancoFalso();
      final rascunho = await criarRascunho();

      final alterada = await AvaliacaoRepository().salvarGabarito(rascunho, [
        'C',
        'C',
        'C',
      ]);

      expect(alterada.gabarito.map((q) => q.alternativaCorreta), [
        'C',
        'C',
        'C',
      ]);
    });

    test('recusa alterar o gabarito de prova agendada', () async {
      final firestore = await configurarBancoFalso();
      final agendada = await AvaliacaoRepository().buscar('aval-1');
      expect(agendada.gabaritoEditavel, isFalse);

      await expectLater(
        AvaliacaoRepository().salvarGabarito(agendada, ['E', 'E', 'E', 'E']),
        throwsStateError,
      );
      final salva = await firestore
          .collection('avaliacoes')
          .doc('aval-1')
          .get();
      expect(salva.data()!['gabarito'][0]['alternativaCorreta'], 'A');
    });

    test('bloqueia depois de marcar como pronta', () async {
      await configurarBancoFalso();
      final pronta = await AvaliacaoRepository().marcarComoPronta(
        await criarRascunho(),
      );

      await expectLater(
        AvaliacaoRepository().salvarGabarito(pronta, ['C', 'C', 'C']),
        throwsStateError,
      );
    });
  });

  group('Tela de detalhes', () {
    Future<void> abrir(WidgetTester tester, Assessment avaliacao) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: AssessmentDetailScreen(assessment: avaliacao)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('rascunho mostra as opções de editar o gabarito', (
      tester,
    ) async {
      await configurarBancoFalso();
      await abrir(tester, await criarRascunho());

      expect(find.text('Configurar gabarito'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.textContaining('Gabarito bloqueado'), findsNothing);
    });

    testWidgets('prova agendada não oferece editar o gabarito', (tester) async {
      await configurarBancoFalso();
      await abrir(tester, await AvaliacaoRepository().buscar('aval-1'));

      expect(find.text('Iniciar correção'), findsOneWidget);
      expect(find.text('Configurar gabarito'), findsNothing);
      expect(find.text('Editar'), findsNothing);
      expect(find.textContaining('Gabarito bloqueado'), findsOneWidget);
    });

    testWidgets('ao marcar como pronta, as opções somem na hora', (
      tester,
    ) async {
      await configurarBancoFalso();
      await abrir(tester, await criarRascunho());

      await tester.tap(find.text('Marcar como pronta'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Marcar como pronta'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurar gabarito'), findsNothing);
      expect(find.textContaining('Gabarito bloqueado'), findsOneWidget);
    });
  });
}
