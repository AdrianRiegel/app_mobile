import 'package:app_mobile/Screens/assessment_detail_screen.dart';
import 'package:app_mobile/Screens/register_screen.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/email_service.dart';
import 'package:app_mobile/services/email_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

/// Guarda as mensagens em vez de enviar.
class _EmailsFalsos implements EmailSender {
  _EmailsFalsos({this.falhar = false});

  final bool falhar;
  final enviados = <EmailMessage>[];

  @override
  Future<EmailSendResult> send(EmailMessage message) async {
    if (falhar) throw StateError('SMTP fora do ar');
    enviados.add(message);
    return const EmailSendResult.success();
  }
}

void main() {
  late _EmailsFalsos emails;

  setUp(() {
    emails = _EmailsFalsos();
    Emails.configure(emails);
  });
  tearDown(() => Emails.configure(null));

  group('SmtpEmailSender', () {
    test('sem credenciais falha sem tentar conectar', () async {
      final sender = SmtpEmailSender(user: '', appPassword: '');
      expect(sender.configurado, isFalse);
      final resultado = await sender.send(
        const EmailMessage(to: 'a@b.com', subject: 'x', text: 'x'),
      );
      expect(resultado.ok, isFalse);
      expect(resultado.error, contains('GMAIL_USER'));
    });

    test('aceita a senha de app copiada com espaços', () {
      final sender = SmtpEmailSender(
        user: ' professor@gmail.com ',
        appPassword: 'abcd efgh ijkl mnop',
      );
      expect(sender.configurado, isTrue);
    });
  });

  group('Emails', () {
    test('falha no envio não lança erro', () async {
      Emails.configure(_EmailsFalsos(falhar: true));
      final resultado = await Emails.boasVindas(
        nome: 'Maria',
        email: 'maria@escola.com',
      );
      expect(resultado.ok, isFalse);
      expect(resultado.error, contains('SMTP fora do ar'));
    });

    test('boas-vindas usa o primeiro nome e escapa HTML', () {
      final msg = EmailTemplates.boasVindas(
        nome: '<b>Ana</b> Souza',
        email: 'ana@escola.com',
      );
      expect(msg.to, 'ana@escola.com');
      expect(msg.subject, 'Bem-vindo(a) ao EduTurmas');
      expect(msg.text, startsWith('Olá, <b>Ana</b>!'));
      expect(msg.html, contains('Olá, &lt;b&gt;Ana&lt;'));
      expect(msg.html, isNot(contains('<b>Ana</b>')));
    });

    test('aviso de correção respeita a preferência do perfil', () async {
      await configurarBancoFalso();
      final avaliacao = await AvaliacaoRepository().buscar('aval-1');

      final enviado = await Emails.notificarCorrecaoEncerrada(
        avaliacao: avaliacao,
        ausentes: 2,
      );
      expect(enviado?.ok, isTrue);
      final msg = emails.enviados.single;
      expect(msg.to, 'maria@escola.com');
      expect(msg.subject, 'Correção encerrada: Avaliação bimestral — Cap. 4');
      expect(msg.text, contains('Ausentes (nota 0): 2'));
      expect(msg.text, contains('Turma: 3º Ano A'));

      // Com as notificações desligadas, nada é enviado.
      await Database.auth.atualizarPerfil(
        nome: 'Maria Silva',
        notificacoesEmail: false,
      );
      expect(
        await Emails.notificarCorrecaoEncerrada(
          avaliacao: avaliacao,
          ausentes: 2,
        ),
        isNull,
      );
      expect(emails.enviados, hasLength(1));
    });
  });

  group('Telas', () {
    testWidgets('cadastro envia boas-vindas ao novo professor', (tester) async {
      await configurarBancoFalso(logado: false);
      await _abrirCadastro(tester);

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'João Pereira');
      await tester.enterText(campos.at(1), 'joao@escola.com');
      await tester.enterText(campos.at(2), 'senha123');
      await tester.enterText(campos.at(3), 'senha123');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      expect(find.text('Cadastro concluído. Entre com sua nova conta.'),
          findsOneWidget);
      final msg = emails.enviados.single;
      expect(msg.to, 'joao@escola.com');
      expect(msg.text, startsWith('Olá, João!'));
    });

    testWidgets('cadastro conclui mesmo se o e-mail falhar', (tester) async {
      Emails.configure(_EmailsFalsos(falhar: true));
      await configurarBancoFalso(logado: false);
      await _abrirCadastro(tester);

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'João Pereira');
      await tester.enterText(campos.at(1), 'joao@escola.com');
      await tester.enterText(campos.at(2), 'senha123');
      await tester.enterText(campos.at(3), 'senha123');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Cadastro concluído. Entre com sua nova conta.'),
          findsOneWidget);
    });

    testWidgets('encerrar correção envia o resumo ao professor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();
      final avaliacao = await AvaliacaoRepository().buscar('aval-1');
      await tester.pumpWidget(
        MaterialApp(home: AssessmentDetailScreen(assessment: avaliacao)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Encerrar correção'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Encerrar correção'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Correção encerrada com sucesso'),
          findsOneWidget);
      final msg = emails.enviados.single;
      expect(msg.to, 'maria@escola.com');
      // Os 2 alunos da turma não tinham nota: ambos contam como ausentes.
      expect(msg.text, contains('Ausentes (nota 0): 2'));
      expect(msg.text, contains('Provas corrigidas: 0'));
    });
  });
}

/// O cadastro volta para a tela anterior e mostra o aviso nela.
Future<void> _abrirCadastro(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}
