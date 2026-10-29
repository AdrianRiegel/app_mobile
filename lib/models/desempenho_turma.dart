import 'aluno.dart';
import 'assessment.dart';
import 'resultado.dart';

/// Nota mínima para o aluno ser considerado aprovado em uma prova.
const double notaMinimaAprovacao = 6.0;

/// Desempenho de um aluno em uma prova. [resultado] fica `null` quando o
/// aluno ainda não teve a prova corrigida.
class DesempenhoAluno {
  const DesempenhoAluno({required this.aluno, this.resultado});

  final Aluno aluno;
  final Resultado? resultado;

  bool get corrigido => resultado != null;

  String get situacao {
    final atual = resultado;
    if (atual == null) return 'Sem correção';
    return atual.notaCalculada >= notaMinimaAprovacao
        ? 'Aprovado'
        : 'Reprovado';
  }
}

/// Desempenho de todos os alunos da turma em uma prova.
class DesempenhoProva {
  const DesempenhoProva({required this.avaliacao, required this.alunos});

  final Assessment avaliacao;
  final List<DesempenhoAluno> alunos;

  List<Resultado> get _resultados => [
    for (final aluno in alunos)
      if (aluno.resultado != null) aluno.resultado!,
  ];

  int get corrigidos => _resultados.length;

  int get aprovados => _resultados
      .where((resultado) => resultado.notaCalculada >= notaMinimaAprovacao)
      .length;

  /// Média das notas (0 a 10) entre os alunos corrigidos.
  double get mediaNotas {
    final resultados = _resultados;
    if (resultados.isEmpty) return 0;
    final soma = resultados.fold<double>(
      0,
      (total, resultado) => total + resultado.notaCalculada,
    );
    return soma / resultados.length;
  }

  /// Percentual de aprovados entre os alunos corrigidos (0 a 100).
  int get percentualAprovacao =>
      corrigidos == 0 ? 0 : (100 * aprovados / corrigidos).round();
}

/// Desempenho da turma em todas as provas selecionadas para o relatório.
class DesempenhoTurma {
  const DesempenhoTurma({
    required this.turmaNome,
    required this.totalAlunos,
    required this.provas,
  });

  final String turmaNome;
  final int totalAlunos;
  final List<DesempenhoProva> provas;

  /// Média geral das notas, considerando só as provas com correções.
  double get mediaGeral {
    final comCorrecao = provas.where((prova) => prova.corrigidos > 0).toList();
    if (comCorrecao.isEmpty) return 0;
    final soma = comCorrecao.fold<double>(
      0,
      (total, prova) => total + prova.mediaNotas,
    );
    return soma / comCorrecao.length;
  }
}
