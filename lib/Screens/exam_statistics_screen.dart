import 'package:flutter/material.dart';

import '../models/statistics.dart';
import '../theme/app_colors.dart';

/// Tela 5.6 — Estatísticas da prova.
///
/// Mostra o acerto médio, a questão mais errada e o desempenho questão a
/// questão de uma avaliação. Os dados são simulados ([ExamStatistics]).
class ExamStatisticsScreen extends StatelessWidget {
  const ExamStatisticsScreen({super.key, required this.statistics});

  final ExamStatistics statistics;

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
          'Estatísticas',
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
            Text(
              'Estatísticas · ${statistics.shortLabel}',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${statistics.className} · ${statistics.subject}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _summaryCard(
                      label: 'Acerto médio',
                      value: '${statistics.averageScore}%',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      label: 'Questão mais errada',
                      value: statistics.hardestQuestion,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Acertos por questão',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...statistics.questions.map(_questionRow),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionRow(QuestionStat question) {
    final fraction = (question.correctRate / 100).clamp(0.0, 1.0);
    final barColor = question.correctRate < 50
        ? AppColors.danger
        : question.correctRate < 70
        ? AppColors.warning
        : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              'Q${question.number}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 10, color: AppColors.accentLight),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(height: 10, color: barColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(
              '${question.correctRate}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
