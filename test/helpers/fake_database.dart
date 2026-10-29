import 'package:app_mobile/models/usuario.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

const professorId = 'prof-1';
const senhaValida = 'senha123';

/// Autenticação em memória: aceita qualquer e-mail com [senhaValida].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.logado = true});

  bool logado;
  Usuario _usuario = const Usuario(
    id: professorId,
    nome: 'Maria Silva',
    email: 'maria@escola.com',
    escola: 'Colégio Estadual',
    disciplinaPrincipal: 'Matemática',
    notificacoesEmail: true,
  );

  @override
  String? get uid => logado ? professorId : null;

  @override
  Future<bool> restaurarSessao() async => logado;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    if (senha != senhaValida) {
      throw const AuthException('E-mail ou senha incorretos');
    }
    logado = true;
  }

  @override
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {}

  @override
  Future<void> redefinirSenha(String email) async {}

  @override
  Future<void> sair() async => logado = false;

  @override
  Future<Usuario?> carregarUsuario() async => logado ? _usuario : null;

  @override
  Future<void> atualizarPerfil({
    required String nome,
    String? escola,
    String? disciplinaPrincipal,
    bool? notificacoesEmail,
  }) async {
    if (!logado) throw const AuthException('Nenhum usuário logado');
    if (nome.trim().isEmpty) {
      throw const AuthException('O nome não pode estar em branco');
    }
    _usuario = _usuario.copyWith(
      nome: nome.trim(),
      escola: escola?.trim(),
      disciplinaPrincipal: disciplinaPrincipal?.trim(),
      notificacoesEmail: notificacoesEmail,
    );
  }
}

/// Liga o [Database] a um Firestore em memória com uma turma de dois alunos
/// e uma avaliação agendada de 4 questões (gabarito A, B, C, D).
Future<FakeFirebaseFirestore> configurarBancoFalso({bool logado = true}) async {
  final firestore = FakeFirebaseFirestore();
  Database.configure(
    firestore: firestore,
    auth: FakeAuthRepository(logado: logado),
  );
  final criadoEm = Timestamp.fromDate(DateTime(2026, 8, 1));

  await firestore.collection('turmas').doc('turma-1').set({
    'professorId': professorId,
    'descricao': '3º Ano A - Matemática',
    'semestre': 1,
    'ano': 2026,
    'totalAlunos': 2,
    'criadoEm': criadoEm,
  });

  for (final (id, nome, matricula) in [
    ('aluno-1', 'Ana Beatriz', '2026041'),
    ('aluno-2', 'Carlos Dias', '2026042'),
  ]) {
    await firestore.collection('alunos').doc(id).set({
      'turmaId': 'turma-1',
      'professorId': professorId,
      'nome': nome,
      'matricula': matricula,
      'criadoEm': criadoEm,
    });
  }

  await firestore.collection('avaliacoes').doc('aval-1').set({
    'turmaId': 'turma-1',
    'professorId': professorId,
    'titulo': 'Avaliação bimestral — Cap. 4',
    'disciplina': 'Matemática',
    'status': 'agendada',
    'dataAplicacao': Timestamp.fromDate(DateTime(2026, 8, 22)),
    'gabarito': [
      for (final (index, letra) in ['A', 'B', 'C', 'D'].indexed)
        {'questao': index + 1, 'alternativaCorreta': letra, 'peso': 1.0},
    ],
    'criadoEm': criadoEm,
  });

  return firestore;
}

/// Grava um resultado da `aval-1` com as questões marcadas em [acertos].
Future<void> adicionarResultado(
  FakeFirebaseFirestore firestore, {
  required String alunoId,
  required List<bool> acertos,
}) {
  final total = acertos.where((acerto) => acerto).length;
  return firestore.collection('resultados').doc('aval-1_$alunoId').set({
    'avaliacaoId': 'aval-1',
    'turmaId': 'turma-1',
    'professorId': professorId,
    'alunoId': alunoId,
    'respostasAluno': [
      for (final (index, acerto) in acertos.indexed)
        {'questao': index + 1, 'alternativaMarcada': 'A', 'correta': acerto},
    ],
    'totalAcertos': total,
    'notaCalculada': 10 * total / acertos.length,
  });
}
