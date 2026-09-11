import 'package:flutter/material.dart';

import '../data/mock_statistics.dart';
import '../models/statistics.dart';
import '../theme/app_colors.dart';
import 'classes_screen.dart';
import 'exam_statistics_screen.dart';
import 'report_screen.dart';

enum _StatisticsViewState { content, empty, error }

/// Tela 6 — Estatísticas gerais.
///
/// Lista as turmas e, dentro de cada uma, as provas com o acerto médio.
/// Tocar em uma prova abre a [ExamStatisticsScreen] (tela 5.6).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final List<ClassStatistics> _classes = mockClassStatistics;
  _StatisticsViewState _viewState = _StatisticsViewState.content;

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
                  const Expanded(
                    child: Text(
                      'Estatísticas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Gerar relatório',
                    onPressed: _openReport,
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ),
                  PopupMenuButton<_StatisticsViewState>(
                    tooltip: 'Demonstrar estados da tela',
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    onSelected: (value) => setState(() => _viewState = value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _StatisticsViewState.content,
                        child: Text('Exibir estatísticas'),
                      ),
                      PopupMenuItem(
                        value: _StatisticsViewState.empty,
                        child: Text('Simular estado vazio'),
                      ),
                      PopupMenuItem(
                        value: _StatisticsViewState.error,
                        child: Text('Simular erro'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_viewState) {
      case _StatisticsViewState.empty:
        return _emptyState();
      case _StatisticsViewState.error:
        return _errorState();
      case _StatisticsViewState.content:
        return _content();
    }
  }

  Widget _content() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _classes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _classCard(_classes[index], index == 0),
    );
  }

  Widget _classCard(ClassStatistics classStats, bool startsExpanded) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: startsExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.muted,
          collapsedIconColor: AppColors.muted,
          title: Text(
            classStats.displayName,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              classStats.exams.isEmpty
                  ? 'Sem provas corrigidas'
                  : '${classStats.exams.length} ${classStats.exams.length == 1 ? 'prova' : 'provas'} · média ${classStats.averageScore}%',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
          children: [
            for (final exam in classStats.exams)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _examRow(exam),
              ),
          ],
        ),
      ),
    );
  }

  Widget _examRow(ExamStatistics exam) {
    return Material(
      color: AppColors.input,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamStatisticsScreen(statistics: exam),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.assessmentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acerto médio: ${exam.averageScore}%',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.bar_chart,
                color: AppColors.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ainda não há estatísticas',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Corrija ao menos uma prova para acompanhar o desempenho das turmas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Não foi possível carregar',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _viewState = _StatisticsViewState.content);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Estatísticas carregadas')),
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pop(context);
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ClassesScreen()),
                );
              case 2:
                break;
              case 3:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Perfil estará disponível em uma próxima entrega',
                    ),
                  ),
                );
            }
          },
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.muted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Turmas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Estatísticas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
