import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/turma.dart';
import 'database.dart';

class TurmaComProvaAplicadaException implements Exception {
  const TurmaComProvaAplicadaException();
  @override
  String toString() =>
      'Não é possível excluir uma turma com provas aplicadas ou resultados.';
}

class TurmaRepository extends FirestoreRepository {
  /// Turmas do professor, das mais recentes (ano/semestre) para as antigas.
  Future<List<Turma>> listar() async {
    final snapshot = await turmas
        .where('professorId', isEqualTo: professorId)
        .get();
    return snapshot.docs.map(fromDoc).toList()..sort((a, b) {
      final porAno = b.ano.compareTo(a.ano);
      if (porAno != 0) return porAno;
      final porSemestre = b.semestre.compareTo(a.semestre);
      if (porSemestre != 0) return porSemestre;
      return a.descricao.toLowerCase().compareTo(b.descricao.toLowerCase());
    });
  }

  Future<Turma> buscar(String id) async {
    final doc = await turmas.doc(id).get();
    if (!doc.exists) {
      throw StateError('Turma $id não encontrada');
    }
    return fromDoc(doc);
  }

  Future<Turma> criar({
    required String descricao,
    required int semestre,
    required int ano,
  }) async {
    final ref = await turmas.add({
      'professorId': professorId,
      'descricao': descricao,
      'semestre': semestre,
      'ano': ano,
      'totalAlunos': 0,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return Turma(
      id: ref.id,
      descricao: descricao,
      semestre: semestre,
      ano: ano,
    );
  }

  Future<void> editar({
    required String id,
    required String descricao,
    required int semestre,
    required int ano,
  }) async {
    if (descricao.trim().isEmpty ||
        semestre < 1 ||
        semestre > 2 ||
        ano < 2000 ||
        ano > 2100) {
      throw ArgumentError('Informe descrição, semestre e ano válidos');
    }
    await turmas.doc(id).update({
      'descricao': descricao.trim(),
      'semestre': semestre,
      'ano': ano,
    });
  }

  Future<void> excluir(String id) async {
    if (await AlunoRepository().turmaTemProvaAplicada(id)) {
      throw const TurmaComProvaAplicadaException();
    }
    final alunosDaTurma = await alunos
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: id)
        .get();
    final provas = await avaliacoes
        .where('professorId', isEqualTo: professorId)
        .where('turmaId', isEqualTo: id)
        .get();
    // Uma única escrita atômica evita deixar registros órfãos em caso de falha.
    final batch = firestore.batch();
    for (final aluno in alunosDaTurma.docs) {
      batch.delete(aluno.reference);
    }
    for (final prova in provas.docs) {
      batch.delete(prova.reference);
    }
    batch.delete(turmas.doc(id));
    await batch.commit();
  }

  static Turma fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Turma(
      id: doc.id,
      descricao: data['descricao'] as String? ?? '',
      semestre: (data['semestre'] as num?)?.toInt() ?? 1,
      ano: (data['ano'] as num?)?.toInt() ?? DateTime.now().year,
      totalAlunos: (data['totalAlunos'] as num?)?.toInt() ?? 0,
    );
  }
}
