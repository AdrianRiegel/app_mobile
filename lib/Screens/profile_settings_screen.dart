import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/usuario.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import 'login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _escolaController = TextEditingController();
  final _disciplinaController = TextEditingController();

  bool _notificacoesEmail = true;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _escolaController.dispose();
    _disciplinaController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final usuario = await Database.auth.carregarUsuario();
      if (!mounted) return;
      if (usuario != null) {
        _usuario = usuario;
        _nomeController.text = usuario.nome;
        _emailController.text = usuario.email;
        _escolaController.text = usuario.escola ?? '';
        _disciplinaController.text = usuario.disciplinaPrincipal ?? '';
        _notificacoesEmail = usuario.notificacoesEmail;
      }
    } catch (e) {
      if (mounted) _erro = 'Erro ao carregar dados do usuário: $e';
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe seu nome.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await Database.auth.atualizarPerfil(
        nome: nome,
        escola: _escolaController.text.trim(),
        disciplinaPrincipal: _disciplinaController.text.trim(),
        notificacoesEmail: _notificacoesEmail,
      );

      final atualizado = await Database.auth.carregarUsuario();
      if (!mounted) return;

      setState(() {
        _usuario = atualizado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: context.colors.accent,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Erro ao salvar alterações: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _confirmarSair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará informar seu e-mail e senha para acessar novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await Database.auth.sair();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: StandardAppBar(title: 'Perfil e Configurações'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final iniciais = _usuario?.iniciais ?? '?';

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Perfil e Configurações'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            if (_erro != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.danger),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: context.colors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: TextStyle(color: context.colors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Avatar Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: context.colors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      iniciais,
                      style: TextStyle(
                        color: context.colors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _usuario?.nome ?? 'Professor(a)',
                    style: TextStyle(
                      color: context.colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _usuario?.email ?? '',
                    style: TextStyle(
                      color: context.colors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.colors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Professor(a)',
                      style: TextStyle(
                        color: context.colors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Dados Pessoais
            Text(
              'Dados Pessoais e Profissionais',
              style: TextStyle(
                color: context.colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            LabeledTextField(
              label: 'Nome Completo',
              controller: _nomeController,
              hintText: 'Seu nome completo',
            ),
            const SizedBox(height: 14),

            LabeledTextField(
              label: 'E-mail (Login)',
              controller: _emailController,
              enabled: false,
              readOnly: true,
              hintText: 'seu.email@escola.com',
              suffixIcon: Icon(Icons.lock_outline, size: 18, color: context.colors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              'O e-mail é utilizado para autenticação e não pode ser alterado por aqui.',
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),

            LabeledTextField(
              label: 'Instituição de Ensino / Escola',
              controller: _escolaController,
              hintText: 'Ex: Escola Estadual Modelo',
            ),
            const SizedBox(height: 14),

            LabeledTextField(
              label: 'Disciplina Principal',
              controller: _disciplinaController,
              hintText: 'Ex: Matemática, Física, etc.',
            ),

            const SizedBox(height: 28),

            // Seção Preferências
            Text(
              'Preferências e Notificações',
              style: TextStyle(
                color: context.colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Material(
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.border),
              ),
              child: SwitchListTile(
                value: _notificacoesEmail,
                activeThumbColor: context.colors.accent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                title: Text(
                  'Notificações por e-mail',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.text,
                  ),
                ),
                subtitle: Text(
                  'Receba alertas sobre correções e turmas',
                  style: TextStyle(fontSize: 12, color: context.colors.muted),
                ),
                onChanged: (val) {
                  setState(() => _notificacoesEmail = val);
                },
              ),
            ),

            const SizedBox(height: 14),

            // Tema do app
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aparência',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance,
                    builder: (context, modo, _) => SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined, size: 18),
                            label: Text('Sistema'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined, size: 18),
                            label: Text('Claro'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined, size: 18),
                            label: Text('Escuro'),
                          ),
                        ],
                        selected: {modo},
                        onSelectionChanged: (selecao) =>
                            ThemeController.instance.alterar(selecao.first),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Info sobre app
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: context.colors.muted),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EduTurmas Mobile',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.text,
                          ),
                        ),
                        Text(
                          'Versão 1.0.0 · Correção inteligente de provas',
                          style: TextStyle(fontSize: 11, color: context.colors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Botão Salvar
            PrimaryButton(
              label: _salvando ? 'Salvando...' : 'Salvar alterações',
              icon: Icons.save_outlined,
              verticalPadding: 14,
              onPressed: _salvando ? null : _salvar,
            ),

            const SizedBox(height: 12),

            // Botão Sair
            SecondaryButton(
              label: 'Sair da conta',
              icon: Icons.logout,
              foregroundColor: Colors.redAccent,
              borderColor: Colors.redAccent.withValues(alpha: 0.4),
              verticalPadding: 14,
              onPressed: _confirmarSair,
            ),
          ],
        ),
      ),
    );
  }
}
