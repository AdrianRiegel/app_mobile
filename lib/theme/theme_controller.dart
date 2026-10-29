import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema escolhido pelo usuário (sistema, claro ou escuro), salvo no aparelho.
///
/// O `MaterialApp` escuta [instance] e reconstrói ao trocar o tema.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final instance = ThemeController._();

  static const _chave = 'tema';

  /// Lê a preferência salva. Falhas de leitura mantêm o tema do sistema.
  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(_chave);
      value = ThemeMode.values.firstWhere(
        (modo) => modo.name == salvo,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      value = ThemeMode.system;
    }
  }

  Future<void> alterar(ThemeMode modo) async {
    value = modo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave, modo.name);
    } catch (_) {
      // A troca vale para esta sessão mesmo se não for possível salvar.
    }
  }
}
