import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color bgColor = const Color(0xFFF0F1F4);
  final Color cardColor = const Color(0xFFFFFFFF);
  final Color borderColor = const Color(0xFFE2E4E9);
  final Color textColor = const Color(0xFF1B1D22);
  final Color mutedColor = const Color(0xFF6B7078);
  final Color accentColor = const Color(0xFF4F5BD5);
  final Color accentLightColor = const Color(0xFFECEEFB);

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
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
                    decoration: BoxDecoration(
                      color: accentLightColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'MS',
                      style: TextStyle(
                        color: accentColor,
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
                          'Olá, Maria',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Professora',
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.notifications_none, color: mutedColor, size: 22),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildDashCard(icon: Icons.people_outline, label: 'Turmas', value: '5 ativas')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDashCard(icon: Icons.insert_chart_outlined, label: 'Relatórios', value: 'Gerar PDF')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildDashCard(icon: Icons.bar_chart, label: 'Estatísticas', value: 'Ver desempenho')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDashCard(icon: Icons.assignment_turned_in_outlined, label: 'Provas', value: '3 pendentes')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ler QR Code', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Corrigir prova rápido', style: TextStyle(color: const Color(0xFFE6E6FF), fontSize: 10)),
                            ],
                          ),
                          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: SafeArea( // Protege contra a barra de baixo do iPhone/Android
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: accentColor,
            unselectedItemColor: mutedColor,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 22,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Turmas'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estatísticas'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 10, color: mutedColor)),
        ],
      ),
    );
  }
}