class Usuario {
  const Usuario({required this.id, required this.nome, required this.email});

  final String id;
  final String nome;
  final String email;

  String get primeiroNome => nome.trim().split(' ').first;

  String get iniciais => iniciaisDoNome(nome);
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
