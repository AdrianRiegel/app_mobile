import 'package:flutter/material.dart';

import '../components/components.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: 'Criar conta'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LabeledTextField(
                label: 'Nome completo',
                hintText: 'Maria Silva',
              ),
              const SizedBox(height: 16),
              const LabeledTextField(
                label: 'E-mail',
                hintText: 'nome@escola.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const LabeledTextField(
                label: 'Senha',
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const LabeledTextField(
                label: 'Confirmar senha',
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Cadastrar',
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cadastro concluído. Entre com sua nova conta.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Já tem conta? ',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
