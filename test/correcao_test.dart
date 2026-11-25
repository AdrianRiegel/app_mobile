import 'package:app_mobile/Screens/correction_start_screen.dart';
import 'package:app_mobile/models/aluno.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

/// Casos de borda da regra de correção e atribuição de nota (#15).
void main() {
  Assessment prova(List<QuestaoGabarito> gabarito) => Assessment(
    id: 'aval-x',
    turmaId: 'turma-1',
    gabarito: gabarito,
    title: 'Prova',
    subject: 'Matemática',
    className: '3º Ano A',
    dateLabel: 'Sem data',
    status: AssessmentStatus.scheduled,
    totalQuestions: gabarito.length,
    correctedStudents: 0,
    totalStudents: 2,
  );

  final cincoQuestoes = prova([
    for (final (index, letra) in ['A', 'B', 'C', 'D', 'E'].indexed)
      QuestaoGabarito(questao: index + 1, alternativaCorreta: letra),
  ]);

  group('ResultadoRepository.corrigir — casos de borda', () {
    test('questões sem resposta do aluno contam como erro', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: cincoQuestoes,
        alunoId: 'aluno-1',
        respostas: ['A', 'B'], // folha com só duas respostas
      );

      expect(resultado.respostas, hasLength(5));
      expect(resultado.totalAcertos, 2);
      expect(resultado.respostas.skip(2).map((r) => r.alternativaMarcada), [
        null,
        null,
        null,
      ]);
      expect(resultado.notaCalculada, 4.0);
    });

    test('respostas além do gabarito são ignoradas', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: cincoQuestoes,
        alunoId: 'aluno-1',
        respostas: ['A', 'B', 'C', 'D', 'E', 'A', 'B'],
      );

      expect(resultado.respostas, hasLength(5));
      expect(resultado.notaCalculada, 10.0);
    });

    test('nota zero quando erra tudo', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: cincoQuestoes,
        alunoId: 'aluno-1',
        respostas: ['E', 'E', 'E', 'E', 'A'],
      );

      expect(resultado.totalAcertos, 0);
      expect(resultado.notaCalculada, 0.0);
      expect(resultado.aprovado, isFalse);
    });

    test('questão sem alternativa correta no gabarito não pontua', () {
      final incompleta = prova(const [
        QuestaoGabarito(questao: 1, alternativaCorreta: 'A'),
        QuestaoGabarito(questao: 2), // gabarito ainda não configurado
      ]);

      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: incompleta,
        alunoId: 'aluno-1',
        respostas: ['A', null],
      );

      expect(resultado.respostas.last.correta, isFalse);
      expect(resultado.notaCalculada, 5.0);
    });

    test('gabarito vazio dá nota zero sem dividir por zero', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: prova(const []),
        alunoId: 'aluno-1',
        respostas: ['A'],
      );

      expect(resultado.respostas, isEmpty);
      expect(resultado.notaCalculada, 0.0);
    });

    test('arredonda a nota para duas casas decimais', () {
      final tresQuestoes = prova(const [
        QuestaoGabarito(questao: 1, alternativaCorreta: 'A'),
        QuestaoGabarito(questao: 2, alternativaCorreta: 'B'),
        QuestaoGabarito(questao: 3, alternativaCorreta: 'C'),
      ]);

      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: tresQuestoes,
        alunoId: 'aluno-1',
        respostas: ['A', 'X', 'X'],
      );

      expect(resultado.notaCalculada, 3.33);
    });

    test('nota exatamente 6 é aprovação', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: prova([
          for (var questao = 1; questao <= 10; questao++)
            QuestaoGabarito(questao: questao, alternativaCorreta: 'A'),
        ]),
        alunoId: 'aluno-1',
        respostas: [...List.filled(6, 'A'), ...List.filled(4, 'B')],
      );

      expect(resultado.notaCalculada, 6.0);
      expect(resultado.aprovado, isTrue);
    });
  });

  test(
    'impede correção duplicada de prova já corrigida a menos que permitirSobrescrita seja true',
    () async {
      final firestore = await configurarBancoFalso();
      final avaliacao = await AvaliacaoRepository().buscar('aval-1');
      const aluno = Aluno(
        id: 'aluno-1',
        turmaId: 'turma-1',
        nome: 'Ana Beatriz',
        matricula: '2026041',
      );

      await ResultadoRepository().salvar(
        avaliacao: avaliacao,
        aluno: aluno,
        respostas: ['A', 'A', 'A', 'A'],
      );

      // Verifica helper de consulta
      expect(
        await ResultadoRepository().alunoJaCorrigido(
          avaliacaoId: avaliacao.id,
          alunoId: aluno.id,
        ),
        isTrue,
      );
      final resultadoExistente = await ResultadoRepository()
          .buscarPorAvaliacaoEAluno(
            avaliacaoId: avaliacao.id,
            alunoId: aluno.id,
          );
      expect(resultadoExistente, isNotNull);
      expect(resultadoExistente!.alunoId, aluno.id);

      // Segunda tentativa sem permitirSobrescrita deve lançar StateError
      expect(
        () => ResultadoRepository().salvar(
          avaliacao: avaliacao,
          aluno: aluno,
          respostas: ['A', 'B', 'C', 'D'],
        ),
        throwsA(isA<StateError>()),
      );

      // Segunda tentativa com permitirSobrescrita: true substitui o resultado anterior
      await ResultadoRepository().salvar(
        avaliacao: avaliacao,
        aluno: aluno,
        respostas: ['A', 'B', 'C', 'D'],
        permitirSobrescrita: true,
      );

      final resultados = await firestore
          .collection('resultados')
          .where('alunoId', isEqualTo: 'aluno-1')
          .get();
      expect(resultados.docs, hasLength(1));
      expect(resultados.docs.single.data()['notaCalculada'], 10.0);
    },
  );

  testWidgets('etapa de leitura não exibe botão de simular leitura da folha', (
    tester,
  ) async {
    await configurarBancoFalso();
    final avaliacao = await AvaliacaoRepository().buscar('aval-1');

    await tester.pumpWidget(
      MaterialApp(home: CorrectionStartScreen(assessment: avaliacao)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar para identificação do aluno'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selecione um aluno...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Beatriz (2026041)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar para leitura da folha'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir câmera e fotografar'), findsOneWidget);
    expect(find.text('Simular leitura da Folha'), findsNothing);
  });
}
