/// Geometria fixa da folha de respostas, em pontos de PDF numa página A4
/// (595 × 842). O PDF desenha a folha com estas medidas e o leitor da foto
/// usa as mesmas para achar cada bolha.
///
/// Os quatro quadrados pretos dos cantos servem de referência: o leitor os
/// localiza na foto e corrige a perspectiva a partir deles.
abstract final class AnswerSheetLayout {
  static const double pageWidth = 595.28;
  static const double pageHeight = 841.89;

  /// Lado dos quadrados pretos dos cantos e distância deles até a borda.
  static const double markerSize = 28;
  static const double markerInset = 28;

  static const int columns = 2;
  static const int questionsPerColumn = 20;
  static const int questionsPerPage = columns * questionsPerColumn;

  static const double gridTop = 250;
  static const double rowHeight = 24;
  static const List<double> columnLeft = [72, 322];
  static const double numberWidth = 44;
  static const double bubbleRadius = 8.5;
  static const double bubbleSpacing = 30;

  /// Área do QR Code, usada também para descobrir se a foto está girada.
  static const double qrLeft = 430;
  static const double qrTop = 80;
  static const double qrSize = 100;

  static const List<String> letters = ['A', 'B', 'C', 'D', 'E'];

  /// Centros dos marcadores, no sentido horário a partir do canto superior
  /// esquerdo.
  static List<(double, double)> get markerCenters {
    const c = markerInset + markerSize / 2;
    return const [
      (c, c),
      (pageWidth - c, c),
      (pageWidth - c, pageHeight - c),
      (c, pageHeight - c),
    ];
  }

  static int pageCount(int totalQuestions) => totalQuestions <= 0
      ? 1
      : (totalQuestions + questionsPerPage - 1) ~/ questionsPerPage;

  /// Índices (a partir de 0) das questões impressas na folha [page].
  static (int inicio, int fim) questionRange(int page, int totalQuestions) {
    final inicio = page * questionsPerPage;
    final fim = (inicio + questionsPerPage).clamp(0, totalQuestions);
    return (inicio, fim);
  }

  /// Centro da bolha [option] da [indexOnPage]-ésima questão da folha.
  static (double, double) bubbleCenter(int indexOnPage, int option) {
    final coluna = indexOnPage ~/ questionsPerColumn;
    final linha = indexOnPage % questionsPerColumn;
    return (
      columnLeft[coluna] + numberWidth + bubbleRadius + option * bubbleSpacing,
      gridTop + linha * rowHeight + rowHeight / 2,
    );
  }

  /// Canto superior esquerdo do número da questão.
  static (double, double) numberOrigin(int indexOnPage) {
    final coluna = indexOnPage ~/ questionsPerColumn;
    final linha = indexOnPage % questionsPerColumn;
    return (columnLeft[coluna], gridTop + linha * rowHeight + 6);
  }
}
