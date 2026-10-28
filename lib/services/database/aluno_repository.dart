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
        'nome': nome,
        'matricula': matricula,
        'criadoEm': FieldValue.serverTimestamp(),
      })
      ..update(turmas.doc(turmaId), {'totalAlunos': FieldValue.increment(1)});
    await batch.commit();

    return Aluno(
      id: ref.id,
      turmaId: turmaId,
      nome: nome,
      matricula: matricula,
    );
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
