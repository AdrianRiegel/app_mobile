import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'Screens/dashboard_screen.dart';
import 'Screens/login_screen.dart';
import 'services/database/database.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');
  final logado = await Database.auth.restaurarSessao();
  await ThemeController.instance.carregar();
  runApp(EduTurmasApp(logado: logado));
}

class EduTurmasApp extends StatelessWidget {
  const EduTurmasApp({super.key, this.logado = false});

  /// Abre direto no painel quando há uma sessão salva no aparelho.
  final bool logado;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, modo, _) => MaterialApp(
        title: 'EduTurmas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: modo,
        home: logado ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }
}
