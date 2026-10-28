class Turma {
  const Turma({
    required this.id,
    required this.descricao,
    required this.semestre,
    required this.ano,
    this.totalAlunos = 0,
  });

  final String id;

  /// Descrição completa (ex.: `3º Ano A - Matemática`).
  final String descricao;
  final int semestre;
  final int ano;
  final int totalAlunos;

  /// Nome da turma sem a disciplina (ex.: `3º Ano A`).
  String get nome => descricao.split(' - ').first;

  /// Disciplina informada na descrição, ou vazio se não houver.
  String get disciplina {
    final partes = descricao.split(' - ');
    return partes.length > 1 ? partes.sublist(1).join(' - ') : '';
  }

  String get resumo => '$ano · $semestreº semestre · $totalAlunos alunos';
}
