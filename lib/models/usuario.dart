class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.escola,
    this.notificacoesEmail = true,
  });

  final String id;
  final String nome;
  final String email;
  final String? escola;
  final bool notificacoesEmail;

  String get primeiroNome => nome.trim().split(' ').first;

  String get iniciais => iniciaisDoNome(nome);

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? escola,
    bool? notificacoesEmail,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      escola: escola ?? this.escola,
      notificacoesEmail: notificacoesEmail ?? this.notificacoesEmail,
    );
  }
}

/// `Maria da Silva` → `MS`.
String iniciaisDoNome(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.first.isEmpty) return '?';
  final iniciais = partes.length > 1
      ? '${partes.first[0]}${partes.last[0]}'
      : partes.first[0];
  return iniciais.toUpperCase();
}
