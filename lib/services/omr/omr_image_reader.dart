import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import 'answer_sheet_layout.dart';

/// A foto não pôde ser lida como folha de respostas. [message] é exibida
/// ao professor.
class AnswerSheetReadException implements Exception {
  const AnswerSheetReadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Leitura de uma foto da folha: o texto do QR Code (ou `null`, se não deu
/// para decodificá-lo) e o preenchimento bruto de todas as posições de bolha
/// da folha ([AnswerSheetLayout.questionsPerPage] × 5).
class AnswerSheetScan {
  const AnswerSheetScan({required this.qrText, required this.rawFill});

  final String? qrText;
  final List<List<double>> rawFill;

  /// Densidades (0 a 1) das bolhas impressas. [optionCounts] traz o número
  /// de alternativas de cada questão desta folha.
  ///
  /// A letra impressa dentro da bolha já escurece um pouco: o nível de uma
  /// bolha vazia vira o zero da escala.
  List<List<double>> densities(List<int> optionCounts) {
    final brutas = [
      for (var q = 0; q < optionCounts.length; q++)
        rawFill[q].sublist(0, optionCounts[q]),
    ];
    final todas = brutas.expand((l) => l).toList()..sort();
    if (todas.isEmpty) return brutas;
    final vazia = todas[(todas.length * 0.2).floor()];
    final escala = 1 - vazia;
    return [
      for (final linha in brutas)
        [
          for (final valor in linha)
            escala <= 0 ? 0.0 : ((valor - vazia) / escala).clamp(0.0, 1.0),
        ],
    ];
  }
}

/// Lê as marcações de uma foto da folha de respostas impressa pelo app
/// ([AnswerSheetLayout]), em Dart puro.
///
/// 1. Converte para tons de cinza e separa o que é escuro com um limiar
///    local, que tolera sombra e luz desigual.
/// 2. Acha os quatro quadrados pretos dos cantos e calcula a homografia
///    entre a folha e a foto, o que corrige perspectiva e inclinação.
/// 3. Descobre se a foto está girada pela posição do QR Code.
/// 4. Decodifica o QR Code (prova, turma e aluno) a partir de um recorte já
///    endireitado, na resolução original da foto.
/// 5. Mede a fração escura dentro de cada bolha.
///
/// [AnswerSheetScan.densities] dá a matriz usada pelo `OmrProcessor`.
abstract final class OmrImageReader {
  static const int _maxSide = 1400;
  static const int _minSide = 300;

  static AnswerSheetScan scan(Uint8List bytes) {
    final imagem = _GrayImage.decode(bytes);
    final escuro = imagem.darkMask();
    final cantos = _findMarkers(imagem, escuro);
    final h = _bestOrientation(cantos, imagem, escuro);
    return AnswerSheetScan(
      qrText: _decodeQr(h, imagem),
      rawFill: _sampleBubbles(h, imagem, escuro),
    );
  }

  /// Atalho: densidades das bolhas impressas, ignorando o QR Code.
  static List<List<double>> readDensities(
    Uint8List bytes,
    List<int> optionCounts,
  ) => scan(bytes).densities(optionCounts);

  // ---------------------------------------------------------------- cantos

  static List<(double, double)> _findMarkers(_GrayImage im, Uint8List dark) {
    final w = im.width;
    final h = im.height;
    final menor = math.min(w, h);
    final labels = Int32List(w * h);
    final pilha = Int32List(w * h);
    final candidatos = <_Blob>[];

    for (var inicio = 0; inicio < w * h; inicio++) {
      if (dark[inicio] == 0 || labels[inicio] != 0) continue;
      labels[inicio] = 1;
      var topo = 0;
      pilha[topo++] = inicio;
      var count = 0;
      var minX = w, minY = h, maxX = 0, maxY = 0;
      var somaX = 0.0, somaY = 0.0;
      while (topo > 0) {
        final p = pilha[--topo];
        final x = p % w;
        final y = p ~/ w;
        count++;
        somaX += x;
        somaY += y;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        if (x > 0 && dark[p - 1] != 0 && labels[p - 1] == 0) {
          labels[p - 1] = 1;
          pilha[topo++] = p - 1;
        }
        if (x < w - 1 && dark[p + 1] != 0 && labels[p + 1] == 0) {
          labels[p + 1] = 1;
          pilha[topo++] = p + 1;
        }
        if (y > 0 && dark[p - w] != 0 && labels[p - w] == 0) {
          labels[p - w] = 1;
          pilha[topo++] = p - w;
        }
        if (y < h - 1 && dark[p + w] != 0 && labels[p + w] == 0) {
          labels[p + w] = 1;
          pilha[topo++] = p + w;
        }
      }

      final bw = maxX - minX + 1;
      final bh = maxY - minY + 1;
      final lado = math.max(bw, bh);
      final proporcao = bw / bh;
      final solidez = count / (bw * bh);
      if (lado >= menor * 0.012 &&
          lado <= menor * 0.15 &&
          proporcao >= 0.6 &&
          proporcao <= 1.67 &&
          solidez >= 0.6) {
        candidatos.add(_Blob(somaX / count, somaY / count, count));
      }
    }

    const erro = AnswerSheetReadException(
      'Não encontrei os 4 quadrados pretos dos cantos da folha. '
      'Fotografe a folha inteira, de frente e com boa luz.',
    );
    if (candidatos.length < 4) throw erro;

    // Os marcadores estão entre as maiores manchas sólidas: descarta as
    // bem menores (bolhas preenchidas, letras, sujeira).
    final areas = candidatos.map((c) => c.area).toList()
      ..sort((a, b) => b.compareTo(a));
    final referencia = areas[3];
    final grandes = candidatos.where((c) => c.area >= referencia * 0.4);

    _Blob extremo(double Function(_Blob) valor) =>
        grandes.reduce((a, b) => valor(a) >= valor(b) ? a : b);
    final cantos = [
      extremo((c) => -(c.x + c.y)), // superior esquerdo
      extremo((c) => c.x - c.y), // superior direito
      extremo((c) => c.x + c.y), // inferior direito
      extremo((c) => c.y - c.x), // inferior esquerdo
    ];
    if (cantos.toSet().length < 4) throw erro;
    final tamanhos = cantos.map((c) => c.area).toList()..sort();
    if (tamanhos.last > tamanhos.first * 3.5) throw erro;

    // Os cantos precisam cercar boa parte da foto; senão foram confundidos
    // com bolhas ou outras manchas dentro da folha.
    var area = 0.0;
    for (var i = 0; i < 4; i++) {
      final a = cantos[i];
      final b = cantos[(i + 1) % 4];
      area += a.x * b.y - b.x * a.y;
    }
    if (area.abs() / 2 < w * h * 0.12) throw erro;

    return [for (final c in cantos) (c.x, c.y)];
  }

  // ------------------------------------------------------------ orientação

  /// Testa as 4 rotações possíveis e fica com a que põe o QR Code (a região
  /// mais escura da folha) no lugar certo.
  static _Homography _bestOrientation(
    List<(double, double)> cantos,
    _GrayImage im,
    Uint8List dark,
  ) {
    final modelo = AnswerSheetLayout.markerCenters;
    _Homography? melhor;
    var melhorEscuro = -1.0;
    for (var giro = 0; giro < 4; giro++) {
      final h = _Homography.solve(modelo, [
        for (var i = 0; i < 4; i++) cantos[(i + giro) % 4],
      ]);
      if (h == null) continue;
      final escuro = _darkRatioInBox(
        h,
        im,
        dark,
        AnswerSheetLayout.qrLeft + 10,
        AnswerSheetLayout.qrTop + 10,
        AnswerSheetLayout.qrSize - 20,
      );
      if (escuro > melhorEscuro) {
        melhorEscuro = escuro;
        melhor = h;
      }
    }
    if (melhor == null || melhorEscuro < 0.15) {
      throw const AnswerSheetReadException(
        'Não reconheci a folha de respostas do EduTurmas. Use a folha '
        'impressa pelo app e fotografe-a inteira, com os 4 quadrados pretos '
        'dos cantos e o QR Code visíveis.',
      );
    }
    return melhor;
  }

  static double _darkRatioInBox(
    _Homography h,
    _GrayImage im,
    Uint8List dark,
    double left,
    double top,
    double size,
  ) {
    const passos = 16;
    var escuros = 0;
    var total = 0;
    for (var i = 0; i < passos; i++) {
      for (var j = 0; j < passos; j++) {
        final (u, v) = h.apply(
          left + size * (i + 0.5) / passos,
          top + size * (j + 0.5) / passos,
        );
        total++;
        if (im.isDark(dark, u, v)) escuros++;
      }
    }
    return escuros / total;
  }

  // ---------------------------------------------------------------- bolhas

  static List<List<double>> _sampleBubbles(
    _Homography h,
    _GrayImage im,
    Uint8List dark,
  ) {
    // Amostra só o miolo da bolha, longe do contorno impresso.
    const raio = AnswerSheetLayout.bubbleRadius * 0.65;
    const passos = 9;
    return [
      for (var q = 0; q < AnswerSheetLayout.questionsPerPage; q++)
        [
          for (var op = 0; op < AnswerSheetLayout.letters.length; op++)
            () {
              final (cx, cy) = AnswerSheetLayout.bubbleCenter(q, op);
              var escuros = 0;
              var total = 0;
              for (var i = 0; i < passos; i++) {
                for (var j = 0; j < passos; j++) {
                  final dx = (i / (passos - 1) * 2 - 1) * raio;
                  final dy = (j / (passos - 1) * 2 - 1) * raio;
                  if (dx * dx + dy * dy > raio * raio) continue;
                  final (u, v) = h.apply(cx + dx, cy + dy);
                  total++;
                  if (im.isDark(dark, u, v)) escuros++;
                }
              }
              return escuros / total;
            }(),
        ],
    ];
  }

  // ------------------------------------------------------------------- QR

  /// Recorta a região do QR já endireitada (com margem branca) a partir da
  /// foto original e decodifica.
  static String? _decodeQr(_Homography h, _GrayImage im) {
    const margem = 12.0;
    const pxPorPonto = 4;
    const inicioX = AnswerSheetLayout.qrLeft - margem;
    const inicioY = AnswerSheetLayout.qrTop - margem;
    const lado = AnswerSheetLayout.qrSize + 2 * margem;
    final n = (lado * pxPorPonto).round();
    final pixels = Int32List(n * n);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final (u, v) = h.apply(
          inicioX + (x + 0.5) / pxPorPonto,
          inicioY + (y + 0.5) / pxPorPonto,
        );
        final g = im.originalLuminance(u, v);
        pixels[y * n + x] = 0xFF000000 | (g << 16) | (g << 8) | g;
      }
    }
    final fonte = RGBLuminanceSource(n, n, pixels);
    for (final binarizar in [
      (LuminanceSource f) => HybridBinarizer(f),
      (LuminanceSource f) => GlobalHistogramBinarizer(f),
    ]) {
      try {
        return QRCodeReader().decode(BinaryBitmap(binarizar(fonte))).text;
      } catch (_) {
        // Tenta o próximo binarizador.
      }
    }
    return null;
  }
}

class _Blob {
  _Blob(this.x, this.y, this.area);

  final double x;
  final double y;
  final int area;
}

class _GrayImage {
  _GrayImage(this.width, this.height, this.lum, this.original);

  factory _GrayImage.decode(Uint8List bytes) {
    img.Image? imagem;
    try {
      imagem = img.decodeImage(bytes);
    } catch (_) {
      imagem = null;
    }
    if (imagem == null) {
      throw const AnswerSheetReadException(
        'Não foi possível abrir a foto da folha.',
      );
    }
    imagem = img.bakeOrientation(imagem);
    final original = imagem;
    if (math.min(imagem.width, imagem.height) <
        OmrImageReader._minSide) {
      throw const AnswerSheetReadException(
        'A foto tem resolução muito baixa. Fotografe a folha mais de perto.',
      );
    }
    if (math.max(imagem.width, imagem.height) > OmrImageReader._maxSide) {
      imagem = imagem.width >= imagem.height
          ? img.copyResize(imagem, width: OmrImageReader._maxSide)
          : img.copyResize(imagem, height: OmrImageReader._maxSide);
    }

    final w = imagem.width;
    final lum = Uint8List(w * imagem.height);
    for (final p in imagem) {
      final valor =
          0.299 * p.rNormalized + 0.587 * p.gNormalized + 0.114 * p.bNormalized;
      lum[p.y * w + p.x] = (valor * 255).round().clamp(0, 255);
    }
    return _GrayImage(w, imagem.height, lum, original);
  }

  final int width;
  final int height;
  final Uint8List lum;

  /// Foto na resolução original, usada para o QR Code (módulos pequenos).
  final img.Image original;

  /// Luminância (0 a 255) na foto original do ponto (u, v) da imagem
  /// reduzida. Fora da foto, branco.
  int originalLuminance(double u, double v) {
    final escala = original.width / width;
    // Interpolação bilinear: os módulos do QR ficam com bordas mais fiéis.
    final fx = u * escala - 0.5;
    final fy = v * escala - 0.5;
    final x0 = fx.floor();
    final y0 = fy.floor();
    final tx = fx - x0;
    final ty = fy - y0;
    double lum(int x, int y) {
      if (x < 0 || y < 0 || x >= original.width || y >= original.height) {
        return 1;
      }
      final p = original.getPixel(x, y);
      return 0.299 * p.rNormalized +
          0.587 * p.gNormalized +
          0.114 * p.bNormalized;
    }

    final valor =
        lum(x0, y0) * (1 - tx) * (1 - ty) +
        lum(x0 + 1, y0) * tx * (1 - ty) +
        lum(x0, y0 + 1) * (1 - tx) * ty +
        lum(x0 + 1, y0 + 1) * tx * ty;
    return (valor * 255).round().clamp(0, 255);
  }

  /// Pixel escuro = bem mais escuro que a vizinhança (média numa janela de
  /// ~1/6 do menor lado). Funciona com sombra e luz desigual.
  Uint8List darkMask() {
    final w = width;
    final h = height;
    final integral = Float64List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var linha = 0.0;
      for (var x = 0; x < w; x++) {
        linha += lum[y * w + x];
        integral[(y + 1) * (w + 1) + x + 1] = integral[y * (w + 1) + x + 1] + linha;
      }
    }

    final r = math.max(8, math.min(w, h) ~/ 12);
    final mask = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final y0 = math.max(0, y - r);
      final y1 = math.min(h, y + r + 1);
      for (var x = 0; x < w; x++) {
        final x0 = math.max(0, x - r);
        final x1 = math.min(w, x + r + 1);
        final soma = integral[y1 * (w + 1) + x1] -
            integral[y0 * (w + 1) + x1] -
            integral[y1 * (w + 1) + x0] +
            integral[y0 * (w + 1) + x0];
        final media = soma / ((x1 - x0) * (y1 - y0));
        final valor = lum[y * w + x];
        if (valor < media * 0.72 && valor < 200) mask[y * w + x] = 1;
      }
    }
    return mask;
  }

  bool isDark(Uint8List mask, double u, double v) {
    final x = u.round();
    final y = v.round();
    if (x < 0 || y < 0 || x >= width || y >= height) return false;
    return mask[y * width + x] != 0;
  }
}

/// Transformação projetiva da folha (pontos de PDF) para a foto (pixels).
class _Homography {
  _Homography(this.h);

  final List<double> h;

  (double, double) apply(double x, double y) {
    final w = h[6] * x + h[7] * y + 1;
    return (
      (h[0] * x + h[1] * y + h[2]) / w,
      (h[3] * x + h[4] * y + h[5]) / w,
    );
  }

  static _Homography? solve(
    List<(double, double)> origem,
    List<(double, double)> destino,
  ) {
    final a = <List<double>>[];
    for (var i = 0; i < 4; i++) {
      final (x, y) = origem[i];
      final (u, v) = destino[i];
      a.add([x, y, 1, 0, 0, 0, -u * x, -u * y, u]);
      a.add([0, 0, 0, x, y, 1, -v * x, -v * y, v]);
    }
    // Eliminação de Gauss com pivoteamento parcial.
    for (var col = 0; col < 8; col++) {
      var pivo = col;
      for (var lin = col + 1; lin < 8; lin++) {
        if (a[lin][col].abs() > a[pivo][col].abs()) pivo = lin;
      }
      if (a[pivo][col].abs() < 1e-9) return null;
      final troca = a[col];
      a[col] = a[pivo];
      a[pivo] = troca;
      for (var lin = 0; lin < 8; lin++) {
        if (lin == col) continue;
        final fator = a[lin][col] / a[col][col];
        if (fator == 0) continue;
        for (var k = col; k < 9; k++) {
          a[lin][k] -= fator * a[col][k];
        }
      }
    }
    return _Homography([for (var i = 0; i < 8; i++) a[i][8] / a[i][i]]);
  }
}
