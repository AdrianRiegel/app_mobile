import 'package:app_mobile/models/aluno.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/csv_import_service.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/omr/omr_processor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

/// Bateria completa de testes automatizados para validação das regras de negócio
/// do EduTurmas (#79).
void main() {
  group('Regra de Negócio 1: Gestão de Turmas e Semestre', () {
    test('criação de turma com semestre e ano válidos persiste com totalAlunos zero',
        () async {
      await configurarBancoFalso();
      final repo = TurmaRepository();

      final criada = await repo.criar(
        descricao: '1º Ano B - Física',
        semestre: 2,
        ano: 2026,
      );

      expect(criada.id, isNotEmpty);
      expect(criada.descricao, '1º Ano B - Física');
      expect(criada.semestre, 2);
      expect(criada.ano, 2026);
      expect(criada.totalAlunos, 0);

      final listadas = await repo.listar();
      expect(listadas.any((t) => t.id == criada.id), isTrue);
    });

    test('edição de turma atualiza descrição e semestre', () async {
      await configurarBancoFalso();
      final repo = TurmaRepository();

      await repo.editar(
        id: 'turma-1',
        descricao: '3º Ano A - Matemática Avançada',
        semestre: 2,
        ano: 2026,
      );

      final turma = await repo.buscar('turma-1');
      expect(turma.descricao, '3º Ano A - Matemática Avançada');
      expect(turma.semestre, 2);
    });

    test('rejeita exclusão de turma com provas aplicadas', () async {
      await configurarBancoFalso();
      final turmaRepo = TurmaRepository();
      final avaliacaoRepo = AvaliacaoRepository();

      // Marca a avaliação da turma como concluída
      await avaliacaoRepo.atualizarStatus('aval-1', AssessmentStatus.completed);

      expect(
        () => turmaRepo.excluir('turma-1'),
        throwsA(isA<TurmaComProvaAplicadaException>()),
      );
    });
  });

  group('Regra de Negócio 2: Alunos e Unicidade de Matrícula', () {
    test('impede cadastro de aluno com matrícula repetida na mesma turma',
        () async {
      await configurarBancoFalso();
      final repo = AlunoRepository();

      // '2026041' já pertence à aluna Ana Beatriz na 'turma-1'
      expect(
        () => repo.adicionar(
          turmaId: 'turma-1',
          nome: 'Aluno Repetido',
          matricula: '2026041',
        ),
        throwsA(isA<MatriculaDuplicadaException>()),
      );
    });

    test('permite atualizar dados de um aluno existente mantendo a matrícula',
        () async {
      await configurarBancoFalso();
      final repo = AlunoRepository();

      await repo.editar(
        id: 'aluno-1',
        turmaId: 'turma-1',
        nome: 'Ana Beatriz Souza',
        matricula: '2026041',
      );

      final alunos = await repo.listarPorTurma('turma-1');
      final ana = alunos.firstWhere((a) => a.id == 'aluno-1');
      expect(ana.nome, 'Ana Beatriz Souza');
      expect(ana.matricula, '2026041');
    });

    test('impede exclusão de aluno quando há prova aplicada na turma', () async {
      await configurarBancoFalso();
      final avaliacaoRepo = AvaliacaoRepository();
      final alunoRepo = AlunoRepository();

      // Atualiza avaliação para concluída / aplicada
      await avaliacaoRepo.atualizarStatus('aval-1', AssessmentStatus.completed);

      expect(
        () => alunoRepo.excluir(alunoId: 'aluno-1', turmaId: 'turma-1'),
        throwsA(isA<AlunoComProvaAplicadaException>()),
      );
    });

    test('permite excluir aluno quando não há prova aplicada na turma',
        () async {
      final firestore = await configurarBancoFalso();
      // Remove avaliações para simular turma sem prova aplicada
      final avaliacoes = await firestore.collection('avaliacoes').get();
      for (final doc in avaliacoes.docs) {
        await doc.reference.delete();
      }

      final alunoRepo = AlunoRepository();
      await alunoRepo.excluir(alunoId: 'aluno-2', turmaId: 'turma-1');

      final restantes = await alunoRepo.listarPorTurma('turma-1');
      expect(restantes.any((a) => a.id == 'aluno-2'), isFalse);
    });
  });

  group('Regra de Negócio 3: Ciclo de Vida e Transições da Avaliação', () {
    test('cria avaliação em rascunho (draft) e transiciona para scheduled ao salvar gabarito',
        () async {
      await configurarBancoFalso();
      final repo = AvaliacaoRepository();
      final turma = await TurmaRepository().buscar('turma-1');

      final rascunho = await repo.criar(
        turma: turma,
        titulo: 'Simulado ENEM',
        disciplina: 'Ciências',
        totalQuestoes: 5,
      );

      expect(rascunho.status, AssessmentStatus.draft);
      expect(rascunho.isDraft, isTrue);
      expect(rascunho.gabaritoConfigurado, isFalse);

      final agendada = await repo.salvarGabarito(
        rascunho,
        ['A', 'B', 'C', 'D', 'E'],
      );
      expect(agendada.status, AssessmentStatus.scheduled);
      expect(agendada.isScheduled, isTrue);
      expect(agendada.gabaritoConfigurado, isTrue);
      expect(agendada.gabarito.length, 5);
    });

    test('rejeita exclusão de avaliação concluída/aplicada', () async {
      await configurarBancoFalso();
      final repo = AvaliacaoRepository();

      await repo.atualizarStatus('aval-1', AssessmentStatus.completed);
      expect(
        () => repo.excluir('aval-1'),
        throwsA(isA<StateError>()),
      );
    });

    test('permite exclusão de avaliação não aplicada', () async {
      await configurarBancoFalso();
      final repo = AvaliacaoRepository();

      await repo.excluir('aval-1');
      final lista = await repo.listar();
      expect(lista.any((a) => a.id == 'aval-1'), isFalse);
    });
  });

  group('Regra de Negócio 4: Cálculo de Notas, Pesos e Aprovação', () {
    Assessment criarProva(List<QuestaoGabarito> gabarito) => Assessment(
          id: 'aval-calc',
          turmaId: 'turma-1',
          gabarito: gabarito,
          title: 'Prova de Teste',
          subject: 'Geral',
          className: 'Turma Teste',
          dateLabel: 'Hoje',
          status: AssessmentStatus.scheduled,
          totalQuestions: gabarito.length,
          correctedStudents: 0,
          totalStudents: 1,
        );

    test('calcula nota proporcional de 0.0 a 10.0 com 4 alternativas', () {
      final prova = criarProva([
        const QuestaoGabarito(questao: 1, alternativaCorreta: 'A'),
        const QuestaoGabarito(questao: 2, alternativaCorreta: 'B'),
        const QuestaoGabarito(questao: 3, alternativaCorreta: 'C'),
        const QuestaoGabarito(questao: 4, alternativaCorreta: 'D'),
      ]);

      // 3 acertos de 4 = 7.5
      final r1 = ResultadoRepository.corrigir(
        id: 'r1',
        avaliacao: prova,
        alunoId: 'a1',
        respostas: ['A', 'B', 'C', 'A'],
      );
      expect(r1.totalAcertos, 3);
      expect(r1.notaCalculada, 7.5);
      expect(r1.aprovado, isTrue);

      // 2 acertos de 4 = 5.0 (reprovado)
      final r2 = ResultadoRepository.corrigir(
        id: 'r2',
        avaliacao: prova,
        alunoId: 'a2',
        respostas: ['A', 'B', 'A', 'A'],
      );
      expect(r2.totalAcertos, 2);
      expect(r2.notaCalculada, 5.0);
      expect(r2.aprovado, isFalse);
    });

    test('critério de corte: nota >= 6.0 é aprovação e < 6.0 é reprovação', () {
      final prova10 = criarProva([
        for (var q = 1; q <= 10; q++)
          QuestaoGabarito(questao: q, alternativaCorreta: 'A'),
      ]);

      // Exatamente 6 acertos em 10 = nota 6.0
      final rAprovado = ResultadoRepository.corrigir(
        id: 'ra',
        avaliacao: prova10,
        alunoId: 'a1',
        respostas: [...List.filled(6, 'A'), ...List.filled(4, 'B')],
      );
      expect(rAprovado.notaCalculada, 6.0);
      expect(rAprovado.aprovado, isTrue);

      // 5 acertos em 10 = nota 5.0
      final rReprovado = ResultadoRepository.corrigir(
        id: 'rr',
        avaliacao: prova10,
        alunoId: 'a2',
        respostas: [...List.filled(5, 'A'), ...List.filled(5, 'B')],
      );
      expect(rReprovado.notaCalculada, 5.0);
      expect(rReprovado.aprovado, isFalse);
    });

    test('respostas nulas ou folhas incompletas pontuam zero para a questão', () {
      final prova = criarProva([
        const QuestaoGabarito(questao: 1, alternativaCorreta: 'A'),
        const QuestaoGabarito(questao: 2, alternativaCorreta: 'B'),
      ]);

      final resultado = ResultadoRepository.corrigir(
        id: 'r',
        avaliacao: prova,
        alunoId: 'a1',
        respostas: ['A', null],
      );

      expect(resultado.totalAcertos, 1);
      expect(resultado.notaCalculada, 5.0);
      expect(resultado.respostas.last.alternativaMarcada, isNull);
      expect(resultado.respostas.last.correta, isFalse);
    });
  });

  group('Regra de Negócio 5: Encerramento de Correção e Alunos Ausentes', () {
    test('encerrarCorrecao atribui nota 0 para alunos sem folha corrigida e completa a prova',
        () async {
      await configurarBancoFalso();
      final avaliacaoRepo = AvaliacaoRepository();
      final resultadoRepo = ResultadoRepository();

      final avaliacao = await avaliacaoRepo.buscar('aval-1');

      // Corrige apenas a aluna 1 (Ana Beatriz com nota 10.0)
      const aluno1 = Aluno(
        id: 'aluno-1',
        turmaId: 'turma-1',
        nome: 'Ana Beatriz',
        matricula: '2026041',
      );
      await resultadoRepo.salvar(
        avaliacao: avaliacao,
        aluno: aluno1,
        respostas: ['A', 'B', 'C', 'D'],
      );

      // Aluno 2 (Carlos Dias) não compareceu / não foi corrigido
      final ausentesAtribuidos = await resultadoRepo.encerrarCorrecao(
        avaliacao: avaliacao,
      );
      expect(ausentesAtribuidos, 1);

      // Verifica que a aluna 1 manteve 10.0 e o aluno 2 recebeu 0.0
      final resultados = await resultadoRepo.listarPorAvaliacao('aval-1');
      expect(resultados, hasLength(2));

      final rAna = resultados.firstWhere((r) => r.alunoId == 'aluno-1');
      final rCarlos = resultados.firstWhere((r) => r.alunoId == 'aluno-2');

      expect(rAna.notaCalculada, 10.0);
      expect(rAna.aprovado, isTrue);

      expect(rCarlos.notaCalculada, 0.0);
      expect(rCarlos.aprovado, isFalse);
      expect(rCarlos.respostas.every((r) => r.alternativaMarcada == null), isTrue);

      // Avaliação passa a completed
      final avaliacaoAtualizada = await avaliacaoRepo.buscar('aval-1');
      expect(avaliacaoAtualizada.status, AssessmentStatus.completed);
    });
  });

  group('Regra de Negócio 6: Isolamento Multi-Tenant por Professor', () {
    test('turmas e avaliações pertencem estritamente ao professor logado',
        () async {
      final firestore = await configurarBancoFalso();

      // Insere turma pertencente a outro professor (prof-2)
      await firestore.collection('turmas').doc('turma-outro-prof').set({
        'professorId': 'prof-2',
        'descricao': 'Turma do Professor 2',
        'semestre': 1,
        'ano': 2026,
        'totalAlunos': 30,
        'criadoEm': Timestamp.now(),
      });

      final turmasProf1 = await TurmaRepository().listar();
      expect(turmasProf1.any((t) => t.id == 'turma-outro-prof'), isFalse);
    });
  });

  group('Regra de Negócio 7: Importação CSV e Tratamento de Duplicidades', () {
    test('parseStudents processa CSV e desconsidera matrículas repetidas', () {
      const csvContent = '''
Nome,Matrícula
Lucas Gabriel,2026100
Mariana Costa,2026101
Lucas Repetido,2026100
,2026102
''';

      final resultado = CsvImportService.parseStudents(csvContent);
      expect(resultado.alunos, hasLength(2));
      expect(resultado.alunos[0].matricula, '2026100');
      expect(resultado.alunos[1].matricula, '2026101');
      expect(resultado.erros, hasLength(2)); // 1 duplicada + 1 sem nome
    });

    test('parseQuestions valida alternativas e pesos', () {
      const csvGabarito = '''
Questão,Resposta,Peso
1,A,2.0
2,B,1.5
3,Z,1.0
''';

      final resultado = CsvImportService.parseQuestions(csvGabarito);
      expect(resultado.questoes, hasLength(2));
      expect(resultado.questoes[0].alternativaCorreta, 'A');
      expect(resultado.questoes[1].alternativaCorreta, 'B');
      expect(resultado.erros, hasLength(1)); // Questão 3 com alternativa inválida 'Z'
    });
  });

  group('Regra de Negócio 8: Reconhecimento OMR e Detecção de Ambiguidade', () {
    test('marcação regular única é lida com alta precisão sem ambiguidade', () {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', 'B', 'C', 'D'],
      );
      final resultado = OmrProcessor.processDensityMatrix(matrix);

      expect(resultado.needsManualReview, isFalse);
      expect(resultado.formattedAnswers, ['A', 'B', 'C', 'D']);
    });

    test('marcação dupla ou ambígua ativa sinalizador de revisão manual', () {
      final matrix = OmrProcessor.createDensityMatrix(
        answers: ['A', 'B', 'C', 'D'],
        ambiguousQuestions: {2}, // questão 2 ambígua
      );
      final resultado = OmrProcessor.processDensityMatrix(matrix);

      expect(resultado.needsManualReview, isTrue);
      expect(resultado.questions.any((q) => q.questao == 2 && q.isAmbiguous), isTrue);
    });
  });
}
