import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  final Color primaryAccent = const Color(0xFF4F5BD5);
  final Color textColor = const Color(0xFF1B1D22);
  final Color mutedColor = const Color(0xFF6B7078);
  final Color borderColor = const Color(0xFFE2E4E9);
  final Color inputBgColor = const Color(0xFFFAFAFB);
  final Color backIconBg = const Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: backIconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Redefinir senha',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Informe seu e-mail cadastrado para receber o link de redefinição.',
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
              const SizedBox(height: 24),
              _buildFieldLabel('E-mail'),
              const SizedBox(height: 6),
              _buildTextField(hintText: 'nome@escola.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Enviar link', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Voltar para o login', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primaryAccent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mutedColor));
  }

  Widget _buildTextField({required String hintText, TextInputType? keyboardType}) {
    return TextField(
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.6)),
        filled: true,
        fillColor: inputBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryAccent, width: 1.5)),
      ),
    );
  }
}