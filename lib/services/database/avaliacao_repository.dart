import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/assessment.dart';
import '../../models/turma.dart';
import 'database.dart';

/// Avaliações (`avaliacoes`) convertidas para o model [Assessment] usado nas
/// telas, com o nome da turma e o total de correções já preenchidos.
///
/// Ciclo de status: `rascunho` ao criar → `agendada` ao salvar o gabarito →
/// `concluida` quando todos os alunos da turma foram corrigidos.
class AvaliacaoRepository extends FirestoreRepository {
  /// Avaliações do professor (opcionalmente de uma turma), mais recentes
  /// primeiro.
  Future<List<Assessment>> listar({String? turmaId}) async {
    var query = avaliacoes.where('professorId', isEqualTo: professorId);
    if (turmaId != null) {
      query = query.where('turmaId', isEqualTo: turmaId);
    }

    final (snapshot, turmasDoProfessor) = await (
      query.get(),
      TurmaRepository().listar(),
    ).wait;
    final turmasPorId = {
      for (final turma in turmasDoProfessor) turma.id: turma,
    };

    final docs = [...snapshot.docs]
      ..sort(
        (a, b) =>
            FirestoreRepository.criadoEm(b)
                .compareTo(FirestoreRepository.criadoEm(a)),
      );
    return Future.wait(
      docs.map((doc) => _montar(doc, turmasPorId[doc.data()['turmaId']])),
    );
  }

  Future<Assessment> buscar(String id) async {
    final doc = await avaliacoes.doc(id).get();
    if (!doc.exists) {
      throw StateError('Avaliação $id não encontrada');
    }
    final turma = await TurmaRepository().buscar(doc.data()!['turmaId']);
    return _montar(doc, turma);
  }

  /// Cria a avaliação como rascunho com a data prevista de aplicação opcional.
  Future<Assessment> criar({
    required Turma turma,
    required String titulo,
    required String disciplina,
    required int totalQuestoes,
    DateTime? dataAplicacao,
    List<String>? respostas,
  }) async {
    final gabarito = List.generate(
      totalQuestoes,
      (index) => QuestaoGabarito(
        questao: index + 1,
        alternativaCorreta: respostas?[index],
      ),
    );
    final ref = await avaliacoes.add({
      'turmaId': turma.id,
      'professorId': professorId,
      'titulo': titulo,
      'disciplina': disciplina,
      'status': _statusParaBanco(AssessmentStatus.draft),
      'dataAplicacao':
          dataAplicacao != null ? Timestamp.fromDate(dataAplicacao) : null,
      'gabarito': gabarito.map(_gabaritoParaBanco).toList(),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return Assessment(
      id: ref.id,
      turmaId: turma.id,
      gabarito: gabarito,
      title: titulo,
      subject: disciplina,
      className: turma.nome,
      dateLabel:
          dataAplicacao != null ? formatarData(dataAplicacao) : 'Sem data',
      dataAplicacao: dataAplicacao,
      status: AssessmentStatus.draft,
      totalQuestions: totalQuestoes,
      correctedStudents: 0,
      totalStudents: turma.totalAlunos,
    );
  }

  /// Atualiza título, disciplina e data de aplicação da prova.
  Future<Assessment> editar({
    required String id,
    required String titulo,
    required String disciplina,
    DateTime? dataAplicacao,
  }) async {
    final dados = <String, dynamic>{
      'titulo': titulo.trim(),
      'disciplina': disciplina.trim(),
    };
    if (dataAplicacao != null) {
      dados['dataAplicacao'] = Timestamp.fromDate(dataAplicacao);
    }
    await avaliacoes.doc(id).update(dados);
    return buscar(id);
  }

  /// Exclui uma avaliação somente se ela NÃO estiver concluída/aplicada.
  /// Lança [StateError] se a avaliação já foi aplicada.
  Future<void> excluir(String id) async {
    final avaliacao = await buscar(id);
    if (avaliacao.status == AssessmentStatus.completed) {
      throw StateError('Não é possível excluir uma avaliação já aplicada');
    }

    final batch = firestore.batch()..delete(avaliacoes.doc(id));
    final snapshotResultados = await resultados
        .where('professorId', isEqualTo: professorId)
        .where('avaliacaoId', isEqualTo: id)
        .get();
    for (final doc in snapshotResultados.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Salva o gabarito e, se a avaliação ainda era rascunho, a marca como
  /// agendada.
  Future<Assessment> salvarGabarito(
    Assessment avaliacao,
    List<String> respostas,
  ) async {
    final gabarito = [
      for (var i = 0; i < respostas.length; i++)
        QuestaoGabarito(
          questao: i + 1,
          alternativaCorreta: respostas[i],
          peso: i < avaliacao.gabarito.length ? avaliacao.gabarito[i].peso : 1,
        ),
    ];
    final status = avaliacao.status == AssessmentStatus.draft
        ? AssessmentStatus.scheduled
        : avaliacao.status;

    await avaliacoes.doc(avaliacao.id).update({
      'gabarito': gabarito.map(_gabaritoParaBanco).toList(),
      'status': _statusParaBanco(status),
    });
    return buscar(avaliacao.id);
  }

  Future<void> atualizarStatus(String id, AssessmentStatus status) {
    return avaliacoes.doc(id).update({'status': _statusParaBanco(status)});
  }

  Future<Assessment> _montar(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Turma? turma,
  ) async {
    final corrigidos = await resultados
        .where('professorId', isEqualTo: professorId)
        .where('avaliacaoId', isEqualTo: doc.id)
        .count()
        .get();
    return fromDoc(doc, turma: turma, corrigidos: corrigidos.count ?? 0);
  }

  static Assessment fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    Turma? turma,
    int corrigidos = 0,
  }) {
    final data = doc.data()!;
    final gabarito = ((data['gabarito'] as List?) ?? const []).map((item) {
      final questao = Map<String, dynamic>.from(item as Map);
      return QuestaoGabarito(
        questao: (questao['questao'] as num).toInt(),
        alternativaCorreta: questao['alternativaCorreta'] as String?,
        peso: (questao['peso'] as num?)?.toDouble() ?? 1.0,
      );
    }).toList();
    final dataAplicacao = data['dataAplicacao'];

    return Assessment(
      id: doc.id,
      turmaId: data['turmaId'] as String? ?? '',
      gabarito: gabarito,
      title: data['titulo'] as String? ?? '',
      subject: data['disciplina'] as String? ?? turma?.disciplina ?? '',
      className: turma?.nome ?? 'Turma removida',
      dateLabel: dataAplicacao is Timestamp
          ? formatarData(dataAplicacao.toDate())
          : 'Sem data',
      dataAplicacao: dataAplicacao is Timestamp ? dataAplicacao.toDate() : null,
      status: _statusDoBanco(data['status'] as String?),
      totalQuestions: gabarito.length,
      correctedStudents: corrigidos,
      totalStudents: turma?.totalAlunos ?? 0,
    );
  }

  /// Formata como `22 ago. 2026`.
  static String formatarData(DateTime data) {
    const meses = [
      'jan.',
      'fev.',
      'mar.',
      'abr.',
      'mai.',
      'jun.',
      'jul.',
      'ago.',
      'set.',
      'out.',
      'nov.',
      'dez.',
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }

  static Map<String, dynamic> _gabaritoParaBanco(QuestaoGabarito questao) => {
    'questao': questao.questao,
    'alternativaCorreta': questao.alternativaCorreta,
    'peso': questao.peso,
  };

  static String _statusParaBanco(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.draft:
        return 'rascunho';
      case AssessmentStatus.scheduled:
        return 'agendada';
      case AssessmentStatus.completed:
        return 'concluida';
    }
  }

  static AssessmentStatus _statusDoBanco(String? status) {
    switch (status) {
      case 'agendada':
        return AssessmentStatus.scheduled;
      case 'concluida':
        return AssessmentStatus.completed;
      default:
        return AssessmentStatus.draft;
    }
  }
}
