import 'package:app_mobile/Screens/dashboard_screen.dart';
import 'package:app_mobile/Screens/profile_settings_screen.dart';
import 'package:app_mobile/components/components.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_database.dart';

void main() {
  group('AuthRepository.atualizarPerfil', () {
    test('atualiza dados do usuário no repositório', () async {
      await configurarBancoFalso();

      final usuarioAntes = await Database.auth.carregarUsuario();
      expect(usuarioAntes?.nome, 'Maria Silva');
      expect(usuarioAntes?.escola, 'Colégio Estadual');

      await Database.auth.atualizarPerfil(
        nome: 'Maria Silva Santos',
        escola: 'Instituto Federal',
        disciplinaPrincipal: 'Física',
        notificacoesEmail: false,
      );

      final usuarioDepois = await Database.auth.carregarUsuario();
      expect(usuarioDepois?.nome, 'Maria Silva Santos');
      expect(usuarioDepois?.escola, 'Instituto Federal');
      expect(usuarioDepois?.disciplinaPrincipal, 'Física');
      expect(usuarioDepois?.notificacoesEmail, isFalse);
    });

    test('rejeita nome em branco com AuthException', () async {
      await configurarBancoFalso();

      expect(
        () => Database.auth.atualizarPerfil(nome: '   '),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('ProfileSettingsScreen', () {
    testWidgets('carrega dados, permite editar e salvar alterações', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: ProfileSettingsScreen()),
      );
      await tester.pumpAndSettle();

      // Confirma que os campos foram carregados com dados do usuário
      expect(find.text('Maria Silva'), findsWidgets);
      expect(find.text('maria@escola.com'), findsWidgets);
      expect(find.text('Colégio Estadual'), findsOneWidget);
      expect(find.text('Matemática'), findsOneWidget);

      // Edita o nome
      final nomeField = find.widgetWithText(TextField, 'Maria Silva');
      await tester.enterText(nomeField, 'Dra. Maria Silva');

      // Edita a escola
      final escolaField = find.widgetWithText(TextField, 'Colégio Estadual');
      await tester.enterText(escolaField, 'Escola Técnica Central');

      // Toca em Salvar alterações
      final salvarBtn = find.widgetWithText(PrimaryButton, 'Salvar alterações');
      await tester.tap(salvarBtn);
      await tester.pumpAndSettle();

      // Verifica SnackBar de sucesso
      expect(find.text('Perfil atualizado com sucesso!'), findsOneWidget);

      // Verifica se o repositório foi atualizado
      final usuario = await Database.auth.carregarUsuario();
      expect(usuario?.nome, 'Dra. Maria Silva');
      expect(usuario?.escola, 'Escola Técnica Central');
    });

    testWidgets('exibe erro ao tentar salvar com nome vazio', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();

      await tester.pumpWidget(
        const MaterialApp(home: ProfileSettingsScreen()),
      );
      await tester.pumpAndSettle();

      // Limpa o nome
      final nomeField = find.widgetWithText(TextField, 'Maria Silva');
      await tester.enterText(nomeField, '   ');

      // Tenta salvar
      final salvarBtn = find.widgetWithText(PrimaryButton, 'Salvar alterações');
      await tester.tap(salvarBtn);
      await tester.pumpAndSettle();

      // Verifica alerta
      expect(find.text('Por favor, informe seu nome.'), findsOneWidget);
    });
  });

  group('DashboardScreen - Navegação para Perfil', () {
    testWidgets('abre ProfileSettingsScreen pelo item da barra inferior', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();

      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pumpAndSettle();

      // Clica no item Perfil da barra inferior
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      // Confirma que a tela de perfil foi aberta
      expect(find.text('Perfil e Configurações'), findsOneWidget);
      expect(find.text('Dados Pessoais e Profissionais'), findsOneWidget);
    });

    testWidgets('abre ProfileSettingsScreen ao clicar no avatar do professor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await configurarBancoFalso();

      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pumpAndSettle();

      // Clica nas iniciais do avatar 'MS'
      await tester.tap(find.text('MS'));
      await tester.pumpAndSettle();

      expect(find.text('Perfil e Configurações'), findsOneWidget);
    });
  });
}
