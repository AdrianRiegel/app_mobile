import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailSendResult {
  const EmailSendResult.success() : ok = true, error = null;
  const EmailSendResult.failure(this.error) : ok = false;

  final bool ok;
  final String? error;
}

class EmailService {
  EmailService({String? gmailUser, String? gmailAppPassword})
      : _gmailUser = gmailUser ?? dotenv.env['GMAIL_USER'] ?? '',
        _gmailAppPassword =
            gmailAppPassword ?? dotenv.env['GMAIL_APP_PASSWORD'] ?? '';

  final String _gmailUser;
  final String _gmailAppPassword;

  Future<EmailSendResult> sendEmail({
    required String to,
    required String subject,
    required String text,
    String? html,
    String fromName = 'EduTurmas',
    List<String> cc = const [],
    List<String> bcc = const [],
  }) async {
    if (_gmailUser.isEmpty || _gmailAppPassword.isEmpty) {
      return const EmailSendResult.failure(
        'Credenciais SMTP não configuradas (.env: GMAIL_USER / GMAIL_APP_PASSWORD)',
      );
    }

    final smtpServer = gmail(_gmailUser, _gmailAppPassword);
    final message = Message()
      ..from = Address(_gmailUser, fromName)
      ..recipients.add(to)
      ..ccRecipients.addAll(cc)
      ..bccRecipients.addAll(bcc)
      ..subject = subject
      ..text = text;

    if (html != null) {
      message.html = html;
    }

    try {
      await send(message, smtpServer);
      return const EmailSendResult.success();
    } on MailerException catch (e) {
      final problems = e.problems.map((p) => '${p.code}: ${p.msg}').join('; ');
      return EmailSendResult.failure(problems);
    } catch (e) {
      return EmailSendResult.failure(e.toString());
    }
  }
}
