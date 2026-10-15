import 'package:flutter/material.dart';

import '../components/components.dart';
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
      appBar: const StandardAppBar(title: 'Detalhes da avaliação'),
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
                StatusBadge(
                  label: assessment.statusLabel,
                  background: assessment.status.badgeBackground,
                  foreground: assessment.status.badgeForeground,
                  horizontalPadding: 8,
                  verticalPadding: 5,
                ),
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
            PrimaryButton(
              label: 'Iniciar correção',
              icon: Icons.qr_code_scanner,
              verticalPadding: 14,
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
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Configurar gabarito',
              icon: Icons.edit_note_outlined,
              verticalPadding: 14,
              onPressed: () => _openAnswerKey(context),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Ver estatísticas',
              icon: Icons.bar_chart,
              verticalPadding: 14,
              onPressed: () => _openStatistics(context),
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
