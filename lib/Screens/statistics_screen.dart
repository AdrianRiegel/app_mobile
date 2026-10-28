import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/statistics.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';
import 'classes_screen.dart';
import 'exam_statistics_screen.dart';
import 'report_screen.dart';

enum _StatisticsViewState { loading, content, empty, error }

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
  List<ClassStatistics> _classes = [];
  _StatisticsViewState _viewState = _StatisticsViewState.loading;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _viewState = _StatisticsViewState.loading);
    try {
      final classes = await EstatisticasRepository().porTurma();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _viewState = classes.every((turma) => turma.exams.isEmpty)
            ? _StatisticsViewState.empty
            : _StatisticsViewState.content;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _viewState = _StatisticsViewState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Estatísticas',
        actions: [
          IconButton(
            tooltip: 'Gerar relatório',
            onPressed: _openReport,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              size: 20,
              color: AppColors.muted,
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregar,
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.muted),
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody()),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_viewState) {
      case _StatisticsViewState.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
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
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const EmptyStateView(
      icon: Icons.bar_chart,
      iconBackground: AppColors.accentLight,
      iconColor: AppColors.accent,
      title: 'Ainda não há estatísticas',
      message:
          'Corrija ao menos uma prova para acompanhar o desempenho das turmas.',
    );
  }

  Widget _errorState() => LoadErrorView(onRetry: _carregar);

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
  }

  Widget _bottomNav() {
    return AppBottomNavBar(
      currentIndex: 2,
      thirdItemIcon: Icons.bar_chart,
      thirdItemLabel: 'Estatísticas',
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
    );
  }
}
