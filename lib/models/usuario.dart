class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.escola,
    this.disciplinaPrincipal,
    this.notificacoesEmail = true,
  });

  final String id;
  final String nome;
  final String email;
  final String? escola;
  final String? disciplinaPrincipal;
  final bool notificacoesEmail;

  String get primeiroNome => nome.trim().split(' ').first;

  String get iniciais => iniciaisDoNome(nome);

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? escola,
    String? disciplinaPrincipal,
    bool? notificacoesEmail,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      escola: escola ?? this.escola,
      disciplinaPrincipal: disciplinaPrincipal ?? this.disciplinaPrincipal,
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
