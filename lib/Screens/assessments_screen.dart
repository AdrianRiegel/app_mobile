import 'package:flutter/material.dart';

import '../components/components.dart';
import '../data/mock_assessments.dart';
import '../models/assessment.dart';
import '../theme/app_colors.dart';
import 'assessment_detail_screen.dart';
import 'correction_start_screen.dart';
import 'new_assessment_screen.dart';

enum _AssessmentViewState { content, empty, error }

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  final List<Assessment> _assessments = [...mockAssessments];
  _AssessmentViewState _viewState = _AssessmentViewState.content;
  AssessmentStatus? _filter;

  List<Assessment> get _filteredAssessments {
    if (_filter == null) return _assessments;
    return _assessments.where((item) => item.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Avaliações',
        actions: [
          PopupMenuButton<_AssessmentViewState>(
            tooltip: 'Demonstrar estados da tela',
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppColors.muted,
            ),
            onSelected: (value) => setState(() => _viewState = value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _AssessmentViewState.content,
                child: Text('Exibir avaliações'),
              ),
              PopupMenuItem(
                value: _AssessmentViewState.empty,
                child: Text('Simular estado vazio'),
              ),
              PopupMenuItem(
                value: _AssessmentViewState.error,
                child: Text('Simular erro'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody()),
      floatingActionButton: _viewState == _AssessmentViewState.content
          ? FloatingActionButton.extended(
              onPressed: _createAssessment,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add, size: 19),
              label: const Text(
                'Nova avaliação',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_viewState) {
      case _AssessmentViewState.empty:
        return _emptyState();
      case _AssessmentViewState.error:
        return _errorState();
      case _AssessmentViewState.content:
        return _content();
    }
  }

  Widget _content() {
    final items = _filteredAssessments;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
      children: [
        AccentActionBanner(
          title: 'Correção rápida',
          subtitle: 'Leia o QR Code e comece em poucos passos',
          onTap: _startQuickCorrection,
          padding: 14,
          titleFontSize: 14,
          iconSize: 28,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Avaliações recentes',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${items.length} ${items.length == 1 ? 'avaliação' : 'avaliações'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Todas', null),
              const SizedBox(width: 7),
              _filterChip('Rascunhos', AssessmentStatus.draft),
              const SizedBox(width: 7),
              _filterChip('Agendadas', AssessmentStatus.scheduled),
              const SizedBox(width: 7),
              _filterChip('Concluídas', AssessmentStatus.completed),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: _smallFilteredEmptyState(),
          )
        else
          ...items.map(
            (assessment) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _assessmentItem(assessment),
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, AssessmentStatus? value) {
    final selected = _filter == value;
    return AppFilterChip(
      label: label,
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _assessmentItem(Assessment assessment) {
    return AppListItemCard(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.description_outlined,
          size: 19,
          color: AppColors.accent,
        ),
      ),
      title: assessment.title,
      titleTrailing: StatusBadge(
        label: assessment.statusLabel,
        background: assessment.status.badgeBackground,
        foreground: assessment.status.badgeForeground,
        fontSize: 8,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${assessment.className} · ${assessment.subject}',
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            '${assessment.totalQuestions} questões · ${assessment.dateLabel}',
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentDetailScreen(assessment: assessment),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return EmptyStateView(
      icon: Icons.assignment_outlined,
      iconBackground: AppColors.accentLight,
      iconColor: AppColors.accent,
      title: 'Nenhuma avaliação criada',
      message: 'Crie a primeira avaliação para configurar o gabarito e iniciar as correções.',
      action: PrimaryButton(
        label: 'Criar avaliação',
        icon: Icons.add,
        fullWidth: false,
        verticalPadding: 13,
        horizontalPadding: 20,
        onPressed: _createAssessment,
      ),
    );
  }

  Widget _errorState() {
    return EmptyStateView(
      icon: Icons.cloud_off_outlined,
      iconBackground: AppColors.dangerLight,
      iconColor: AppColors.danger,
      iconSize: 32,
      title: 'Não foi possível carregar',
      message: 'Verifique sua conexão e tente novamente.',
      action: SecondaryButton(
        label: 'Tentar novamente',
        icon: Icons.refresh,
        fullWidth: false,
        verticalPadding: 13,
        horizontalPadding: 20,
        onPressed: () {
          setState(() => _viewState = _AssessmentViewState.content);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avaliações carregadas')),
          );
        },
      ),
    );
  }

  Widget _smallFilteredEmptyState() {
    return const Column(
      children: [
        Icon(Icons.filter_alt_off_outlined, color: AppColors.muted, size: 30),
        SizedBox(height: 8),
        Text(
          'Nenhuma avaliação neste filtro',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Selecione outra categoria para continuar.',
          style: TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _createAssessment() async {
    final assessment = await Navigator.push<Assessment>(
      context,
      MaterialPageRoute(builder: (_) => const NewAssessmentScreen()),
    );
    if (assessment == null || !mounted) {
      return;
    }

    setState(() {
      _assessments.insert(0, assessment);
      _viewState = _AssessmentViewState.content;
      _filter = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação criada como rascunho')),
    );
  }

  void _startQuickCorrection() {
    final selected = _assessments.firstWhere(
      (item) => item.status == AssessmentStatus.scheduled,
      orElse: () => _assessments.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CorrectionStartScreen(assessment: selected),
      ),
    );
  }
}
