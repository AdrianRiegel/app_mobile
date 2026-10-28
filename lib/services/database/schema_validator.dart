/// Validador de esquemas das coleções do Firestore para o EduTurmas.
///
/// Garante a conformidade dos dados antes da persistência e verifica a
/// integridade dos relacionamentos entre documentos.
class SchemaValidationException implements Exception {
  const SchemaValidationException(this.message);
  final String message;

  @override
  String toString() => 'SchemaValidationException: $message';
}

abstract final class SchemaValidator {
  /// Valida dados da collection `usuarios`.
  static void validateUsuario(Map<String, dynamic> data) {
    _requireNonEmptyString(data['nome'], 'usuarios.nome');
    _requireNonEmptyString(data['email'], 'usuarios.email');
    if (!data['email'].toString().contains('@')) {
      throw const SchemaValidationException('E-mail do usuário inválido');
    }
  }

  /// Valida dados da collection `turmas`.
  static void validateTurma(Map<String, dynamic> data) {
    _requireNonEmptyString(data['professorId'], 'turmas.professorId');
    _requireNonEmptyString(data['descricao'], 'turmas.descricao');
    final semestre = data['semestre'];
    if (semestre is! num || semestre < 1 || semestre > 2) {
      throw const SchemaValidationException('turmas.semestre deve ser 1 ou 2');
    }
    final ano = data['ano'];
    if (ano is! num || ano < 2000) {
      throw const SchemaValidationException('turmas.ano deve ser um ano válido');
    }
  }

  /// Valida dados da collection `alunos`.
  static void validateAluno(Map<String, dynamic> data) {
    _requireNonEmptyString(data['professorId'], 'alunos.professorId');
    _requireNonEmptyString(data['turmaId'], 'alunos.turmaId');
    _requireNonEmptyString(data['nome'], 'alunos.nome');
    _requireNonEmptyString(data['matricula'], 'alunos.matricula');
  }

  /// Valida dados da collection `avaliacoes`.
  static void validateAvaliacao(Map<String, dynamic> data) {
    _requireNonEmptyString(data['professorId'], 'avaliacoes.professorId');
    _requireNonEmptyString(data['turmaId'], 'avaliacoes.turmaId');
    _requireNonEmptyString(data['titulo'], 'avaliacoes.titulo');
    _requireNonEmptyString(data['disciplina'], 'avaliacoes.disciplina');

    const statusValidos = {'rascunho', 'agendada', 'concluida'};
    final status = data['status'];
    if (!statusValidos.contains(status)) {
      throw SchemaValidationException(
        'avaliacoes.status inválido: $status. Esperado: $statusValidos',
      );
    }

    final totalQuestoes = data['totalQuestoes'];
    if (totalQuestoes is! num || totalQuestoes <= 0) {
      throw const SchemaValidationException(
        'avaliacoes.totalQuestoes deve ser maior que 0',
      );
    }

    final gabarito = data['gabarito'];
    if (gabarito is! List) {
      throw const SchemaValidationException('avaliacoes.gabarito deve ser uma lista');
    }
  }

  /// Valida dados da collection `resultados`.
  static void validateResultado(Map<String, dynamic> data) {
    _requireNonEmptyString(data['professorId'], 'resultados.professorId');
    _requireNonEmptyString(data['avaliacaoId'], 'resultados.avaliacaoId');
    _requireNonEmptyString(data['alunoId'], 'resultados.alunoId');
    _requireNonEmptyString(data['turmaId'], 'resultados.turmaId');

    final totalAcertos = data['totalAcertos'];
    if (totalAcertos is! num || totalAcertos < 0) {
      throw const SchemaValidationException(
        'resultados.totalAcertos deve ser >= 0',
      );
    }

    final nota = data['notaCalculada'];
    if (nota is! num || nota < 0.0 || nota > 10.0) {
      throw const SchemaValidationException(
        'resultados.notaCalculada deve estar entre 0.0 e 10.0',
      );
    }
  }

  static void _requireNonEmptyString(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw SchemaValidationException('$fieldName é obrigatório e não pode ser vazio');
    }
  }
}
