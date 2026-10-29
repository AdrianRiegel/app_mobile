import 'package:flutter/material.dart';

import '../components/components.dart';
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
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Estatísticas'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Text(
              'Estatísticas · ${statistics.shortLabel}',
              style: TextStyle(
                color: context.colors.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${statistics.className} · ${statistics.subject}',
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatSummaryCard(
                      label: 'Acerto médio',
                      value: '${statistics.averageScore}%',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatSummaryCard(
                      label: 'Questão mais errada',
                      value: statistics.hardestQuestion,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Acertos por questão',
              style: TextStyle(
                color: context.colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...statistics.questions.map((q) => _questionRow(context, q)),
          ],
        ),
      ),
    );
  }

  Widget _questionRow(BuildContext context, QuestionStat question) {
    final fraction = (question.correctRate / 100).clamp(0.0, 1.0);
    final barColor = question.correctRate < 50
        ? context.colors.danger
        : question.correctRate < 70
        ? context.colors.warning
        : context.colors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              'Q${question.number}',
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 10, color: context.colors.accentLight),
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
              style: TextStyle(
                color: context.colors.text,
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
