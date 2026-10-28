import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

export 'aluno_repository.dart';
export 'auth_repository.dart';
export 'avaliacao_repository.dart';
export 'estatisticas_repository.dart';
export 'resultado_repository.dart';
export 'schema_validator.dart';
export 'turma_repository.dart';

/// Ponto único de acesso ao Firebase.
///
/// As telas usam os repositórios, que buscam as instâncias aqui. Nos testes,
/// [configure] troca o Firestore e a autenticação por versões falsas.
abstract final class Database {
  static FirebaseFirestore? _firestore;
  static AuthRepository? _auth;

  static FirebaseFirestore get firestore =>
      _firestore ??= FirebaseFirestore.instance;

  static AuthRepository get auth => _auth ??= FirebaseAuthRepository();

  @visibleForTesting
  static void configure({FirebaseFirestore? firestore, AuthRepository? auth}) {
    _firestore = firestore;
    _auth = auth;
  }
}

/// Base dos repositórios: coleções do Firestore e o professor logado, usado
/// em todas as consultas para respeitar as regras de segurança.
abstract class FirestoreRepository {
  FirebaseFirestore get firestore => Database.firestore;

  String get professorId {
    final uid = Database.auth.uid;
    if (uid == null) {
      throw StateError('Nenhum professor autenticado');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get turmas =>
      firestore.collection('turmas');

  CollectionReference<Map<String, dynamic>> get alunos =>
      firestore.collection('alunos');

  CollectionReference<Map<String, dynamic>> get avaliacoes =>
      firestore.collection('avaliacoes');

  CollectionReference<Map<String, dynamic>> get resultados =>
      firestore.collection('resultados');

  /// Lê `criadoEm`, que fica `null` até o servidor confirmar a escrita.
  static DateTime criadoEm(DocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()?['criadoEm'];
    return value is Timestamp ? value.toDate() : DateTime.now();
  }
}
