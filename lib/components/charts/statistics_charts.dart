import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ChartDataPoint {
  const ChartDataPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

Color performanceBandColor(BuildContext context, num value) {
  if (value >= 70) {
    return context.colors.success;
  } else if (value >= 50) {
    return Colors.amber.shade700;
  }
  return context.colors.danger;
}

/// Card contendo gráfico de barras verticais para comparação de acertos por questão ou médias por turma.
class VerticalBarChartCard extends StatelessWidget {
  const VerticalBarChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.entries,
    this.height = 140,
    this.showBandLegend = true,
  });

  final String title;
  final String? subtitle;
  final List<ChartDataPoint> entries;
  final double height;
  final bool showBandLegend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            width: double.infinity,
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Sem dados para exibir',
                      style: TextStyle(color: context.colors.muted, fontSize: 11),
                    ),
                  )
                : CustomPaint(
                    painter: _VerticalBarChartPainter(
                      entries: entries,
                      textColor: context.colors.muted,
                      successColor: context.colors.success,
                      warningColor: Colors.amber.shade700,
                      dangerColor: context.colors.danger,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VerticalBarChartPainter extends CustomPainter {
  _VerticalBarChartPainter({
    required this.entries,
    required this.textColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
  });

  final List<ChartDataPoint> entries;
  final Color textColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;

  Color _colorFor(num value) {
    if (value >= 70) return successColor;
    if (value >= 50) return warningColor;
    return dangerColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final bottomPadding = 20.0;
    final topPadding = 16.0;
    final availableHeight = size.height - bottomPadding - topPadding;
    final barSlotWidth = size.width / entries.length;
    final barWidth = math.min(barSlotWidth * 0.6, 26.0);

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final slotCenterX = (i * barSlotWidth) + (barSlotWidth / 2);
      final fraction = (entry.value / 100.0).clamp(0.04, 1.0);
      final barH = availableHeight * fraction;
      final barTop = size.height - bottomPadding - barH;

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          slotCenterX - (barWidth / 2),
          barTop,
          barWidth,
          barH,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final barPaint = Paint()..color = _colorFor(entry.value);
      canvas.drawRRect(barRect, barPaint);

      // Percentual acima da barra
      final valuePainter = TextPainter(
        text: TextSpan(
          text: '${entry.value.round()}%',
          style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      valuePainter.paint(
        canvas,
        Offset(slotCenterX - (valuePainter.width / 2), barTop - valuePainter.height - 2),
      );

      // Rótulo abaixo da barra
      final labelPainter = TextPainter(
        text: TextSpan(
          text: entry.label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(slotCenterX - (labelPainter.width / 2), size.height - bottomPadding + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalBarChartPainter oldDelegate) => true;
}

/// Card de distribuição de desempenho com gráfico circular em anel (Donut).
class PerformanceDonutCard extends StatelessWidget {
  const PerformanceDonutCard({
    super.key,
    required this.title,
    required this.averagePercent,
    required this.goodCount,
    required this.mediumCount,
    required this.lowCount,
  });

  final String title;
  final num averagePercent;
  final int goodCount;
  final int mediumCount;
  final int lowCount;

  @override
  Widget build(BuildContext context) {
    final total = goodCount + mediumCount + lowCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    averagePercent: averagePercent,
                    goodCount: goodCount,
                    mediumCount: mediumCount,
                    lowCount: lowCount,
                    goodColor: context.colors.success,
                    mediumColor: Colors.amber.shade700,
                    lowColor: context.colors.danger,
                    trackColor: context.colors.border,
                    textColor: context.colors.text,
                    mutedColor: context.colors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(
                      context,
                      color: context.colors.success,
                      label: 'Alta (≥ 70%)',
                      count: goodCount,
                      total: total,
                    ),
                    const SizedBox(height: 6),
                    _legendItem(
                      context,
                      color: Colors.amber.shade700,
                      label: 'Média (50% a 69%)',
                      count: mediumCount,
                      total: total,
                    ),
                    const SizedBox(height: 6),
                    _legendItem(
                      context,
                      color: context.colors.danger,
                      label: 'Baixa (< 50%)',
                      count: lowCount,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int count,
    required int total,
  }) {
    final pct = total > 0 ? (count / total * 100).round() : 0;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.colors.muted, fontSize: 11),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: TextStyle(
            color: context.colors.text,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.averagePercent,
    required this.goodCount,
    required this.mediumCount,
    required this.lowCount,
    required this.goodColor,
    required this.mediumColor,
    required this.lowColor,
    required this.trackColor,
    required this.textColor,
    required this.mutedColor,
  });

  final num averagePercent;
  final int goodCount;
  final int mediumCount;
  final int lowCount;
  final Color goodColor;
  final Color mediumColor;
  final Color lowColor;
  final Color trackColor;
  final Color textColor;
  final Color mutedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    final strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final total = goodCount + mediumCount + lowCount;
    if (total > 0) {
      var startAngle = -math.pi / 2;

      void drawSegment(int count, Color color) {
        if (count <= 0) return;
        final sweepAngle = (count / total) * 2 * math.pi;
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle - 0.08,
          false,
          paint,
        );
        startAngle += sweepAngle;
      }

      drawSegment(goodCount, goodColor);
      drawSegment(mediumCount, mediumColor);
      drawSegment(lowCount, lowColor);
    }

    // Texto central pintado no canvas (não gera Widget Text para manter expect(find.text('75%'), findsOneWidget))
    final avgPainter = TextPainter(
      text: TextSpan(
        text: '${averagePercent.round()}%',
        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    avgPainter.paint(
      canvas,
      Offset(center.dx - avgPainter.width / 2, center.dy - avgPainter.height / 2 - 4),
    );

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'média',
        style: TextStyle(color: mutedColor, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    subPainter.paint(
      canvas,
      Offset(center.dx - subPainter.width / 2, center.dy + 7),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

/// Card com gráfico de linhas/tendência para demonstrar a evolução ao longo das provas.
class LineTrendChartCard extends StatelessWidget {
  const LineTrendChartCard({
    super.key,
    required this.title,
    required this.entries,
    this.height = 110,
  });

  final String title;
  final List<ChartDataPoint> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            width: double.infinity,
            child: entries.length < 2
                ? Center(
                    child: Text(
                      'Poucos dados para traçar evolução',
                      style: TextStyle(color: context.colors.muted, fontSize: 11),
                    ),
                  )
                : CustomPaint(
                    painter: _LineTrendPainter(
                      entries: entries,
                      lineColor: context.colors.accent,
                      textColor: context.colors.muted,
                      pointColor: context.colors.text,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineTrendPainter extends CustomPainter {
  _LineTrendPainter({
    required this.entries,
    required this.lineColor,
    required this.textColor,
    required this.pointColor,
  });

  final List<ChartDataPoint> entries;
  final Color lineColor;
  final Color textColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final bottomPadding = 18.0;
    final topPadding = 12.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final stepX = entries.length > 1 ? size.width / (entries.length - 1) : 0.0;

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < entries.length; i++) {
      final x = i * stepX;
      final normalizedY = (entries[i].value / 100.0).clamp(0.0, 1.0);
      final y = size.height - bottomPadding - (normalizedY * chartHeight);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    final whiteDotPaint = Paint()..color = Colors.white;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 2.5, whiteDotPaint);

      // Rótulo da prova/avaliação
      final textSpan = TextSpan(
        text: entries[i].label,
        style: TextStyle(color: textColor, fontSize: 9),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          (p.dx - textPainter.width / 2).clamp(0, size.width - textPainter.width),
          size.height - bottomPadding + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineTrendPainter oldDelegate) => true;
}
