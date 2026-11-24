import 'dart:convert';

import '../models/assessment.dart';
import 'email_service.dart';

/// Textos dos e-mails do app, em texto puro e HTML.
abstract final class EmailTemplates {
  static const _escape = HtmlEscape();

  static String _primeiroNome(String nome) {
    final primeiro = nome.trim().split(RegExp(r'\s+')).first;
    return primeiro.isEmpty ? 'professor(a)' : primeiro;
  }

  static EmailMessage boasVindas({required String nome, required String email}) {
    final primeiro = _primeiroNome(nome);
    return EmailMessage(
      to: email,
      subject: 'Bem-vindo(a) ao EduTurmas',
      text:
          'Olá, $primeiro!\n\n'
          'Sua conta no EduTurmas foi criada com o e-mail $email.\n\n'
          'Com ela você pode cadastrar turmas e alunos, montar provas com '
          'gabarito e corrigir as folhas de resposta pelo celular.\n\n'
          'Se não foi você quem criou esta conta, ignore este e-mail.\n\n'
          'Equipe EduTurmas',
      html: _layout(
        titulo: 'Olá, ${_escape.convert(primeiro)}!',
        corpo:
            '<p>Sua conta no <b>EduTurmas</b> foi criada com o e-mail '
            '<b>${_escape.convert(email)}</b>.</p>'
            '<p>Com ela você pode cadastrar turmas e alunos, montar provas '
            'com gabarito e corrigir as folhas de resposta pelo celular.</p>'
            '<p style="color:#6B7078;font-size:13px">Se não foi você quem '
            'criou esta conta, ignore este e-mail.</p>',
      ),
    );
  }

  static EmailMessage correcaoEncerrada({
    required String nome,
    required String email,
    required Assessment avaliacao,
    required int ausentes,
  }) {
    final primeiro = _primeiroNome(nome);
    final corrigidas = avaliacao.correctedStudents - ausentes;
    final linhas = <(String, String)>[
      ('Avaliação', avaliacao.title),
      ('Turma', avaliacao.className),
      ('Alunos', '${avaliacao.totalStudents}'),
      ('Provas corrigidas', '${corrigidas < 0 ? 0 : corrigidas}'),
      ('Ausentes (nota 0)', '$ausentes'),
    ];

    return EmailMessage(
      to: email,
      subject: 'Correção encerrada: ${avaliacao.title}',
      text:
          'Olá, $primeiro!\n\n'
          'A correção da avaliação foi encerrada.\n\n'
          '${linhas.map((l) => '${l.$1}: ${l.$2}').join('\n')}\n\n'
          'As notas e estatísticas já estão disponíveis no app.\n\n'
          'Equipe EduTurmas',
      html: _layout(
        titulo: 'Correção encerrada',
        corpo:
            '<p>Olá, ${_escape.convert(primeiro)}! A correção da avaliação '
            'foi encerrada.</p>'
            '<table style="border-collapse:collapse;font-size:14px">'
            '${linhas.map((l) => '<tr>'
                '<td style="padding:4px 16px 4px 0;color:#6B7078">${_escape.convert(l.$1)}</td>'
                '<td style="padding:4px 0"><b>${_escape.convert(l.$2)}</b></td>'
                '</tr>').join()}'
            '</table>'
            '<p>As notas e estatísticas já estão disponíveis no app.</p>',
      ),
    );
  }

  static String _layout({required String titulo, required String corpo}) {
    return '<div style="font-family:Arial,sans-serif;color:#1B1D22;'
        'max-width:520px;margin:0 auto;padding:24px">'
        '<div style="color:#4F5BD5;font-weight:bold;font-size:18px;'
        'margin-bottom:16px">EduTurmas</div>'
        '<h2 style="font-size:20px;margin:0 0 12px">$titulo</h2>'
        '$corpo'
        '<p style="margin-top:24px">Equipe EduTurmas</p>'
        '</div>';
  }
}
