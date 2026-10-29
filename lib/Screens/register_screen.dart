import 'package:flutter/material.dart';

import '../components/components.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _cadastrando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Preencha nome, e-mail e senha');
      return;
    }
    if (senha != _confirmarSenhaController.text) {
      _mostrarMensagem('As senhas não conferem');
      return;
    }

    setState(() => _cadastrando = true);
    try {
      await Database.auth.cadastrar(nome: nome, email: email, senha: senha);
      // O Firebase já entra na conta nova; o fluxo pede um login explícito.
      await Database.auth.sair();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cadastro concluído. Entre com sua nova conta.'),
        ),
      );
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);
    } finally {
      if (mounted) setState(() => _cadastrando = false);
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
      appBar: const StandardAppBar(title: 'Criar conta'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: 'Nome completo',
                controller: _nomeController,
                hintText: 'Maria Silva',
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'E-mail',
                controller: _emailController,
                hintText: 'nome@escola.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Senha',
                controller: _senhaController,
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Confirmar senha',
                controller: _confirmarSenhaController,
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _cadastrando ? 'Cadastrando...' : 'Cadastrar',
                onPressed: _cadastrando ? null : _cadastrar,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem conta? ',
                    style: TextStyle(fontSize: 13, color: context.colors.muted),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.colors.accent,
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
