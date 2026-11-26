import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app_mobile/services/omr/answer_sheet_layout.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Gera uma "foto" sintética da folha de respostas, desenhada com a mesma
/// geometria do PDF ([AnswerSheetLayout]).
///
/// [marks] traz, para cada questão da folha (índice a partir de 0), as
/// alternativas pintadas (índices). Opcionalmente gira, aplica perspectiva,
/// escurece um lado da folha e a coloca sobre um fundo, como numa foto real.
Uint8List renderAnswerSheet({
  required List<int> optionCounts,
  Map<int, List<int>> marks = const {},
  double scale = 1.6,
  double rotationDegrees = 0,
  double keystone = 0,
  bool unevenLight = false,
  bool background = false,
  bool withMarkers = true,
  bool withQr = true,
  String? qrText,
}) {
  final w = (AnswerSheetLayout.pageWidth * scale).round();
  final h = (AnswerSheetLayout.pageHeight * scale).round();
  final page = img.Image(width: w, height: h);
  img.fill(page, color: img.ColorRgb8(250, 248, 240));
  final preto = img.ColorRgb8(20, 20, 20);
  final cinza = img.ColorRgb8(90, 90, 90);
  final caneta = img.ColorRgb8(30, 45, 150);
  int px(double pt) => (pt * scale).round();

  if (withMarkers) {
    for (final (cx, cy) in AnswerSheetLayout.markerCenters) {
      const meio = AnswerSheetLayout.markerSize / 2;
      img.fillRect(
        page,
        x1: px(cx - meio),
        y1: px(cy - meio),
        x2: px(cx + meio),
        y2: px(cy + meio),
        color: preto,
      );
    }
  }

  // Cabeçalho: linhas de "texto".
  for (var i = 0; i < 7; i++) {
    img.fillRect(
      page,
      x1: px(72),
      y1: px(70 + i * 18),
      x2: px(72 + 120 + (i * 37) % 200),
      y2: px(70 + i * 18 + 6),
      color: cinza,
    );
  }

  if (withQr) {
    // QR de verdade com [qrText]; sem ele, um "QR" de ruído com metade dos
    // módulos pretos (a leitura das bolhas não depende do conteúdo).
    final matriz = qrText == null
        ? null
        : Encoder.encode(qrText, ErrorCorrectionLevel.l).matrix!;
    final aleatorio = math.Random(7);
    final modulos = matriz?.width ?? 25;
    final lado = AnswerSheetLayout.qrSize / modulos;
    for (var i = 0; i < modulos; i++) {
      for (var j = 0; j < modulos; j++) {
        final escuro = matriz == null
            ? aleatorio.nextBool()
            : matriz.get(i, j) == 1;
        if (escuro) {
          img.fillRect(
            page,
            x1: px(AnswerSheetLayout.qrLeft + i * lado),
            y1: px(AnswerSheetLayout.qrTop + j * lado),
            x2: px(AnswerSheetLayout.qrLeft + (i + 1) * lado),
            y2: px(AnswerSheetLayout.qrTop + (j + 1) * lado),
            color: preto,
          );
        }
      }
    }
  }

  for (var q = 0; q < optionCounts.length; q++) {
    final (nx, ny) = AnswerSheetLayout.numberOrigin(q);
    img.fillRect(
      page,
      x1: px(nx),
      y1: px(ny),
      x2: px(nx + 12),
      y2: px(ny + 8),
      color: preto,
    );
    for (var op = 0; op < optionCounts[q]; op++) {
      final (cx, cy) = AnswerSheetLayout.bubbleCenter(q, op);
      for (var t = 0; t < 2; t++) {
        img.drawCircle(
          page,
          x: px(cx),
          y: px(cy),
          radius: px(AnswerSheetLayout.bubbleRadius) - t,
          color: cinza,
        );
      }
      // A letra impressa no meio da bolha.
      img.fillRect(
        page,
        x1: px(cx - 1.5),
        y1: px(cy - 2.5),
        x2: px(cx + 1.5),
        y2: px(cy + 2.5),
        color: cinza,
      );
      if (marks[q]?.contains(op) ?? false) {
        img.fillCircle(
          page,
          x: px(cx),
          y: px(cy),
          radius: px(AnswerSheetLayout.bubbleRadius * 0.9),
          color: caneta,
        );
      }
    }
  }

  final transformar =
      rotationDegrees != 0 || keystone != 0 || unevenLight || background;
  if (!transformar) return img.encodePng(page);

  // "Fotografa" a folha: cada pixel da foto busca o ponto da folha que o
  // originou (rotação + perspectiva), com fundo escuro em volta.
  // Folha deitada precisa de uma foto mais larga que alta.
  final deitada = (rotationDegrees.abs() % 180 - 90).abs() < 30;
  final fw = ((deitada ? h : w) * 1.2).round();
  final fh = ((deitada ? w : h) * 1.12).round();
  final foto = img.Image(width: fw, height: fh);
  final ang = rotationDegrees * math.pi / 180;
  final cosA = math.cos(-ang);
  final sinA = math.sin(-ang);
  for (var y = 0; y < fh; y++) {
    for (var x = 0; x < fw; x++) {
      final dx = x - fw / 2;
      final dy = y - fh / 2;
      // Perspectiva (projetiva, como numa foto): o lado de cima fica mais
      // estreito que o de baixo.
      final p = 1 + keystone * dy / fh;
      final sx = (dx * cosA - dy * sinA) / p;
      final sy = (dx * sinA + dy * cosA) / p;
      final ix = (sx + w / 2).round();
      final iy = (sy + h / 2).round();
      int r, g, b;
      if (ix >= 0 && iy >= 0 && ix < w && iy < h) {
        final p = page.getPixel(ix, iy);
        r = p.r.toInt();
        g = p.g.toInt();
        b = p.b.toInt();
      } else {
        r = 70;
        g = 60;
        b = 55;
      }
      if (unevenLight) {
        final fator = 0.55 + 0.45 * x / fw;
        r = (r * fator).round();
        g = (g * fator).round();
        b = (b * fator).round();
      }
      foto.setPixelRgb(x, y, r, g, b);
    }
  }
  return img.encodeJpg(foto, quality: 88);
}
