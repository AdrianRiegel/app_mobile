import 'package:flutter/material.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
          color: AppColors.text,
        ),
        title: const Text(
          'Avaliações',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
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
        Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _startQuickCorrection,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correção rápida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Leia o QR Code e comece em poucos passos',
                          style: TextStyle(
                            color: Color(0xFFE6E6FF),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      selectedColor: AppColors.accentLight,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.muted,
        fontSize: 10,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _assessmentItem(Assessment assessment) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssessmentDetailScreen(assessment: assessment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            assessment.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(assessment),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assessment.className} · ${assessment.subject}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${assessment.totalQuestions} questões · ${assessment.dateLabel}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
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

  Widget _statusBadge(Assessment assessment) {
    Color background;
    Color foreground;
    switch (assessment.status) {
      case AssessmentStatus.completed:
        background = AppColors.successLight;
        foreground = AppColors.success;
        break;
      case AssessmentStatus.scheduled:
        background = AppColors.accentLight;
        foreground = AppColors.accent;
        break;
      case AssessmentStatus.draft:
        background = const Color(0xFFEEF0F3);
        foreground = AppColors.muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        assessment.statusLabel,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w600,
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
                Icons.assignment_outlined,
                color: AppColors.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhuma avaliação criada',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie a primeira avaliação para configurar o gabarito e iniciar as correções.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createAssessment,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar avaliação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
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
                setState(() => _viewState = _AssessmentViewState.content);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avaliações carregadas')),
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
