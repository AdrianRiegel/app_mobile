import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Item exibido nos gráficos de barras e linha das estatísticas.
class ChartDataPoint {
  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}

/// Retorna a cor semântica de acordo com a faixa de acerto (0–100).
Color performanceBandColor(BuildContext context, num rate) {
  if (rate < 50) return context.colors.danger;
  if (rate < 70) return context.colors.warning;
  return context.colors.accent;
}

/// Gráfico de barras verticais com linhas de grade e rolagem horizontal quando
/// há muitos itens.
class VerticalBarChartCard extends StatelessWidget {
  const VerticalBarChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.entries,
    this.showBandLegend = true,
    this.height = 175,
  });

  final String title;
  final String? subtitle;
  final List<ChartDataPoint> entries;
  final bool showBandLegend;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(color: colors.muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          if (entries.isEmpty)
            SizedBox(
              height: 90,
              child: Center(
                child: Text(
                  'Sem dados para exibir no gráfico.',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minItemWidth = 44.0;
                const yAxisWidth = 34.0;
                final neededWidth =
                    yAxisWidth + entries.length * minItemWidth + 8;
                final chartWidth = math.max(constraints.maxWidth, neededWidth);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: height,
                    child: CustomPaint(
                      painter: _BarChartPainter(
                        entries: entries,
                        colors: colors,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (showBandLegend && entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _LegendDot(color: colors.accent, label: 'Bom (≥ 70%)'),
                _LegendDot(color: colors.warning, label: 'Atenção (50–69%)'),
                _LegendDot(color: colors.danger, label: 'Crítico (< 50%)'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Gráfico de rosca exibindo a proporção de questões por faixa de desempenho.
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
  final int averagePercent;
  final int goodCount;
  final int mediumCount;
  final int lowCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = goodCount + mediumCount + lowCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    goodCount: goodCount,
                    mediumCount: mediumCount,
                    lowCount: lowCount,
                    centerLabel: '$averagePercent%',
                    centerSublabel: 'média',
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BandSummaryRow(
                      color: colors.accent,
                      label: 'Bom (≥ 70%)',
                      count: goodCount,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _BandSummaryRow(
                      color: colors.warning,
                      label: 'Atenção (50–69%)',
                      count: mediumCount,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _BandSummaryRow(
                      color: colors.danger,
                      label: 'Crítico (< 50%)',
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
}

/// Gráfico de linha com área preenchida para mostrar evolução entre provas.
class LineTrendChartCard extends StatelessWidget {
  const LineTrendChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.entries,
    this.height = 148,
  });

  final String title;
  final String? subtitle;
  final List<ChartDataPoint> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(color: colors.muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const minStep = 64.0;
              const yAxisWidth = 34.0;
              final neededWidth = yAxisWidth + entries.length * minStep;
              final chartWidth = math.max(constraints.maxWidth, neededWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: height,
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      entries: entries,
                      colors: colors,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: context.colors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _BandSummaryRow extends StatelessWidget {
  const _BandSummaryRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  final Color color;
  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : ((count / total) * 100).round();
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

void _drawGridAndAxisLabels(
  Canvas canvas,
  Size size, {
  required double leftPad,
  required double topPad,
  required double bottomPad,
  required AppColors colors,
}) {
  final plotHeight = size.height - topPad - bottomPad;
  final gridPaint = Paint()
    ..color = colors.border
    ..strokeWidth = 1;

  for (final pct in [0, 50, 100]) {
    final y = topPad + plotHeight * (1 - pct / 100);
    canvas.drawLine(Offset(leftPad, y), Offset(size.width - 4, y), gridPaint);
    _paintText(
      canvas,
      '$pct%',
      Offset(0, y - 6),
      width: leftPad - 6,
      align: TextAlign.right,
      style: TextStyle(color: colors.muted, fontSize: 9),
    );
  }
}

void _paintText(
  Canvas canvas,
  String text,
  Offset offset, {
  required double width,
  required TextStyle style,
  TextAlign align = TextAlign.center,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
    ellipsis: '…',
  )..layout(minWidth: width, maxWidth: width);
  painter.paint(canvas, offset);
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.entries, required this.colors});

  final List<ChartDataPoint> entries;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const topPad = 20.0;
    const bottomPad = 24.0;
    final plotWidth = size.width - leftPad - 6;
    final plotHeight = size.height - topPad - bottomPad;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    _drawGridAndAxisLabels(
      canvas,
      size,
      leftPad: leftPad,
      topPad: topPad,
      bottomPad: bottomPad,
      colors: colors,
    );

    final slotWidth = plotWidth / entries.length;
    final barWidth = math.min(26.0, slotWidth * 0.54);
    final trackPaint = Paint()..color = colors.accentLight;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final value = entry.value.clamp(0.0, 100.0);
      final centerX = leftPad + slotWidth * (i + 0.5);
      final barLeft = centerX - barWidth / 2;

      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, topPad, barWidth, plotHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);

      final barHeight = plotHeight * (value / 100);
      if (barHeight > 0) {
        final barColor =
            entry.color ??
            (value < 50
                ? colors.danger
                : value < 70
                ? colors.warning
                : colors.accent);
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barLeft,
            topPad + plotHeight - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(6),
        );
        canvas.drawRRect(barRect, Paint()..color = barColor);
      }

      _paintText(
        canvas,
        '${value.round()}%',
        Offset(centerX - slotWidth / 2, topPad + plotHeight - barHeight - 15),
        width: slotWidth,
        style: TextStyle(
          color: colors.text,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );

      _paintText(
        canvas,
        entry.label,
        Offset(centerX - slotWidth / 2, topPad + plotHeight + 6),
        width: slotWidth,
        style: TextStyle(color: colors.muted, fontSize: 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.colors != colors;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.goodCount,
    required this.mediumCount,
    required this.lowCount,
    required this.centerLabel,
    required this.centerSublabel,
    required this.colors,
  });

  final int goodCount;
  final int mediumCount;
  final int lowCount;
  final String centerLabel;
  final String centerSublabel;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = 14.0;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = colors.accentLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final total = goodCount + mediumCount + lowCount;
    if (total > 0) {
      final segments = [
        (goodCount, colors.accent),
        (mediumCount, colors.warning),
        (lowCount, colors.danger),
      ];
      var startAngle = -math.pi / 2;
      for (final (count, color) in segments) {
        if (count <= 0) continue;
        final sweep = (count / total) * math.pi * 2;
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, sweep, false, paint);
        startAngle += sweep;
      }
    }

    _paintText(
      canvas,
      centerLabel,
      Offset(0, center.dy - 14),
      width: size.width,
      style: TextStyle(
        color: colors.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
    _paintText(
      canvas,
      centerSublabel,
      Offset(0, center.dy + 6),
      width: size.width,
      style: TextStyle(color: colors.muted, fontSize: 10),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.goodCount != goodCount ||
      oldDelegate.mediumCount != mediumCount ||
      oldDelegate.lowCount != lowCount ||
      oldDelegate.centerLabel != centerLabel ||
      oldDelegate.colors != colors;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.entries, required this.colors});

  final List<ChartDataPoint> entries;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    const leftPad = 34.0;
    const topPad = 20.0;
    const bottomPad = 24.0;
    final plotWidth = size.width - leftPad - 10;
    final plotHeight = size.height - topPad - bottomPad;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    _drawGridAndAxisLabels(
      canvas,
      size,
      leftPad: leftPad,
      topPad: topPad,
      bottomPad: bottomPad,
      colors: colors,
    );

    final slotWidth = plotWidth / entries.length;
    final points = <Offset>[
      for (var i = 0; i < entries.length; i++)
        Offset(
          leftPad + slotWidth * (i + 0.5),
          topPad + plotHeight * (1 - entries[i].value.clamp(0.0, 100.0) / 100),
        ),
    ];

    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, topPad + plotHeight)
        ..lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath
        ..lineTo(points.last.dx, topPad + plotHeight)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()..color = colors.accent.withValues(alpha: 0.14),
      );

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = colors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < entries.length; i++) {
      final pt = points[i];
      final val = entries[i].value.clamp(0.0, 100.0);
      canvas.drawCircle(pt, 4.5, Paint()..color = colors.surface);
      canvas.drawCircle(
        pt,
        3.5,
        Paint()
          ..color = entries[i].color ??
              (val < 50
                  ? colors.danger
                  : val < 70
                  ? colors.warning
                  : colors.accent),
      );

      _paintText(
        canvas,
        '${val.round()}%',
        Offset(pt.dx - slotWidth / 2, pt.dy - 16),
        width: slotWidth,
        style: TextStyle(
          color: colors.text,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );

      _paintText(
        canvas,
        entries[i].label,
        Offset(pt.dx - slotWidth / 2, topPad + plotHeight + 6),
        width: slotWidth,
        style: TextStyle(color: colors.muted, fontSize: 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.colors != colors;
}
