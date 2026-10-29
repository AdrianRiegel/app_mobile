import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/aluno.dart';
import 'database.dart';

class MatriculaDuplicadaException implements Exception {
  const MatriculaDuplicadaException(this.matricula);

  final String matricula;

  String get message => 'Já existe um aluno com a matrícula $matricula';

  @override
  String toString() => message;
}

/// Exceção lançada ao tentar excluir aluno de uma turma que já possui prova aplicada.
class AlunoComProvaAplicadaException implements Exception {
  const AlunoComProvaAplicadaException([
    this.message =
        'Não é possível excluir o aluno pois a turma já possui prova aplicada',
  ]);

  final String message;

  @override
  String toString() => message;
}

class AlunoRepository extends FirestoreRepository {
  Future<List<Aluno>> listarPorTurma(String turmaId) async {
    final snapshot = await alunos
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: turmaId)
        .get();
    return snapshot.docs.map(fromDoc).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  /// Cadastra o aluno e incrementa `totalAlunos` da turma na mesma escrita.
  ///
  /// Lança [MatriculaDuplicadaException] se a matrícula já existir na turma.
  Future<Aluno> adicionar({
    required String turmaId,
    required String nome,
    required String matricula,
  }) async {
    final existentes = await alunos
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: turmaId)
        .where('matricula', isEqualTo: matricula)
        .limit(1)
        .get();
    if (existentes.docs.isNotEmpty) {
      throw MatriculaDuplicadaException(matricula);
    }

    final ref = alunos.doc();
    final batch = firestore.batch()
      ..set(ref, {
        'turmaId': turmaId,
        'professorId': professorId,
        'nome': nome.trim(),
        'matricula': matricula.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      })
      ..update(turmas.doc(turmaId), {'totalAlunos': FieldValue.increment(1)});
    await batch.commit();

    return Aluno(
      id: ref.id,
      turmaId: turmaId,
      nome: nome.trim(),
      matricula: matricula.trim(),
    );
  }

  /// Atualiza os dados de um aluno (nome e matrícula), verificando duplicidade.
  Future<Aluno> editar({
    required String id,
    required String turmaId,
    required String nome,
    required String matricula,
  }) async {
    final nomeLimpo = nome.trim();
    final matriculaLimpa = matricula.trim();

    final existentes = await alunos
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: turmaId)
        .where('matricula', isEqualTo: matriculaLimpa)
        .get();

    final conflito = existentes.docs.any((doc) => doc.id != id);
    if (conflito) {
      throw MatriculaDuplicadaException(matriculaLimpa);
    }

    await alunos.doc(id).update({
      'nome': nomeLimpo,
      'matricula': matriculaLimpa,
    });

    return Aluno(
      id: id,
      turmaId: turmaId,
      nome: nomeLimpo,
      matricula: matriculaLimpa,
    );
  }

  /// Verifica se a turma possui provas concluídas/aplicadas ou correções registradas.
  Future<bool> turmaTemProvaAplicada(String turmaId) async {
    final provas = await avaliacoes
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: turmaId)
        .where('status', isEqualTo: 'concluida')
        .limit(1)
        .get();
    if (provas.docs.isNotEmpty) return true;

    final resultadosDaTurma = await resultados
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: turmaId)
        .limit(1)
        .get();
    return resultadosDaTurma.docs.isNotEmpty;
  }

  /// Exclui o aluno se a turma NÃO possuir nenhuma prova aplicada.
  /// Lança [AlunoComProvaAplicadaException] caso contrário.
  Future<void> excluir({
    required String alunoId,
    required String turmaId,
  }) async {
    final temProva = await turmaTemProvaAplicada(turmaId);
    if (temProva) {
      throw const AlunoComProvaAplicadaException();
    }

    final batch = firestore.batch()
      ..delete(alunos.doc(alunoId))
      ..update(turmas.doc(turmaId), {'totalAlunos': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Importa uma lista de alunos para a turma, ignorando matrículas já existentes.
  /// Retorna o número de alunos adicionados.
  Future<int> importarAlunos({
    required String turmaId,
    required List<({String nome, String matricula})> novosAlunos,
  }) async {
    if (novosAlunos.isEmpty) return 0;

    final atuais = await listarPorTurma(turmaId);
    final matriculasExistentes = {for (final a in atuais) a.matricula};

    final batch = firestore.batch();
    var inseridos = 0;

    for (final aluno in novosAlunos) {
      final matricula = aluno.matricula.trim();
      final nome = aluno.nome.trim();
      if (matricula.isEmpty || nome.isEmpty) continue;
      if (matriculasExistentes.contains(matricula)) continue;

      matriculasExistentes.add(matricula);
      final ref = alunos.doc();
      batch.set(ref, {
        'turmaId': turmaId,
        'professorId': professorId,
        'nome': nome,
        'matricula': matricula,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      inseridos++;
    }

    if (inseridos > 0) {
      batch.update(turmas.doc(turmaId), {
        'totalAlunos': FieldValue.increment(inseridos),
      });
      await batch.commit();
    }

    return inseridos;
  }

  static Aluno fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Aluno(
      id: doc.id,
      turmaId: data['turmaId'] as String? ?? '',
      nome: data['nome'] as String? ?? '',
      matricula: data['matricula'] as String? ?? '',
    );
  }
}
