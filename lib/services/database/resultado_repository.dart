import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/aluno.dart';
import '../../models/assessment.dart';
import '../../models/resultado.dart';
import 'database.dart';

class ResultadoRepository extends FirestoreRepository {
  Future<List<Resultado>> listarPorAvaliacao(String avaliacaoId) async {
    final snapshot = await resultados
        .where('professorId', isEqualTo: professorId)
        .where('avaliacaoId', isEqualTo: avaliacaoId)
        .get();
    return snapshot.docs.map(fromDoc).toList();
  }

  Future<List<Resultado>> listarTodos() async {
    final snapshot = await resultados
        .where('professorId', isEqualTo: professorId)
        .get();
    return snapshot.docs.map(fromDoc).toList();
  }

  /// Corrige as [respostas] do aluno e salva o resultado.
  ///
  /// O documento usa o id `{avaliacaoId}_{alunoId}`, então corrigir o mesmo
  /// aluno de novo substitui o resultado anterior. Quando todos os alunos da
  /// turma têm resultado, a avaliação passa a `concluida`.
  Future<Resultado> salvar({
    required Assessment avaliacao,
    required Aluno aluno,
    required List<String?> respostas,
  }) async {
    final resultado = corrigir(
      id: '${avaliacao.id}_${aluno.id}',
      avaliacao: avaliacao,
      alunoId: aluno.id,
      respostas: respostas,
    );

    await resultados.doc(resultado.id).set({
      'avaliacaoId': resultado.avaliacaoId,
      'turmaId': resultado.turmaId,
      'professorId': professorId,
      'alunoId': resultado.alunoId,
      'respostasAluno': [
        for (final resposta in resultado.respostas)
          {
            'questao': resposta.questao,
            'alternativaMarcada': resposta.alternativaMarcada,
            'correta': resposta.correta,
          },
      ],
      'totalAcertos': resultado.totalAcertos,
      'notaCalculada': resultado.notaCalculada,
      'corrigidoEm': FieldValue.serverTimestamp(),
    });

    if (avaliacao.status != AssessmentStatus.completed &&
        avaliacao.totalStudents > 0) {
      final corrigidos = await resultados
          .where('professorId', isEqualTo: professorId)
          .where('avaliacaoId', isEqualTo: avaliacao.id)
          .count()
          .get();
      if ((corrigidos.count ?? 0) >= avaliacao.totalStudents) {
        await AvaliacaoRepository().atualizarStatus(
          avaliacao.id,
          AssessmentStatus.completed,
        );
      }
    }

    return resultado;
  }

  /// Encerra a correcao de uma avaliacao atribuindo nota 0 para todos os alunos
  /// da turma que ainda nao possuem resultado registrado.
  Future<int> encerrarCorrecao({required Assessment avaliacao}) async {
    final alunos = await AlunoRepository().listarPorTurma(avaliacao.turmaId);
    final resultadosExistentes = await listarPorAvaliacao(avaliacao.id);
    final alunosComResultado =
        resultadosExistentes.map((r) => r.alunoId).toSet();

    var ausentesAtribuidos = 0;

    for (final aluno in alunos) {
      if (alunosComResultado.contains(aluno.id)) {
        continue;
      }

      final respostasVazias = [
        for (final q in avaliacao.gabarito)
          RespostaAluno(
            questao: q.questao,
            alternativaMarcada: null,
            correta: false,
          ),
      ];

      final resultadoZero = Resultado(
        id: '${avaliacao.id}_${aluno.id}',
        avaliacaoId: avaliacao.id,
        turmaId: avaliacao.turmaId,
        alunoId: aluno.id,
        respostas: respostasVazias,
        totalAcertos: 0,
        notaCalculada: 0.0,
      );

      await resultados.doc(resultadoZero.id).set({
        'avaliacaoId': resultadoZero.avaliacaoId,
        'turmaId': resultadoZero.turmaId,
        'professorId': professorId,
        'alunoId': resultadoZero.alunoId,
        'respostasAluno': [
          for (final r in resultadoZero.respostas)
            {
              'questao': r.questao,
              'alternativaMarcada': null,
              'correta': false,
            },
        ],
        'totalAcertos': 0,
        'notaCalculada': 0.0,
        'ausente': true,
        'corrigidoEm': FieldValue.serverTimestamp(),
      });

      alunosComResultado.add(aluno.id);
      ausentesAtribuidos++;
    }

    await AvaliacaoRepository().atualizarStatus(
      avaliacao.id,
      AssessmentStatus.completed,
    );

    return ausentesAtribuidos;
  }

  /// Compara as respostas com o gabarito. A nota vai de 0 a 10 e considera o
  /// peso de cada questão.
  static Resultado corrigir({
    required String id,
    required Assessment avaliacao,
    required String alunoId,
    required List<String?> respostas,
  }) {
    final corrigidas = <RespostaAluno>[];
    var pesoTotal = 0.0;
    var pesoAcertos = 0.0;

    for (final questao in avaliacao.gabarito) {
      final marcada = questao.questao <= respostas.length
          ? respostas[questao.questao - 1]
          : null;
      final correta = marcada != null && marcada == questao.alternativaCorreta;
      corrigidas.add(
        RespostaAluno(
          questao: questao.questao,
          alternativaMarcada: marcada,
          correta: correta,
        ),
      );
      pesoTotal += questao.peso;
      if (correta) {
        pesoAcertos += questao.peso;
      }
    }
    final nota = pesoTotal == 0 ? 0.0 : 10 * pesoAcertos / pesoTotal;

    return Resultado(
      id: id,
      avaliacaoId: avaliacao.id,
      turmaId: avaliacao.turmaId,
      alunoId: alunoId,
      respostas: corrigidas,
      totalAcertos: corrigidas.where((resposta) => resposta.correta).length,
      notaCalculada: (nota * 100).round() / 100,
    );
  }

  static Resultado fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final respostas = ((data['respostasAluno'] as List?) ?? const []).map((
      item,
    ) {
      final resposta = Map<String, dynamic>.from(item as Map);
      return RespostaAluno(
        questao: (resposta['questao'] as num).toInt(),
        alternativaMarcada: resposta['alternativaMarcada'] as String?,
        correta: resposta['correta'] as bool? ?? false,
      );
    }).toList();

    return Resultado(
      id: doc.id,
      avaliacaoId: data['avaliacaoId'] as String? ?? '',
      turmaId: data['turmaId'] as String? ?? '',
      alunoId: data['alunoId'] as String? ?? '',
      respostas: respostas,
      totalAcertos: (data['totalAcertos'] as num?)?.toInt() ?? 0,
      notaCalculada: (data['notaCalculada'] as num?)?.toDouble() ?? 0,
    );
  }
}
