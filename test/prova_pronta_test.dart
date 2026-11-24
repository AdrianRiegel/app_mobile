import 'package:app_mobile/Screens/assessment_detail_screen.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

/// Marcar a prova como pronta, passando de rascunho para agendada (#65).
void main() {
  Future<Assessment> criarRascunho({bool comGabarito = true}) async {
    final repository = AvaliacaoRepository();
    final turma = await TurmaRepository().buscar('turma-1');
    final criada = await repository.criar(
      turma: turma,
      titulo: 'Recuperação',
      disciplina: 'Matemática',
      totalQuestoes: 3,
    );
    return comGabarito
        ? repository.salvarGabarito(criada, ['A', 'B', 'C'])
        : criada;
  }

  group('AvaliacaoRepository.marcarComoPronta', () {
    test('passa a prova de rascunho para agendada', () async {
      await configurarBancoFalso();
      final rascunho = await criarRascunho();
      expect(rascunho.status, AssessmentStatus.draft);

      final pronta = await AvaliacaoRepository().marcarComoPronta(rascunho);

      expect(pronta.status, AssessmentStatus.scheduled);
      final salva = await AvaliacaoRepository().buscar(rascunho.id);
      expect(salva.status, AssessmentStatus.scheduled);
    });

    test('recusa prova sem gabarito configurado', () async {
      await configurarBancoFalso();
      final rascunho = await criarRascunho(comGabarito: false);

      await expectLater(
        AvaliacaoRepository().marcarComoPronta(rascunho),
        throwsStateError,
      );
      final salva = await AvaliacaoRepository().buscar(rascunho.id);
      expect(salva.status, AssessmentStatus.draft);
    });

    test('recusa prova que não está em rascunho', () async {
      await configurarBancoFalso();
      final agendada = await AvaliacaoRepository().buscar('aval-1');
      expect(agendada.status, AssessmentStatus.scheduled);

      await expectLater(
        AvaliacaoRepository().marcarComoPronta(agendada),
        throwsStateError,
      );
    });
  });

  group('Tela de detalhes — botão Marcar como pronta', () {
    Future<void> abrir(WidgetTester tester, Assessment avaliacao) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: AssessmentDetailScreen(assessment: avaliacao)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('confirma e muda a situação para Agendada', (tester) async {
      await configurarBancoFalso();
      final rascunho = await criarRascunho();
      await abrir(tester, rascunho);

      await tester.tap(find.text('Marcar como pronta'));
      await tester.pumpAndSettle();
      expect(find.text('Marcar prova como pronta?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Marcar como pronta'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prova marcada como pronta (Agendada)'), findsOneWidget);
      expect(find.text('Marcar como pronta'), findsNothing);
      final salva = await AvaliacaoRepository().buscar(rascunho.id);
      expect(salva.status, AssessmentStatus.scheduled);
    });

    testWidgets('sem gabarito avisa e não muda a situação', (tester) async {
      await configurarBancoFalso();
      final rascunho = await criarRascunho(comGabarito: false);
      await abrir(tester, rascunho);

      await tester.tap(find.text('Marcar como pronta'));
      await tester.pumpAndSettle();

      expect(find.text('Marcar prova como pronta?'), findsNothing);
      expect(
        find.text('Configure o gabarito antes de marcar a prova como pronta'),
        findsOneWidget,
      );
      final salva = await AvaliacaoRepository().buscar(rascunho.id);
      expect(salva.status, AssessmentStatus.draft);
    });

    testWidgets('não aparece em prova já agendada', (tester) async {
      await configurarBancoFalso();
      await abrir(tester, await AvaliacaoRepository().buscar('aval-1'));

      expect(find.text('Marcar como pronta'), findsNothing);
    });
  });
}
