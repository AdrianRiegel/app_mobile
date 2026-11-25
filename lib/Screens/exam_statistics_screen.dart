import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/statistics.dart';
import '../theme/app_colors.dart';

/// Tela 5.6 — Estatísticas da prova.
///
/// Mostra o acerto médio, a questão mais errada, gráficos de desempenho e
/// distribuição, e a lista questão a questão de uma avaliação.
class ExamStatisticsScreen extends StatelessWidget {
  const ExamStatisticsScreen({super.key, required this.statistics});

  final ExamStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final goodCount =
        statistics.questions.where((q) => q.correctRate >= 70).length;
    final mediumCount = statistics.questions
        .where((q) => q.correctRate >= 50 && q.correctRate < 70)
        .length;
    final lowCount =
        statistics.questions.where((q) => q.correctRate < 50).length;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const StandardAppBar(title: 'Estatísticas'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              if (statistics.questions.isNotEmpty) ...[
                const SizedBox(height: 16),
                VerticalBarChartCard(
                  title: 'Gráfico de acertos por questão',
                  subtitle: 'Percentual de alunos que acertaram cada questão',
                  entries: [
                    for (final q in statistics.questions)
                      ChartDataPoint(
                        label: 'Q${q.number}',
                        value: q.correctRate.toDouble(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                PerformanceDonutCard(
                  title: 'Distribuição das questões',
                  averagePercent: statistics.averageScore,
                  goodCount: goodCount,
                  mediumCount: mediumCount,
                  lowCount: lowCount,
                ),
              ],
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
      ),
    );
  }

  Widget _questionRow(BuildContext context, QuestionStat question) {
    final fraction = (question.correctRate / 100).clamp(0.0, 1.0);
    final barColor = performanceBandColor(context, question.correctRate);

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
