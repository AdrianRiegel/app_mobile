// Verifica os loaders das ações assíncronas rodando o app no navegador, com
// o banco em memória dos testes (não acessa o Firebase real).
//
//   chromedriver --port=4444 &
//   flutter drive -d web-server --browser-name=chrome \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/loaders_test.dart
//
// Os prints de cada loader ficam em build/integration_screenshots/.
import 'package:app_mobile/components/components.dart';
import 'package:app_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/fake_database.dart';
import 'package:app_mobile/services/database/database.dart';

late final IntegrationTestWidgetsFlutterBinding _binding;

/// Autenticação falsa com atraso, para o loader ficar visível no print.
class _AuthLenta extends FakeAuthRepository {
  _AuthLenta() : super(logado: false);

  static const atraso = Duration(milliseconds: 1500);

  @override
  Future<void> entrar({required String email, required String senha}) async {
    await Future<void>.delayed(atraso);
    return super.entrar(email: email, senha: senha);
  }

  @override
  Future<void> atualizarPerfil({
    required String nome,
    String? escola,
    String? disciplinaPrincipal,
    bool? notificacoesEmail,
  }) async {
    await Future<void>.delayed(atraso);
    return super.atualizarPerfil(
      nome: nome,
      escola: escola,
      disciplinaPrincipal: disciplinaPrincipal,
      notificacoesEmail: notificacoesEmail,
    );
  }

  @override
  Future<void> sair() async {
    await Future<void>.delayed(atraso);
    return super.sair();
  }
}

void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loaders das ações assíncronas', (tester) async {
    final firestore = await configurarBancoFalso(logado: false);
    Database.configure(firestore: firestore, auth: _AuthLenta());

    await tester.pumpWidget(const EduTurmasApp());
    await _aguardar(tester, find.text('Entrar'));

    await _passo('Login com senha errada mostra spinner e erro', () async {
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'maria@escola.com');
      await tester.enterText(campos.at(1), 'errada');
      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Entrando...'), findsOneWidget);
      expect(find.byType(ButtonSpinner), findsOneWidget);
      await _print('01_login_carregando');
      await _aguardar(tester, find.text('E-mail ou senha incorretos'));
      expect(find.byType(ButtonSpinner), findsNothing);
      await _aguardar(tester, find.byType(SnackBar), sumir: true);
    });

    await _passo('Login correto', () async {
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'maria@escola.com');
      await tester.enterText(campos.at(1), senhaValida);
      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ButtonSpinner), findsOneWidget);
      await _aguardar(tester, find.textContaining('Olá'));
    });

    await _passo('Criar turma pelo sheet', () async {
      await tester.tap(find.text('Turmas').last);
      await _aguardar(tester, find.text('3º Ano A - Matemática'));
      await tester.tap(find.byIcon(Icons.add).last);
      await _aguardar(tester, find.text('Criar turma'));
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(campos.evaluate().length - 3), 'Turma Loader');
      await tester.tap(find.text('Criar turma'));
      await _aguardar(tester, find.text('Turma Loader'));
      expect(find.byType(LoadingDialog), findsNothing);
      await _print('02_turma_criada');
    });

    await _passo('Adicionar aluno pelo sheet', () async {
      await tester.tap(find.text('3º Ano A - Matemática'));
      await _aguardar(tester, find.text('Ana Beatriz'));
      await tester.tap(find.text('Adicionar'));
      await _aguardar(tester, find.text('Adicionar aluno'));
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(campos.evaluate().length - 2), 'Aluno Loader');
      await tester.enterText(campos.last, '999001');
      await tester.tap(find.text('Adicionar aluno'));
      await _aguardar(tester, find.text('Aluno Loader'));
      expect(find.byType(LoadingDialog), findsNothing);
    });

    await _passo('Excluir aluno pelo diálogo', () async {
      await tester.tap(find.byTooltip('Excluir aluno').first);
      await _aguardar(tester, find.text('Excluir aluno'));
      await tester.tap(find.text('Excluir'));
      await _aguardar(tester, find.textContaining('removido'));
      expect(find.byType(LoadingDialog), findsNothing);
      await _print('03_aluno_excluido');
    });

    await _passo('Salvar perfil mostra spinner no botão', () async {
      await _voltarAoPainel(tester);
      await tester.tap(find.text('Perfil').last);
      await _aguardar(tester, find.text('Maria Silva'));
      await tester.scrollUntilVisible(
        find.text('Sair da conta'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Salvar alterações'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Salvando...'), findsOneWidget);
      expect(find.byType(ButtonSpinner), findsOneWidget);
      await _print('04_perfil_salvando');
      await _aguardar(tester, find.text('Perfil atualizado com sucesso!'));
      expect(find.byType(ButtonSpinner), findsNothing);
    });

    await _passo('Sair mostra loader de tela inteira', () async {
      await tester.tap(find.text('Sair da conta'));
      await _aguardar(tester, find.text('Sair'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sair'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LoadingDialog), findsOneWidget);
      expect(find.text('Saindo...'), findsOneWidget);
      await _print('05_saindo');
      await _aguardar(tester, find.text('Entrar'));
      expect(find.byType(LoadingDialog), findsNothing);
    });
  });
}

Future<void> _print(String nome) => _binding.takeScreenshot('loader_$nome');

Future<void> _passo(String nome, Future<void> Function() acao) async {
  debugPrint('▶ $nome');
  try {
    await acao();
    debugPrint('✔ $nome');
  } catch (e) {
    debugPrint('✘ $nome: $e');
    await _print('falha_${nome.replaceAll(RegExp(r'\W+'), '_')}');
    rethrow;
  }
}

Future<void> _aguardar(
  WidgetTester tester,
  Finder finder, {
  Duration limite = const Duration(seconds: 10),
  bool sumir = false,
}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty != sumir) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  final naTela = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .where((t) => t.trim().isNotEmpty)
      .toSet()
      .join(' | ');
  throw TestFailure(
    '${sumir ? 'Não sumiu' : 'Não apareceu'} em ${limite.inSeconds}s: $finder\nNa tela: $naTela',
  );
}

Future<void> _voltarAoPainel(WidgetTester tester) async {
  for (var i = 0; i < 6 && find.textContaining('Olá').evaluate().isEmpty; i++) {
    final voltar = find.byIcon(Icons.arrow_back);
    if (voltar.evaluate().isEmpty) break;
    await tester.tap(voltar.first);
    await tester.pump(const Duration(milliseconds: 600));
  }
  await _aguardar(tester, find.textContaining('Olá'));
}
