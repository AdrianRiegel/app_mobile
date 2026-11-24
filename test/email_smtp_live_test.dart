// Envio real pelo Gmail, com as credenciais do `.env`. Fica desligado na
// bateria normal; para rodar (manda 2 e-mails para o próprio GMAIL_USER):
//
//   EMAIL_LIVE=1 flutter test test/email_smtp_live_test.dart
import 'dart:io';

import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/email_service.dart';
import 'package:app_mobile/services/email_templates.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> _lerEnv() {
  final arquivo = File('.env');
  if (!arquivo.existsSync()) return const {};
  return {
    for (final linha in arquivo.readAsLinesSync())
      if (linha.contains('=') && !linha.trimLeft().startsWith('#'))
        linha.substring(0, linha.indexOf('=')).trim():
            linha.substring(linha.indexOf('=') + 1).trim(),
  };
}

void main() {
  final ligado = Platform.environment['EMAIL_LIVE'] == '1';
  final env = _lerEnv();
  final destino = env['GMAIL_USER'] ?? '';
  final sender = SmtpEmailSender(
    user: destino,
    appPassword: env['GMAIL_APP_PASSWORD'] ?? '',
  );

  final pular = !ligado
      ? 'defina EMAIL_LIVE=1 para enviar e-mails reais'
      : !sender.configurado
      ? 'preencha GMAIL_USER e GMAIL_APP_PASSWORD no .env'
      : false;

  test('envia boas-vindas pelo Gmail', () async {
    final resultado = await sender.send(
      EmailTemplates.boasVindas(nome: 'Teste EduTurmas', email: destino),
    );
    expect(resultado.ok, isTrue, reason: resultado.error);
  }, skip: pular, timeout: const Timeout(Duration(minutes: 1)));

  test('envia resumo de correção encerrada pelo Gmail', () async {
    const avaliacao = Assessment(
      id: 'teste',
      turmaId: 'turma-teste',
      gabarito: [],
      title: 'Avaliação de teste',
      subject: 'Matemática',
      className: '3º Ano A',
      dateLabel: 'Sem data',
      status: AssessmentStatus.completed,
      totalQuestions: 10,
      correctedStudents: 30,
      totalStudents: 30,
    );
    final resultado = await sender.send(
      EmailTemplates.correcaoEncerrada(
        nome: 'Teste EduTurmas',
        email: destino,
        avaliacao: avaliacao,
        ausentes: 3,
      ),
    );
    expect(resultado.ok, isTrue, reason: resultado.error);
  }, skip: pular, timeout: const Timeout(Duration(minutes: 1)));
}
