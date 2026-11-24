import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

import '../models/assessment.dart';
import 'database/database.dart';
import 'email_templates.dart';

/// E-mail pronto para envio.
class EmailMessage {
  const EmailMessage({
    required this.to,
    required this.subject,
    required this.text,
    this.html,
  });

  final String to;
  final String subject;

  /// Versão em texto puro, exibida por clientes que não mostram HTML.
  final String text;
  final String? html;
}

class EmailSendResult {
  const EmailSendResult.success() : ok = true, error = null;
  const EmailSendResult.failure(this.error) : ok = false;

  final bool ok;
  final String? error;
}

/// Forma de entrega dos e-mails. Nos testes, troque por uma versão falsa com
/// [Emails.configure].
abstract interface class EmailSender {
  Future<EmailSendResult> send(EmailMessage message);
}

/// Envia pelo SMTP do Gmail com uma senha de app (`.env`: `GMAIL_USER` e
/// `GMAIL_APP_PASSWORD`).
///
/// Não funciona no navegador: o SMTP precisa de conexão direta, que a web
/// não permite. Lá o envio falha na hora, sem travar o app.
class SmtpEmailSender implements EmailSender {
  SmtpEmailSender({
    required String user,
    required String appPassword,
    this.fromName = 'EduTurmas',
    this.timeout = const Duration(seconds: 20),
  }) : _user = user.trim(),
       // O Google mostra a senha em blocos ("abcd efgh ..."); os espaços
       // não fazem parte dela.
       _appPassword = appPassword.replaceAll(RegExp(r'\s'), '');

  /// Lê as credenciais do `.env` carregado em `main`.
  factory SmtpEmailSender.fromEnv() {
    final env = dotenv.isInitialized ? dotenv.env : const <String, String>{};
    return SmtpEmailSender(
      user: env['GMAIL_USER'] ?? '',
      appPassword: env['GMAIL_APP_PASSWORD'] ?? '',
    );
  }

  final String _user;
  final String _appPassword;
  final String fromName;
  final Duration timeout;

  bool get configurado => _user.isNotEmpty && _appPassword.isNotEmpty;

  @override
  Future<EmailSendResult> send(EmailMessage message) async {
    if (kIsWeb) {
      return const EmailSendResult.failure(
        'Envio de e-mail indisponível no navegador',
      );
    }
    if (!configurado) {
      return const EmailSendResult.failure(
        'Credenciais SMTP não configuradas (.env: GMAIL_USER / GMAIL_APP_PASSWORD)',
      );
    }

    final email = mailer.Message()
      ..from = mailer.Address(_user, fromName)
      ..recipients.add(message.to)
      ..subject = message.subject
      ..text = message.text
      ..html = message.html;

    try {
      await mailer
          .send(email, gmail(_user, _appPassword))
          .timeout(timeout);
      return const EmailSendResult.success();
    } on mailer.MailerException catch (e) {
      final problems = e.problems.map((p) => '${p.code}: ${p.msg}').join('; ');
      return EmailSendResult.failure(problems.isEmpty ? e.message : problems);
    } on TimeoutException {
      return const EmailSendResult.failure('Tempo esgotado ao enviar e-mail');
    } catch (e) {
      return EmailSendResult.failure(e.toString());
    }
  }
}

/// Ponto único para os e-mails do app.
///
/// Os envios nunca lançam erro nem devem bloquear a tela: chame sem `await`
/// (com `unawaited`) depois que a ação principal deu certo. Falhas ficam só
/// no log.
abstract final class Emails {
  static EmailSender? _sender;

  static EmailSender get sender => _sender ??= SmtpEmailSender.fromEnv();

  @visibleForTesting
  static void configure(EmailSender? sender) => _sender = sender;

  static Future<EmailSendResult> enviar(EmailMessage message) async {
    EmailSendResult resultado;
    try {
      resultado = await sender.send(message);
    } catch (e) {
      resultado = EmailSendResult.failure(e.toString());
    }
    if (!resultado.ok) {
      debugPrint('E-mail "${message.subject}" não enviado: ${resultado.error}');
    }
    return resultado;
  }

  /// Boas-vindas ao professor que acabou de criar a conta.
  static Future<EmailSendResult> boasVindas({
    required String nome,
    required String email,
  }) {
    return enviar(EmailTemplates.boasVindas(nome: nome, email: email));
  }

  /// Envia o resumo do encerramento ao professor logado, se ele mantém
  /// ligadas as "Notificações por e-mail" do perfil. Retorna `null` quando
  /// não há o que enviar.
  static Future<EmailSendResult?> notificarCorrecaoEncerrada({
    required Assessment avaliacao,
    required int ausentes,
  }) async {
    try {
      final professor = await Database.auth.carregarUsuario();
      if (professor == null ||
          !professor.notificacoesEmail ||
          professor.email.isEmpty) {
        return null;
      }
      return await correcaoEncerrada(
        nome: professor.nome,
        email: professor.email,
        avaliacao: avaliacao,
        ausentes: ausentes,
      );
    } catch (e) {
      debugPrint('Aviso de correção encerrada não enviado: $e');
      return null;
    }
  }

  /// Resumo para o professor quando a correção de uma avaliação é encerrada.
  static Future<EmailSendResult> correcaoEncerrada({
    required String nome,
    required String email,
    required Assessment avaliacao,
    required int ausentes,
  }) {
    return enviar(
      EmailTemplates.correcaoEncerrada(
        nome: nome,
        email: email,
        avaliacao: avaliacao,
        ausentes: ausentes,
      ),
    );
  }
}
