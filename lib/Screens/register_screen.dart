import 'package:flutter/material.dart';
import '../services/mock_auth_service.dart';
import '../components/components.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final Color primaryAccent = const Color(0xFF4F5BD5);
  final Color textColor = const Color(0xFF1B1D22);
  final Color mutedColor = const Color(0xFF6B7078);
  final Color borderColor = const Color(0xFFE2E4E9);
  final Color inputBgColor = const Color(0xFFFAFAFB);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: 'Criar conta'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Campos
              _buildFieldLabel('Nome completo'),
              const SizedBox(height: 6),
              _buildTextField(controller: _nameController, hintText: 'Maria Silva', validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe seu nome' : null),
              const SizedBox(height: 16),

              _buildFieldLabel('E-mail'),
              const SizedBox(height: 6),
              _buildTextField(controller: _emailController, hintText: 'nome@escola.com', keyboardType: TextInputType.emailAddress, validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Informe seu e-mail';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Informe um e-mail válido';
                return null;
              }),
              const SizedBox(height: 16),

              _buildFieldLabel('Senha'),
              const SizedBox(height: 6),
              _buildTextField(controller: _passwordController, hintText: '••••••••', obscureText: true, validator: (value) {
                if ((value?.length ?? 0) < 6) return 'A senha deve ter pelo menos 6 caracteres';
                return null;
              }),
              const SizedBox(height: 16),

              _buildFieldLabel('Confirmar senha'),
              const SizedBox(height: 6),
              _buildTextField(controller: _confirmationController, hintText: '••••••••', obscureText: true, validator: (value) => value != _passwordController.text ? 'As senhas não conferem' : null),
              const SizedBox(height: 24),

              // Botão Cadastrar
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
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
      ),
    );
  }
  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mutedColor),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.6)),
        filled: true,
        fillColor: inputBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryAccent, width: 1.5),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final error = MockAuthService.register(_emailController.text, _passwordController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Cadastro concluído. Entre com sua nova conta.')));
  }
}
