import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/desempenho_turma.dart';
import '../../models/statistics.dart';

/// Gera os relatórios em PDF do app: estatísticas das provas (#27) e
/// desempenho da turma por aluno (#14).
///
/// As funções só montam o arquivo; salvar ou compartilhar fica com a tela.
abstract final class RelatorioPdf {
  static const _accent = PdfColor.fromInt(0xFF4F5BD5);
  static const _accentLight = PdfColor.fromInt(0xFFECEEFB);
  static const _text = PdfColor.fromInt(0xFF1B1D22);
  static const _muted = PdfColor.fromInt(0xFF6B7078);
  static const _border = PdfColor.fromInt(0xFFE2E4E9);
  static const _success = PdfColor.fromInt(0xFF1F9D6E);
  static const _warning = PdfColor.fromInt(0xFFB7791F);
  static const _danger = PdfColor.fromInt(0xFFCC4B4B);

  static pw.ThemeData? _tema;

  /// Tema com a Roboto embutida: as fontes padrão do PDF (Helvetica) não
  /// desenham caracteres como "—", usados nos títulos das provas.
  static Future<pw.ThemeData> _carregarTema() async {
    return _tema ??= pw.ThemeData.withFont(
      base: pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      ),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf')),
    );
  }

  /// Relatório de estatísticas: acerto médio, questão mais errada e acerto
  /// por questão de cada prova. Com [prova], inclui só ela.
  static Future<Uint8List> estatisticas({
    required ClassStatistics turma,
    ExamStatistics? prova,
    DateTime? geradoEm,
  }) async {
    final provas = prova != null ? [prova] : turma.exams;
    final media = provas.isEmpty
        ? 0
        : (provas.fold<int>(0, (soma, p) => soma + p.averageScore) /
                  provas.length)
              .round();

    final doc = pw.Document(
      title: 'Relatório de estatísticas — ${turma.displayName}',
      author: 'EduTurmas',
      theme: await _carregarTema(),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: _rodape,
        build: (context) => [
          _cabecalho('Relatório de estatísticas', geradoEm ?? DateTime.now()),
          _resumo([
            ('Turma', turma.displayName),
            ('Prova', prova?.assessmentTitle ?? 'Todas as provas corrigidas'),
            ('Provas incluídas', '${provas.length}'),
            ('Acerto médio', '$media%'),
          ]),
          if (provas.isEmpty)
            _aviso('Nenhuma prova corrigida para esta turma.')
          else
            for (final item in provas) ..._secaoEstatisticas(item),
        ],
      ),
    );
    return doc.save();
  }

  /// Relatório de desempenho da turma: nota e situação de cada aluno em
  /// cada prova, com média e percentual de aprovação.
  static Future<Uint8List> desempenhoTurma(
    DesempenhoTurma desempenho, {
    String? provaSelecionada,
    DateTime? geradoEm,
  }) async {
    final doc = pw.Document(
      title: 'Relatório de desempenho — ${desempenho.turmaNome}',
      author: 'EduTurmas',
      theme: await _carregarTema(),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: _rodape,
        build: (context) => [
          _cabecalho(
            'Relatório de desempenho da turma',
            geradoEm ?? DateTime.now(),
          ),
          _resumo([
            ('Turma', desempenho.turmaNome),
            ('Prova', provaSelecionada ?? 'Todas as provas corrigidas'),
            ('Alunos', '${desempenho.totalAlunos}'),
            ('Média geral', formatarNota(desempenho.mediaGeral)),
          ]),
          if (desempenho.provas.isEmpty)
            _aviso('Nenhuma prova corrigida para esta turma.')
          else
            for (final prova in desempenho.provas) ..._secaoDesempenho(prova),
        ],
      ),
    );
    return doc.save();
  }

  /// Nota com uma casa decimal e vírgula (ex.: `7,5`).
  static String formatarNota(double nota) =>
      nota.toStringAsFixed(1).replaceAll('.', ',');

  /// Nome do arquivo sugerido ao salvar (ex.: `relatorio_desempenho_3_ano_a.pdf`).
  static String nomeArquivo(String tipo, String turma) {
    const acentos = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e', 'í': 'i', //
      'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c', 'º': '', 'ª': '',
    };
    final base = turma
        .toLowerCase()
        .split('')
        .map((letra) => acentos[letra] ?? letra)
        .join()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'relatorio_${tipo}_$base.pdf';
  }

  static pw.Widget _cabecalho(String titulo, DateTime geradoEm) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EduTurmas',
            style: pw.TextStyle(
              color: _accent,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Gerado em ${_dataPorExtenso(geradoEm)}',
            style: const pw.TextStyle(color: _muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _resumo(List<(String, String)> linhas) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.only(bottom: 18),
      decoration: pw.BoxDecoration(
        color: _accentLight,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          for (final (rotulo, valor) in linhas)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 110,
                    child: pw.Text(
                      rotulo,
                      style: const pw.TextStyle(color: _muted, fontSize: 10),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      valor,
                      style: pw.TextStyle(
                        color: _text,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static List<pw.Widget> _secaoEstatisticas(ExamStatistics prova) {
    return [
      _tituloSecao(prova.assessmentTitle),
      pw.Row(
        children: [
          pw.Expanded(
            child: _destaque('Acerto médio', '${prova.averageScore}%'),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: _destaque('Questão mais errada', prova.hardestQuestion),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      _cabecalhoQuestoes(),
      for (final questao in prova.questions) _linhaQuestao(questao),
      pw.SizedBox(height: 18),
    ];
  }

  static pw.Widget _cabecalhoQuestoes() {
    final estilo = pw.TextStyle(
      color: _text,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      color: _accentLight,
      child: pw.Row(
        children: [
          pw.SizedBox(width: 55, child: pw.Text('Questão', style: estilo)),
          pw.SizedBox(width: 45, child: pw.Text('Acerto', style: estilo)),
          pw.Expanded(child: pw.Text('Desempenho', style: estilo)),
        ],
      ),
    );
  }

  static pw.Widget _linhaQuestao(QuestionStat questao) {
    final cor = questao.correctRate < 50
        ? _danger
        : questao.correctRate < 70
        ? _warning
        : _accent;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text(
              'Q${questao.number}',
              style: const pw.TextStyle(color: _text, fontSize: 9),
            ),
          ),
          pw.SizedBox(
            width: 45,
            child: pw.Text(
              '${questao.correctRate}%',
              style: pw.TextStyle(
                color: _text,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Stack(
              children: [
                pw.Container(
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: _accentLight,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                ),
                if (questao.correctRate > 0)
                  pw.LayoutBuilder(
                    builder: (context, constraints) => pw.Container(
                      height: 7,
                      width:
                          (constraints?.maxWidth ?? 0) *
                          questao.correctRate.clamp(0, 100) /
                          100,
                      decoration: pw.BoxDecoration(
                        color: cor,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _secaoDesempenho(DesempenhoProva prova) {
    return [
      _tituloSecao(prova.avaliacao.title),
      pw.Row(
        children: [
          pw.Expanded(
            child: _destaque(
              'Corrigidos',
              '${prova.corrigidos}/${prova.alunos.length}',
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: _destaque('Média', formatarNota(prova.mediaNotas)),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: _destaque('Aprovação', '${prova.percentualAprovacao}%'),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      if (prova.alunos.isEmpty)
        _aviso('Nenhum aluno matriculado nesta turma.')
      else
        pw.TableHelper.fromTextArray(
          headers: ['Aluno', 'Matrícula', 'Acertos', 'Nota', 'Situação'],
          data: [
            for (final item in prova.alunos)
              [
                item.aluno.nome,
                item.aluno.matricula,
                item.resultado == null
                    ? '-'
                    : '${item.resultado!.totalAcertos}/${prova.avaliacao.totalQuestions}',
                item.resultado == null
                    ? '-'
                    : formatarNota(item.resultado!.notaCalculada),
                item.situacao,
              ],
          ],
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _border, width: 0.5),
            bottom: pw.BorderSide(color: _border, width: 0.5),
          ),
          headerStyle: pw.TextStyle(
            color: _text,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: const pw.BoxDecoration(color: _accentLight),
          cellStyle: const pw.TextStyle(color: _text, fontSize: 9),
          headerAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerLeft,
          },
          cellAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerLeft,
          },
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(1.5),
          },
          cellDecoration: (index, data, row) {
            if (index != 4) return const pw.BoxDecoration();
            final cor = switch (data) {
              'Aprovado' => _success,
              'Reprovado' => _danger,
              _ => _muted,
            };
            return pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: cor, width: 2)),
            );
          },
        ),
      pw.SizedBox(height: 18),
    ];
  }

  static pw.Widget _tituloSecao(String titulo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          color: _text,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _destaque(String rotulo, String valor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            rotulo,
            style: const pw.TextStyle(color: _muted, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            valor,
            style: pw.TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _aviso(String texto) {
    return pw.Text(
      texto,
      style: const pw.TextStyle(color: _muted, fontSize: 10),
    );
  }

  static pw.Widget _rodape(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(color: _muted, fontSize: 8),
      ),
    );
  }

  static String _dataPorExtenso(DateTime data) {
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '${data.day} de ${meses[data.month - 1]} de ${data.year}, '
        'às $hora:$minuto';
  }
}
