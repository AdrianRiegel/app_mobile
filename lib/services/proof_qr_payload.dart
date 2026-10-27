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
}
