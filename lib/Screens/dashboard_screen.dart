import 'package:app_mobile/Screens/classes_screen.dart';
import 'package:app_mobile/Screens/login_screen.dart';
import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/usuario.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';
import 'assessments_screen.dart';
import 'correction_start_screen.dart';
import 'report_screen.dart';
import 'statistics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Usuario? _usuario;
  int? _totalTurmas;
  int? _totalAvaliacoes;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      final (usuario, turmas, avaliacoes) = await (
        Database.auth.carregarUsuario(),
        TurmaRepository().listar(),
        AvaliacaoRepository().listar(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _totalTurmas = turmas.length;
        _totalAvaliacoes = avaliacoes.length;
      });
    } catch (_) {
      // O painel continua utilizável; os totais ficam como "-".
    }
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    _carregarResumo();
  }

  Future<void> _sair() async {
    await Database.auth.sair();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _usuario?.iniciais ?? '',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _usuario == null
                              ? 'Olá!'
                              : 'Olá, ${_usuario!.primeiroNome}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const Text(
                          'Professor(a)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.muted,
                          size: 22,
                        ),
                        ElevatedButton(
                          onPressed: _sair,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shadowColor: Colors.transparent,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DashboardStatCard(
                            onTap: () => _abrir(const ClassesScreen()),
                            icon: Icons.people_outline,
                            label: 'Turmas',
                            value: _totalTurmas == null
                                ? '-'
                                : '$_totalTurmas ativas',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DashboardStatCard(
                            icon: Icons.insert_chart_outlined,
                            label: 'Relatórios',
                            value: 'Gerar PDF',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardStatCard(
                            icon: Icons.bar_chart,
                            label: 'Estatísticas',
                            value: 'Ver desempenho',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StatisticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DashboardStatCard(
                            icon: Icons.assignment_turned_in_outlined,
                            label: 'Avaliações',
                            value: _totalAvaliacoes == null
                                ? '-'
                                : '$_totalAvaliacoes cadastradas',
                            onTap: () => _abrir(const AssessmentsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AccentActionBanner(
                      title: 'Ler QR Code',
                      subtitle: 'Corrigir prova rápido',
                      onTap: () => _abrir(const CorrectionStartScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            _abrir(const ClassesScreen());
            return;
          }
          if (index == 2) {
            _abrir(const AssessmentsScreen());
            return;
          }
          if (index == 3) {
            _showComingSoon('Perfil');
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponível em uma próxima entrega'),
      ),
    );
  }
}
