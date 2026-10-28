class RespostaAluno {
  const RespostaAluno({
    required this.questao,
    required this.alternativaMarcada,
    required this.correta,
  });

  final int questao;
  final String? alternativaMarcada;
  final bool correta;
}

/// Correção da prova de um aluno em uma avaliação.
class Resultado {
  const Resultado({
    required this.id,
    required this.avaliacaoId,
    required this.turmaId,
    required this.alunoId,
    required this.respostas,
    required this.totalAcertos,
    required this.notaCalculada,
  });

  final String id;
  final String avaliacaoId;
  final String turmaId;
  final String alunoId;
  final List<RespostaAluno> respostas;
  final int totalAcertos;

  /// Nota de 0 a 10, ponderada pelos pesos do gabarito.
  final double notaCalculada;

  bool get aprovado => notaCalculada >= 6.0;
}
