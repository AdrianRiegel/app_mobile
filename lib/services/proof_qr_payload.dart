import 'dart:convert';

/// Defines the versioned payload printed on each student's proof sheet.
class ProofQrPayload {
  const ProofQrPayload({
    required this.classId,
    required this.proofId,
    required this.studentId,
  });

  final String classId;
  final String proofId;
  final String studentId;

  String encode() {
    if (classId.trim().isEmpty ||
        proofId.trim().isEmpty ||
        studentId.trim().isEmpty) {
      throw ArgumentError('IDs da turma, prova e aluno são obrigatórios.');
    }

    return jsonEncode({
      'version': 1,
      'class_id': classId,
      'proof_id': proofId,
      'student_id': studentId,
    });
  }

  /// Lê o conteúdo de um QR Code impresso pelo app. Lança [FormatException]
  /// se não for um QR do EduTurmas.
  factory ProofQrPayload.decode(String text) {
    Object? dados;
    try {
      dados = jsonDecode(text);
    } on FormatException {
      dados = null;
    }
    if (dados is! Map ||
        dados['version'] is! int ||
        (dados['version'] as int) < 1) {
      throw const FormatException('QR Code não é de uma prova do EduTurmas.');
    }
    String campo(String nome) {
      final valor = dados as Map;
      final texto = valor[nome];
      if (texto is! String || texto.trim().isEmpty) {
        throw FormatException('QR Code sem o campo $nome.');
      }
      return texto;
    }

    return ProofQrPayload(
      classId: campo('class_id'),
      proofId: campo('proof_id'),
      studentId: campo('student_id'),
    );
  }
}
