import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/usuario.dart';
import 'database.dart';

/// Erro de autenticação com mensagem pronta para exibir ao usuário.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  /// UID do professor logado, ou `null` sem sessão.
  String? get uid;

  /// Aguarda o Firebase restaurar a sessão salva no aparelho.
  Future<bool> restaurarSessao();

  Future<void> entrar({required String email, required String senha});

  /// Cria a conta no Firebase Auth e o perfil em `usuarios/{uid}`.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  });

  Future<void> redefinirSenha(String email);

  Future<void> sair();

  Future<Usuario?> carregarUsuario();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      Database.firestore.collection('usuarios');

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Future<bool> restaurarSessao() async {
    final user = await _auth.authStateChanges().first;
    return user != null;
  }

  @override
  Future<void> entrar({required String email, required String senha}) {
    return _executar(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      ),
    );
  }

  @override
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) {
    return _executar(() async {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final user = credencial.user!;
      await user.updateDisplayName(nome.trim());
      await _usuarios.doc(user.uid).set({
        'nome': nome.trim(),
        'email': email.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
        'ativo': true,
      });
    });
  }

  @override
  Future<void> redefinirSenha(String email) {
    return _executar(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> sair() => _auth.signOut();

  @override
  Future<Usuario?> carregarUsuario() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    final data = (await _usuarios.doc(user.uid).get()).data();
    return Usuario(
      id: user.uid,
      nome: data?['nome'] as String? ?? user.displayName ?? 'Professor(a)',
      email: data?['email'] as String? ?? user.email ?? '',
    );
  }

  Future<void> _executar(Future<void> Function() acao) async {
    try {
      await acao();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensagem(e.code));
    }
  }

  static String _mensagem(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido';
      case 'user-disabled':
        return 'Esta conta foi desativada';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente';
      case 'network-request-failed':
        return 'Sem conexão com a internet';
      default:
        return 'Não foi possível concluir a operação ($code)';
    }
  }
}
