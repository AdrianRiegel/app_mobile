import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/assessment.dart';
import '../services/database/database.dart';
import '../theme/app_colors.dart';
import 'assessment_detail_screen.dart';
import 'correction_start_screen.dart';
import 'new_assessment_screen.dart';

enum _AssessmentViewState { loading, content, empty, error }

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  final _repository = AvaliacaoRepository();
  List<Assessment> _assessments = [];
  _AssessmentViewState _viewState = _AssessmentViewState.loading;
  AssessmentStatus? _filter;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _viewState = _AssessmentViewState.loading);
    try {
      final assessments = await _repository.listar();
      if (!mounted) return;
      setState(() {
        _assessments = assessments;
        _viewState = assessments.isEmpty
            ? _AssessmentViewState.empty
            : _AssessmentViewState.content;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _viewState = _AssessmentViewState.error);
    }
  }

  List<Assessment> get _filteredAssessments {
    if (_filter == null) return _assessments;
    return _assessments.where((item) => item.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StandardAppBar(title: 'Avaliações'),
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
      case _AssessmentViewState.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentDetailScreen(assessment: assessment),
          ),
        );
        _carregar();
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

  Widget _errorState() => LoadErrorView(onRetry: _carregar);

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

  Future<void> _startQuickCorrection() async {
    final selected = _assessments
        .where((item) => item.status == AssessmentStatus.scheduled)
        .firstOrNull;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CorrectionStartScreen(assessment: selected),
      ),
    );
    _carregar();
  }
}
