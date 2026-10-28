import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/csv_import_service.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/random_exam_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = await configurarBancoFalso();
  });

  group('AlunoRepository - Refatoração da tela de alunos', () {
    test('edita nome e matrícula de um aluno com sucesso', () async {
      final repo = AlunoRepository();
      final alunoAtualizado = await repo.editar(
        id: 'aluno-1',
        turmaId: 'turma-1',
        nome: 'Ana Beatriz Souza',
        matricula: '2026999',
      );

      expect(alunoAtualizado.nome, 'Ana Beatriz Souza');
      expect(alunoAtualizado.matricula, '2026999');

      final alunos = await repo.listarPorTurma('turma-1');
      final ana = alunos.firstWhere((a) => a.id == 'aluno-1');
      expect(ana.nome, 'Ana Beatriz Souza');
      expect(ana.matricula, '2026999');
    });

    test('rejeita edição de aluno com matrícula já existente', () async {
      final repo = AlunoRepository();
      expect(
        () => repo.editar(
          id: 'aluno-1',
          turmaId: 'turma-1',
          nome: 'Ana Beatriz',
          matricula: '2026042', // matrícula de Carlos Dias
        ),
        throwsA(isA<MatriculaDuplicadaException>()),
      );
    });

    test('permite excluir aluno quando não há prova aplicada', () async {
      final repo = AlunoRepository();
      // 'aval-1' está como agendada no mock, não concluída
      await repo.excluir(alunoId: 'aluno-1', turmaId: 'turma-1');

      final alunos = await repo.listarPorTurma('turma-1');
      expect(alunos.any((a) => a.id == 'aluno-1'), isFalse);

      final turma = await TurmaRepository().buscar('turma-1');
      expect(turma.totalAlunos, 1);
    });

    test('impede exclusão de aluno quando há prova aplicada na turma', () async {
      final repo = AlunoRepository();
      // Marca a avaliação como concluída/aplicada
      await firestore.collection('avaliacoes').doc('aval-1').update({
        'status': 'concluida',
      });

      expect(
        () => repo.excluir(alunoId: 'aluno-1', turmaId: 'turma-1'),
        throwsA(isA<AlunoComProvaAplicadaException>()),
      );
    });

    test('importa múltiplos alunos via repositório ignorando matrículas repetidas', () async {
      final repo = AlunoRepository();
      final adicionados = await repo.importarAlunos(
        turmaId: 'turma-1',
        novosAlunos: [
          (nome: 'Lucas Mendes', matricula: '2026043'),
          (nome: 'Mariana Lima', matricula: '2026044'),
          (nome: 'Aluno Repetido', matricula: '2026041'), // já existe
        ],
      );

      expect(adicionados, 2);
      final alunos = await repo.listarPorTurma('turma-1');
      expect(alunos.length, 4);
    });
  });

  group('AvaliacaoRepository - Refatoração da tela de provas e data de aplicação', () {
    test('cria avaliação com data de aplicação persistida', () async {
      final turma = await TurmaRepository().buscar('turma-1');
      final data = DateTime(2026, 11, 15);
      final repo = AvaliacaoRepository();

      final avaliacao = await repo.criar(
        turma: turma,
        titulo: 'Prova Final',
        disciplina: 'Física',
        totalQuestoes: 5,
        dataAplicacao: data,
      );

      expect(avaliacao.title, 'Prova Final');
      expect(avaliacao.dateLabel, '15 nov. 2026');
      expect(avaliacao.dataAplicacao?.day, 15);

      final buscada = await repo.buscar(avaliacao.id);
      expect(buscada.dateLabel, '15 nov. 2026');
    });

    test('edita informações básicas da avaliação', () async {
      final repo = AvaliacaoRepository();
      final novaData = DateTime(2026, 9, 30);

      final atualizada = await repo.editar(
        id: 'aval-1',
        titulo: 'Avaliação Cap. 4 e 5 - Revisada',
        disciplina: 'Matemática Avançada',
        dataAplicacao: novaData,
      );

      expect(atualizada.title, 'Avaliação Cap. 4 e 5 - Revisada');
      expect(atualizada.subject, 'Matemática Avançada');
      expect(atualizada.dateLabel, '30 set. 2026');
    });

    test('permite excluir avaliação que não está aplicada', () async {
      final repo = AvaliacaoRepository();
      await repo.excluir('aval-1');

      final provas = await repo.listar(turmaId: 'turma-1');
      expect(provas.any((p) => p.id == 'aval-1'), isFalse);
    });

    test('rejeita exclusão de avaliação concluída/aplicada', () async {
      final repo = AvaliacaoRepository();
      await firestore.collection('avaliacoes').doc('aval-1').update({
        'status': 'concluida',
      });

      expect(() => repo.excluir('aval-1'), throwsA(isA<StateError>()));
    });
  });

  group('CsvImportService - Regras de negócio de importação CSV', () {
    test('parseStudents processa CSV com separadores vírgula e ponto-e-vírgula', () {
      const csvVirgula = '''
nome,matricula
Carlos Santos,2026001
Juliana Paes,2026002
''';
      final res1 = CsvImportService.parseStudents(csvVirgula);
      expect(res1.alunos.length, 2);
      expect(res1.alunos[0].nome, 'Carlos Santos');
      expect(res1.alunos[0].matricula, '2026001');

      const csvPontoVirgula = '''
"nome";"matricula"
"Marcos, Junior";"2026003"
"Renata Silva";"2026004"
''';
      final res2 = CsvImportService.parseStudents(csvPontoVirgula);
      expect(res2.alunos.length, 2);
      expect(res2.alunos[0].nome, 'Marcos, Junior');
      expect(res2.alunos[0].matricula, '2026003');
    });

    test('parseStudents detecta matrículas duplicadas e linhas inválidas', () {
      const csv = '''
nome,matricula
Aluno A,2026001
Aluno B,2026001
,2026002
''';
      final res = CsvImportService.parseStudents(csv);
      expect(res.alunos.length, 1);
      expect(res.erros.length, 2);
      expect(res.erros.any((e) => e.contains('repetida')), isTrue);
      expect(res.erros.any((e) => e.contains('ausente')), isTrue);
    });

    test('parseQuestions processa gabarito de questões e pesos', () {
      const csv = '''
questao,resposta,peso
1,A,1.5
2,C,2.0
3,D,1.0
''';
      final res = CsvImportService.parseQuestions(csv);
      expect(res.questoes.length, 3);
      expect(res.questoes[0].questao, 1);
      expect(res.questoes[0].alternativaCorreta, 'A');
      expect(res.questoes[0].peso, 1.5);

      expect(res.questoes[1].questao, 2);
      expect(res.questoes[1].alternativaCorreta, 'C');
      expect(res.questoes[1].peso, 2.0);
    });

    test('parseQuestions valida alternativas de A a E', () {
      const csv = '''
questao;gabarito
1;A
2;Z
3;3
''';
      final res = CsvImportService.parseQuestions(csv);
      expect(res.questoes.length, 1);
      expect(res.erros.length, 2);
    });
  });

  group('RandomExamService - Geração randômica de provas para PDF', () {
    test('gera variantes da prova com gabarito correspondente mapeado', () {
      const original = Assessment(
        id: 'aval-1',
        title: 'Prova Bimestral',
        subject: 'História',
        className: '1º Ano',
        dateLabel: '28 out. 2026',
        status: AssessmentStatus.scheduled,
        totalQuestions: 4,
        correctedStudents: 0,
        totalStudents: 30,
        gabarito: [
          QuestaoGabarito(questao: 1, alternativaCorreta: 'A'),
          QuestaoGabarito(questao: 2, alternativaCorreta: 'B'),
          QuestaoGabarito(questao: 3, alternativaCorreta: 'C'),
          QuestaoGabarito(questao: 4, alternativaCorreta: 'D'),
        ],
      );

      final variantes = RandomExamService.gerarVariantes(
        assessment: original,
        quantidade: 2,
        seed: 42,
      );

      expect(variantes.length, 2);
      expect(variantes[0].variantLabel, 'Tipo A');
      expect(variantes[1].variantLabel, 'Tipo B');

      for (final v in variantes) {
        expect(v.questoes.length, 4);
        expect(v.mapaQuestoes.length, 4);

        // Verifica que todas as questões originais (1..4) estão presentes mapeadas
        for (var i = 1; i <= 4; i++) {
          final novaQuestaoNum = v.mapaQuestoes[i]!;
          final questaoNaVariante = v.questoes.firstWhere((q) => q.questao == novaQuestaoNum);
          final questaoOriginal = original.gabarito.firstWhere((q) => q.questao == i);
          expect(questaoNaVariante.alternativaCorreta, questaoOriginal.alternativaCorreta);
        }

        // Verifica layout do PDF gerado
        final layoutPdf = v.gerarLayoutProvaPdf();
        expect(layoutPdf.contains('AVALIAÇÃO ESCOLAR - ${v.variantLabel.toUpperCase()}'), isTrue);
        expect(layoutPdf.contains('FOLHA DE RESPOSTAS'), isTrue);
      }
    });
  });
}
