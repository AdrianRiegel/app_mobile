import 'package:app_mobile/models/aluno.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  group('ResultadoRepository.corrigir', () {
    const avaliacao = Assessment(
      id: 'aval-1',
      turmaId: 'turma-1',
      gabarito: [
        QuestaoGabarito(questao: 1, alternativaCorreta: 'A', peso: 2),
        QuestaoGabarito(questao: 2, alternativaCorreta: 'B'),
        QuestaoGabarito(questao: 3, alternativaCorreta: 'C'),
      ],
      title: 'Prova',
      subject: 'Matemática',
      className: '3º Ano A',
      dateLabel: 'Sem data',
      status: AssessmentStatus.scheduled,
      totalQuestions: 3,
      correctedStudents: 0,
      totalStudents: 2,
    );

    test('calcula acertos e nota ponderada pelo peso', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: avaliacao,
        alunoId: 'aluno-1',
        respostas: ['A', 'C', null],
      );

      expect(resultado.totalAcertos, 1);
      expect(resultado.respostas.map((r) => r.correta), [true, false, false]);
      expect(resultado.respostas.last.alternativaMarcada, isNull);
      // Acertou a questão de peso 2 de um total de 4.
      expect(resultado.notaCalculada, 5.0);
      expect(resultado.aprovado, isFalse);
    });

    test('dá nota 10 quando acerta tudo', () {
      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: avaliacao,
        alunoId: 'aluno-1',
        respostas: ['A', 'B', 'C'],
      );

      expect(resultado.notaCalculada, 10.0);
      expect(resultado.aprovado, isTrue);
    });
  });

  test('conclui a avaliação quando todos os alunos são corrigidos', () async {
    final firestore = await configurarBancoFalso();
    final repository = ResultadoRepository();
    var avaliacao = await AvaliacaoRepository().buscar('aval-1');

    await repository.salvar(
      avaliacao: avaliacao,
      aluno: const Aluno(
        id: 'aluno-1',
        turmaId: 'turma-1',
        nome: 'Ana Beatriz',
        matricula: '2026041',
      ),
      respostas: ['A', 'B', 'C', 'D'],
    );
    avaliacao = await AvaliacaoRepository().buscar('aval-1');
    expect(avaliacao.status, AssessmentStatus.scheduled);
    expect(avaliacao.correctedStudents, 1);

    await repository.salvar(
      avaliacao: avaliacao,
      aluno: const Aluno(
        id: 'aluno-2',
        turmaId: 'turma-1',
        nome: 'Carlos Dias',
        matricula: '2026042',
      ),
      respostas: ['A', 'A', 'A', 'A'],
    );
    avaliacao = await AvaliacaoRepository().buscar('aval-1');
    expect(avaliacao.status, AssessmentStatus.completed);

    final salvo = await firestore
        .collection('resultados')
        .doc('aval-1_aluno-2')
        .get();
    expect(salvo.data()!['totalAcertos'], 1);
    expect(salvo.data()!['notaCalculada'], 2.5);
  });

  test('cria avaliação como rascunho e agenda ao salvar o gabarito', () async {
    await configurarBancoFalso();
    final repository = AvaliacaoRepository();
    final turma = await TurmaRepository().buscar('turma-1');

    final criada = await repository.criar(
      turma: turma,
      titulo: 'Recuperação',
      disciplina: 'Matemática',
      totalQuestoes: 3,
    );
    expect(criada.status, AssessmentStatus.draft);
    expect(criada.gabaritoConfigurado, isFalse);

    final agendada = await repository.salvarGabarito(criada, ['A', 'B', 'C']);
    expect(agendada.status, AssessmentStatus.scheduled);
    expect(agendada.gabaritoConfigurado, isTrue);
    expect(agendada.className, '3º Ano A');
  });

  test('lista apenas as turmas do professor logado', () async {
    final firestore = await configurarBancoFalso();
    await firestore.collection('turmas').add({
      'professorId': 'outro-professor',
      'descricao': '2º Ano B - Física',
      'semestre': 1,
      'ano': 2026,
      'totalAlunos': 0,
    });

    final turmas = await TurmaRepository().listar();
    expect(turmas.map((turma) => turma.descricao), ['3º Ano A - Matemática']);
  });
}
