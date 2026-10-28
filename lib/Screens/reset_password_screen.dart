import 'package:flutter/material.dart';

import '../components/components.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _mostrarMensagem('Informe o e-mail cadastrado');
      return;
    }

    setState(() => _enviando = true);
    try {
      await Database.auth.redefinirSenha(email);
      _mostrarMensagem('Link de redefinição enviado para o e-mail informado');
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: 'Redefinir senha'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe seu e-mail cadastrado para receber o link de redefinição.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              LabeledTextField(
                label: 'E-mail',
                controller: _emailController,
                hintText: 'nome@escola.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _enviando ? 'Enviando...' : 'Enviar link',
                onPressed: _enviando ? null : _enviarLink,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Voltar para o login',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
