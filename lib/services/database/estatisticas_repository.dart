import '../../models/assessment.dart';
import '../../models/resultado.dart';
import '../../models/statistics.dart';
import 'database.dart';

/// Monta as estatísticas das telas de Estatísticas e Relatório a partir das
/// avaliações e dos resultados salvos.
class EstatisticasRepository extends FirestoreRepository {
  /// Todas as turmas do professor com as provas que já têm correções.
  Future<List<ClassStatistics>> porTurma() async {
    final (turmasDoProfessor, avaliacoesDoProfessor, todosResultados) = await (
      TurmaRepository().listar(),
      AvaliacaoRepository().listar(),
      ResultadoRepository().listarTodos(),
    ).wait;

    final resultadosPorAvaliacao = <String, List<Resultado>>{};
    for (final resultado in todosResultados) {
      resultadosPorAvaliacao
          .putIfAbsent(resultado.avaliacaoId, () => [])
          .add(resultado);
    }

    return [
      for (final turma in turmasDoProfessor)
        ClassStatistics(
          turmaId: turma.id,
          className: turma.nome,
          subject: turma.disciplina,
          exams: [
            for (final avaliacao in avaliacoesDoProfessor)
              if (avaliacao.turmaId == turma.id &&
                  resultadosPorAvaliacao.containsKey(avaliacao.id))
                calcular(avaliacao, resultadosPorAvaliacao[avaliacao.id]!),
          ],
        ),
    ];
  }

  Future<ExamStatistics> daAvaliacao(Assessment avaliacao) async {
    final resultadosDaAvaliacao = await ResultadoRepository()
        .listarPorAvaliacao(avaliacao.id);
    return calcular(avaliacao, resultadosDaAvaliacao);
  }

  /// Percentual de acerto de cada questão entre os alunos corrigidos.
  static ExamStatistics calcular(
    Assessment avaliacao,
    List<Resultado> resultados,
  ) {
    final questions = [
      for (final questao in avaliacao.gabarito)
        QuestionStat(
          number: questao.questao,
          correctRate: resultados.isEmpty
              ? 0
              : (100 *
                        resultados
                            .where(
                              (resultado) => resultado.respostas.any(
                                (resposta) =>
                                    resposta.questao == questao.questao &&
                                    resposta.correta,
                              ),
                            )
                            .length /
                        resultados.length)
                    .round(),
        ),
    ];

    return ExamStatistics.fromQuestions(
      assessmentId: avaliacao.id,
      assessmentTitle: avaliacao.title,
      shortLabel: rotuloCurto(avaliacao.title),
      className: avaliacao.className,
      subject: avaliacao.subject,
      questions: questions,
    );
  }

  /// `Avaliação bimestral — Cap. 4` → `Cap. 4`.
  static String rotuloCurto(String titulo) {
    final partes = titulo.split(RegExp(r'\s+[—-]\s+'));
    return partes.length > 1 ? partes.last : titulo;
  }
}
