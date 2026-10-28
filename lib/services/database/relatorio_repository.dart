import '../../models/desempenho_turma.dart';
import '../../models/resultado.dart';
import 'database.dart';

/// Reúne os dados do relatório de desempenho da turma: cada aluno com a
/// nota que tirou em cada prova.
class RelatorioRepository extends FirestoreRepository {
  /// Desempenho da turma [turmaId]. Com [avaliacaoId], considera só essa
  /// prova; sem ele, todas as provas da turma que já têm correções.
  Future<DesempenhoTurma> desempenhoDaTurma(
    String turmaId, {
    String? avaliacaoId,
  }) async {
    final (turma, alunosDaTurma, avaliacoesDaTurma) = await (
      TurmaRepository().buscar(turmaId),
      AlunoRepository().listarPorTurma(turmaId),
      AvaliacaoRepository().listar(turmaId: turmaId),
    ).wait;

    final selecionadas = avaliacaoId == null
        ? avaliacoesDaTurma
        : avaliacoesDaTurma.where((avaliacao) => avaliacao.id == avaliacaoId);

    final provas = <DesempenhoProva>[];
    for (final avaliacao in selecionadas) {
      final resultados = await ResultadoRepository().listarPorAvaliacao(
        avaliacao.id,
      );
      if (avaliacaoId == null && resultados.isEmpty) continue;

      final resultadoPorAluno = <String, Resultado>{
        for (final resultado in resultados) resultado.alunoId: resultado,
      };
      provas.add(
        DesempenhoProva(
          avaliacao: avaliacao,
          alunos: [
            for (final aluno in alunosDaTurma)
              DesempenhoAluno(
                aluno: aluno,
                resultado: resultadoPorAluno[aluno.id],
              ),
          ],
        ),
      );
    }

    return DesempenhoTurma(
      turmaNome: turma.descricao,
      totalAlunos: alunosDaTurma.length,
      provas: provas,
    );
  }
}
