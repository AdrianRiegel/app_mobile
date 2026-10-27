import 'dart:convert';

import 'package:app_mobile/Screens/class_detail_screen.dart';
import 'package:app_mobile/Screens/classes_screen.dart';
import 'package:app_mobile/Screens/login_screen.dart';
import 'package:app_mobile/services/proof_qr_payload.dart';
import 'package:app_mobile/services/mock_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('turmas paginam e a busca recalcula as páginas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClassesScreen()));

    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('3º Ano A - Matemática'), findsOneWidget);
    await tester.tap(find.text('Próxima ›'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 3'), findsOneWidget);
    expect(find.text('3º Ano A - Matemática'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '1º Ano');
    await tester.pumpAndSettle();
    expect(find.text('Página 1 de 1'), findsOneWidget);
    expect(find.text('1º Ano C - Química'), findsOneWidget);
  });

  testWidgets('alunos são paginados na tela da turma', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(titulo: '3º Ano A - Matemática')),
    );

    expect(find.text('Página 1 de 3'), findsOneWidget);
    expect(find.text('Ana Beatriz'), findsOneWidget);
    expect(find.text('Lucas Mendes'), findsNothing);
    await tester.tap(find.text('Próxima ›'));
    await tester.pumpAndSettle();
    expect(find.text('Página 2 de 3'), findsOneWidget);
    expect(find.text('Lucas Mendes'), findsOneWidget);
    expect(find.text('Ana Beatriz'), findsNothing);
  });

  testWidgets('turma com prova aplicada não pode ser excluída', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClassesScreen()));
    await tester.tap(find.byTooltip('Ações da turma').at(1));
    await tester.pumpAndSettle();

    final blockedOption = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Excluir (há provas aplicadas)'),
    );
    expect(blockedOption.enabled, isFalse);
  });

  testWidgets('turma pode ser editada pela lista', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClassesScreen()));
    await tester.tap(find.byTooltip('Ações da turma').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar turma'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '1º Ano C - Química Aplicada');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(find.text('1º Ano C - Química Aplicada'), findsOneWidget);
  });

  testWidgets('gesto horizontal alterna entre alunos e provas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(titulo: '3º Ano A - Matemática')),
    );

    await tester.fling(find.text('Ana Beatriz'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Provas · 3º Ano A'), findsOneWidget);
  });

  testWidgets('QR individual abre com identificação de turma, prova e aluno', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClassDetailScreen(titulo: '3º Ano A - Matemática')),
    );
    await tester.tap(find.text('Provas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gerar QR Code por aluno'));
    await tester.pumpAndSettle();

    expect(find.text('QR Code individual'), findsOneWidget);
    expect(find.textContaining('Aluno aluno-2026041'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('login de demonstração e cadastro em memória funcionam', () {
    expect(MockAuthService.signIn('professor@eduturmas.com', 'Demo1234'), isTrue);
    expect(MockAuthService.register('n2.teste@eduturmas.com', 'senha123'), isNull);
    expect(MockAuthService.signIn('n2.teste@eduturmas.com', 'senha123'), isTrue);
    expect(MockAuthService.register('N2.Teste@eduturmas.com', 'outrasenha'), isNotNull);
  });

  testWidgets('cadastro cria conta que pode entrar no app', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.text('Cadastre-se'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Pessoa N2');
    await tester.enterText(find.byType(TextFormField).at(1), 'ui.n2@eduturmas.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha123');
    await tester.enterText(find.byType(TextFormField).at(3), 'senha123');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ui.n2@eduturmas.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Maria'), findsOneWidget);
  });

  test('payload do QR identifica turma, prova e aluno', () {
    final payload = ProofQrPayload(
      classId: 'turma-3a',
      proofId: 'prova-42',
      studentId: 'aluno-2026041',
    ).encode();
    final decoded = jsonDecode(payload) as Map<String, dynamic>;

    expect(decoded, {
      'version': 1,
      'class_id': 'turma-3a',
      'proof_id': 'prova-42',
      'student_id': 'aluno-2026041',
    });
  });
}
