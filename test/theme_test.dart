import 'package:app_mobile/Screens/profile_settings_screen.dart';
import 'package:app_mobile/theme/app_colors.dart';
import 'package:app_mobile/theme/app_theme.dart';
import 'package:app_mobile/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  final controller = ThemeController.instance;

  setUp(() => controller.value = ThemeMode.system);

  group('ThemeController', () {
    test('usa o tema do sistema quando não há preferência salva', () async {
      SharedPreferences.setMockInitialValues({});
      controller.value = ThemeMode.dark;

      await controller.carregar();

      expect(controller.value, ThemeMode.system);
    });

    test('salva a escolha e a recupera ao carregar', () async {
      SharedPreferences.setMockInitialValues({});

      await controller.alterar(ThemeMode.dark);
      controller.value = ThemeMode.system;
      await controller.carregar();

      expect(controller.value, ThemeMode.dark);
    });

    test('ignora valor salvo desconhecido', () async {
      SharedPreferences.setMockInitialValues({'tema': 'roxo'});

      await controller.carregar();

      expect(controller.value, ThemeMode.system);
    });
  });

  group('AppTheme', () {
    test('registra a paleta de cada tema como extensão', () {
      expect(AppTheme.light.extension<AppColors>(), AppColors.light);
      expect(AppTheme.dark.extension<AppColors>(), AppColors.dark);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.dark.background);
    });
  });

  testWidgets('seletor de Aparência no perfil troca o tema do app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await configurarBancoFalso();

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: controller,
        builder: (context, modo, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: modo,
          home: const ProfileSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color fundo() => tester
        .widget<Scaffold>(find.byType(Scaffold).first)
        .backgroundColor!;
    expect(fundo(), AppColors.light.background);

    await tester.scrollUntilVisible(
      find.text('Escuro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(controller.value, ThemeMode.dark);
    expect(fundo(), AppColors.dark.background);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tema'), 'dark');

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(fundo(), AppColors.light.background);
  });
}
