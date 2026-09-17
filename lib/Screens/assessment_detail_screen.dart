import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../models/statistics.dart';
import '../theme/app_colors.dart';
import 'answer_key_screen.dart';
import 'correction_start_screen.dart';
import 'exam_statistics_screen.dart';

class AssessmentDetailScreen extends StatelessWidget {
  const AssessmentDetailScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final progress = assessment.totalStudents == 0
        ? 0.0
        : assessment.correctedStudents / assessment.totalStudents;

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
          'Detalhes da avaliação',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${assessment.subject} · ${assessment.className}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          Icons.quiz_outlined,
                          '${assessment.totalQuestions}',
                          'Questões',
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _metric(
                          Icons.people_outline,
                          '${assessment.totalStudents}',
                          'Alunos',
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _metric(
                          Icons.event_outlined,
                          assessment.dateLabel,
                          'Data',
                          smallValue: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Correções realizadas',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      Text(
                        '${assessment.correctedStudents}/${assessment.totalStudents}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.accentLight,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gabarito',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _openAnswerKey(context),
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(assessment.totalQuestions, (index) {
                  final answer = String.fromCharCode(65 + (index % 5));
                  return Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          answer,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CorrectionStartScreen(
                        assessment: assessment,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Iniciar correção'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAnswerKey(context),
                icon: const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Configurar gabarito'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openStatistics(context),
                icon: const Icon(Icons.bar_chart, size: 18),
                label: const Text('Ver estatísticas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStatistics(BuildContext context) {
    final parts = assessment.title.split(RegExp(r'\s+[—-]\s+'));
    final shortLabel = parts.length > 1 ? parts.last : assessment.title;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamStatisticsScreen(
          statistics: ExamStatistics.demo(
            assessmentTitle: assessment.title,
            shortLabel: shortLabel,
            className: assessment.className,
            subject: assessment.subject,
            totalQuestions: assessment.totalQuestions,
          ),
        ),
      ),
    );
  }

  Widget _metric(
    IconData icon,
    String value,
    String label, {
    bool smallValue = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.text,
            fontSize: smallValue ? 9 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    );
  }

  Widget _statusBadge() {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        assessment.statusLabel,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openAnswerKey(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerKeyScreen(assessment: assessment),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gabarito salvo com sucesso')),
      );
    }
  }
}
