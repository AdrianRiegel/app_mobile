import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/turma.dart';
import 'database.dart';

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
