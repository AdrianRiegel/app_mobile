import 'package:app_mobile/Screens/assessment_detail_screen.dart';
import 'package:app_mobile/models/aluno.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  group('ResultadoRepository.encerrarCorrecao', () {
    test('atribui nota 0 apenas a alunos ausentes, preservando notas existentes e atualiza status', (
    ) async {
      final firestore = await configurarBancoFalso();
      final alunoRepo = AlunoRepository();
      final resultadoRepo = ResultadoRepository();
      final avaliacaoRepo = AvaliacaoRepository();

      // Adiciona um 3º aluno na turma para testar o ausente
      final aluno3 = await alunoRepo.adicionar(
        turmaId: 'turma-1',
        nome: 'Diana Reis',
        matricula: '2026043',
      );

      var avaliacao = await avaliacaoRepo.buscar('aval-1');
      expect(avaliacao.status, AssessmentStatus.scheduled);

      // Aluno 1: Nota 7.5 (3 acertos de 4)
      await resultadoRepo.salvar(
        avaliacao: avaliacao,
        aluno: const Aluno(
          id: 'aluno-1',
          turmaId: 'turma-1',
          nome: 'Ana Beatriz',
          matricula: '2026041',
        ),
        respostas: ['A', 'B', 'C', 'A'], // Gabarito é A, B, C, D
      );

      // Aluno 2: Nota 0.0 real (errou todas)
      await resultadoRepo.salvar(
        avaliacao: avaliacao,
        aluno: const Aluno(
          id: 'aluno-2',
          turmaId: 'turma-1',
          nome: 'Carlos Dias',
          matricula: '2026042',
        ),
        respostas: ['E', 'E', 'E', 'E'],
      );

      // Aluno 3 (Diana Reis) não tem resultado registrado

      // Executa o encerramento da correção
      final ausentes = await resultadoRepo.encerrarCorrecao(avaliacao: avaliacao);
      expect(ausentes, 1);

      // Verifica status da avaliação
      avaliacao = await avaliacaoRepo.buscar('aval-1');
      expect(avaliacao.status, AssessmentStatus.completed);

      // Verifica que Aluno 1 preservou a nota 7.5
      final r1 = await firestore.collection('resultados').doc('aval-1_aluno-1').get();
      expect(r1.data()!['notaCalculada'], 7.5);
      expect(r1.data()!['totalAcertos'], 3);

      // Verifica que Aluno 2 preservou a nota 0.0 com suas respostas reais
      final r2 = await firestore.collection('resultados').doc('aval-1_aluno-2').get();
      expect(r2.data()!['notaCalculada'], 0.0);
      expect(r2.data()!['respostasAluno'][0]['alternativaMarcada'], 'E');

      // Verifica que Aluno 3 recebeu nota 0.0 e foi marcado como ausente
      final r3 = await firestore.collection('resultados').doc('aval-1_${aluno3.id}').get();
      expect(r3.exists, isTrue);
      expect(r3.data()!['notaCalculada'], 0.0);
      expect(r3.data()!['totalAcertos'], 0);
      expect(r3.data()!['ausente'], isTrue);
      expect(r3.data()!['respostasAluno'][0]['alternativaMarcada'], isNull);

      // Idempotência: re-executar não altera nada e retorna 0
      final ausentesReexecucao = await resultadoRepo.encerrarCorrecao(avaliacao: avaliacao);
      expect(ausentesReexecucao, 0);
    });
  });

  group('AssessmentDetailScreen - Botão Encerrar Correção', () {
    testWidgets('exibe diálogo de confirmação e conclui a avaliação', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();
      final avaliacao = await AvaliacaoRepository().buscar('aval-1');

      await tester.pumpWidget(
        MaterialApp(home: AssessmentDetailScreen(assessment: avaliacao)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Encerrar correção'), findsOneWidget);

      // Toca em Encerrar correção
      await tester.tap(find.text('Encerrar correção'));
      await tester.pumpAndSettle();

      // Confirma abertura do diálogo
      expect(find.text('Encerrar correção?'), findsOneWidget);

      // Clica no botão de confirmar do diálogo
      await tester.tap(find.widgetWithText(ElevatedButton, 'Encerrar correção'));
      await tester.pumpAndSettle();

      // Verifica SnackBar de sucesso
      expect(find.textContaining('Correção encerrada com sucesso'), findsOneWidget);
    });
  });
}
