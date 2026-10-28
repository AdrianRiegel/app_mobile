import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'Screens/dashboard_screen.dart';
import 'Screens/login_screen.dart';
import 'services/database/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');
  final logado = await Database.auth.restaurarSessao();
  runApp(EduTurmasApp(logado: logado));
}

class EduTurmasApp extends StatelessWidget {
  const EduTurmasApp({super.key, this.logado = false});

  /// Abre direto no painel quando há uma sessão salva no aparelho.
  final bool logado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTurmas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
      ),
      home: logado ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
