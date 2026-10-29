import 'package:app_mobile/services/database/schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchemaValidator', () {
    test('valida usuário válido e rejeita e-mail inválido', () {
      expect(
        () => SchemaValidator.validateUsuario({
          'nome': 'Professor Teste',
          'email': 'professor@escola.com',
        }),
        returnsNormally,
      );

      expect(
        () => SchemaValidator.validateUsuario({
          'nome': 'Professor Teste',
          'email': 'emailinvalido',
        }),
        throwsA(isA<SchemaValidationException>()),
      );

      expect(
        () => SchemaValidator.validateUsuario({
          'nome': '',
          'email': 'professor@escola.com',
        }),
        throwsA(isA<SchemaValidationException>()),
      );
    });

    test('valida turma com regras de semestre e ano', () {
      expect(
        () => SchemaValidator.validateTurma({
          'professorId': 'prof-1',
          'descricao': '3º Ano A',
          'semestre': 1,
          'ano': 2026,
        }),
        returnsNormally,
      );

      expect(
        () => SchemaValidator.validateTurma({
          'professorId': 'prof-1',
          'descricao': '3º Ano A',
          'semestre': 3, // inválido
          'ano': 2026,
        }),
        throwsA(isA<SchemaValidationException>()),
      );
    });

    test('valida aluno e exige matrícula preenchida', () {
      expect(
        () => SchemaValidator.validateAluno({
          'professorId': 'prof-1',
          'turmaId': 'turma-1',
          'nome': 'Carlos Silva',
          'matricula': '2026001',
        }),
        returnsNormally,
      );

      expect(
        () => SchemaValidator.validateAluno({
          'professorId': 'prof-1',
          'turmaId': 'turma-1',
          'nome': 'Carlos Silva',
          'matricula': '',
        }),
        throwsA(isA<SchemaValidationException>()),
      );
    });

    test('valida avaliação com status permitidos', () {
      expect(
        () => SchemaValidator.validateAvaliacao({
          'professorId': 'prof-1',
          'turmaId': 'turma-1',
          'titulo': 'Prova 1',
          'disciplina': 'Matemática',
          'status': 'agendada',
          'totalQuestoes': 5,
          'gabarito': [],
        }),
        returnsNormally,
      );

      expect(
        () => SchemaValidator.validateAvaliacao({
          'professorId': 'prof-1',
          'turmaId': 'turma-1',
          'titulo': 'Prova 1',
          'disciplina': 'Matemática',
          'status': 'status_inexistente',
          'totalQuestoes': 5,
          'gabarito': [],
        }),
        throwsA(isA<SchemaValidationException>()),
      );
    });

    test('valida resultado garantindo notas de 0 a 10', () {
      expect(
        () => SchemaValidator.validateResultado({
          'professorId': 'prof-1',
          'avaliacaoId': 'aval-1',
          'alunoId': 'aluno-1',
          'turmaId': 'turma-1',
          'totalAcertos': 8,
          'notaCalculada': 8.5,
        }),
        returnsNormally,
      );

      expect(
        () => SchemaValidator.validateResultado({
          'professorId': 'prof-1',
          'avaliacaoId': 'aval-1',
          'alunoId': 'aluno-1',
          'turmaId': 'turma-1',
          'totalAcertos': 8,
          'notaCalculada': 12.0, // fora da faixa
        }),
        throwsA(isA<SchemaValidationException>()),
      );
    });
  });
}
