import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const EduTurmasApp());
}

class EduTurmasApp extends StatelessWidget {
  const EduTurmasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTurmas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
      ),
      home: const LoginScreen(),
    );
  }
}