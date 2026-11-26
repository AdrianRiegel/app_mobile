import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/aluno.dart';
import '../../models/assessment.dart';
import '../omr/answer_sheet_layout.dart';
import '../proof_qr_payload.dart';

/// Exporta o conteúdo definitivo salvo, sem sortear outra versão na impressão.
/// Cada aluno recebe o caderno e, em página separada, a folha de respostas.
abstract final class ProvaPdf {
  static const _accent = PdfColor.fromInt(0xFF4F5BD5);

  static void validar(Assessment prova, List<Aluno> alunos) {
    if (!prova.hasPrintableQuestions ||
        prova.id.isEmpty ||
        prova.turmaId.isEmpty) {
      throw StateError(
        'Esta prova não tem o conteúdo das questões salvo. '
        'Crie uma nova prova com enunciados e alternativas para exportar.',
      );
    }
    if (alunos.isEmpty ||
        alunos.any(
          (aluno) => aluno.id.isEmpty || aluno.turmaId != prova.turmaId,
        )) {
      throw StateError('Selecione alunos cadastrados nesta turma.');
    }
    if (prova.gabarito.length != prova.questions.length) {
      throw StateError('O gabarito não corresponde às questões salvas.');
    }
    for (var i = 0; i < prova.questions.length; i++) {
      final question = prova.questions[i];
      if (question.statement.trim().isEmpty ||
          question.options.length < 2 ||
          question.options.length > 5 ||
          question.options.any((text) => text.trim().isEmpty) ||
          question.correctIndex < 0 ||
          question.correctIndex >= question.options.length ||
          prova.gabarito[i].questao != i + 1 ||
          prova.gabarito[i].alternativaCorreta != question.correctLetter) {
        throw StateError(
          'Confira o conteúdo e o gabarito da questão ${i + 1}.',
        );
      }
    }
  }

  static String nomeArquivo(Assessment prova) => 'prova_${prova.id}.pdf';

  static Future<Uint8List> gerar({
    required Assessment prova,
    required List<Aluno> alunos,
  }) async {
    validar(prova, alunos);
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      ),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf')),
    );
    final doc = pw.Document(
      title: prova.title,
      author: 'EduTurmas',
      theme: theme,
    );
    for (final aluno in alunos) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          maxPages: 200,
          header: (_) => _identificacao(prova, aluno, 'Caderno de questões'),
          footer: _rodape,
          build: (_) => [
            pw.Text(
              'Leia cada questão e marque uma alternativa na folha de respostas.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            for (var i = 0; i < prova.questions.length; i++) ...[
              pw.Text(
                '${i + 1}. ${prova.questions[i].statement}',
                overflow: pw.TextOverflow.span,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 7),
              for (final (index, option)
                  in prova.questions[i].options.indexed) ...[
                pw.Text(
                  '${String.fromCharCode(65 + index)}) $option',
                  overflow: pw.TextOverflow.span,
                  style: const pw.TextStyle(fontSize: 11),
                ),
                if (index < prova.questions[i].options.length - 1)
                  pw.SizedBox(height: 5),
              ],
              if (i < prova.questions.length - 1) pw.SizedBox(height: 14),
            ],
          ],
        ),
      );
      // Folhas de resposta começam sempre numa página própria, com geometria
      // fixa (AnswerSheetLayout) para a leitura pela câmera. O QR se repete
      // em cada folha; não contém nem expõe as alternativas corretas.
      final folhas = AnswerSheetLayout.pageCount(prova.questions.length);
      for (var folha = 0; folha < folhas; folha++) {
        doc.addPage(_folhaDeRespostas(prova, aluno, folha, folhas));
      }
    }
    return doc.save();
  }

  static pw.Page _folhaDeRespostas(
    Assessment prova,
    Aluno aluno,
    int folha,
    int folhas,
  ) {
    final total = prova.questions.length;
    final (inicio, fim) = AnswerSheetLayout.questionRange(folha, total);

    pw.Widget marcador((double, double) centro) => pw.Positioned(
      left: centro.$1 - AnswerSheetLayout.markerSize / 2,
      top: centro.$2 - AnswerSheetLayout.markerSize / 2,
      child: pw.Container(
        width: AnswerSheetLayout.markerSize,
        height: AnswerSheetLayout.markerSize,
        color: PdfColors.black,
      ),
    );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Stack(
        children: [
          for (final centro in AnswerSheetLayout.markerCenters) marcador(centro),
          pw.Positioned(
            left: 72,
            top: 64,
            child: pw.SizedBox(
              width: 340,
              child: _identificacao(prova, aluno, 'Folha de respostas'),
            ),
          ),
          pw.Positioned(
            left: 72,
            top: 182,
            child: pw.SizedBox(
              width: 340,
              child: pw.Text(
                'Pinte a bolha inteira de uma alternativa por questão, com '
                'caneta azul ou preta. Não rasure o QR Code nem os quadrados '
                'pretos dos cantos.\n'
                'Questões ${inicio + 1} a $fim de $total'
                '${folhas > 1 ? ' · Folha ${folha + 1} de $folhas' : ''}.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 3),
              ),
            ),
          ),
          pw.Positioned(
            left: AnswerSheetLayout.qrLeft,
            top: AnswerSheetLayout.qrTop,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: ProofQrPayload(
                classId: prova.turmaId,
                proofId: prova.id,
                studentId: aluno.id,
              ).encode(),
              width: AnswerSheetLayout.qrSize,
              height: AnswerSheetLayout.qrSize,
            ),
          ),
          for (var i = inicio; i < fim; i++) ...[
            pw.Positioned(
              left: AnswerSheetLayout.numberOrigin(i - inicio).$1,
              top: AnswerSheetLayout.numberOrigin(i - inicio).$2,
              child: pw.Text(
                '${i + 1}.',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            for (var j = 0; j < prova.questions[i].options.length; j++)
              pw.Positioned(
                left: AnswerSheetLayout.bubbleCenter(i - inicio, j).$1 - AnswerSheetLayout.bubbleRadius,
                top: AnswerSheetLayout.bubbleCenter(i - inicio, j).$2 - AnswerSheetLayout.bubbleRadius,
                child: pw.Container(
                  width: AnswerSheetLayout.bubbleRadius * 2,
                  height: AnswerSheetLayout.bubbleRadius * 2,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
                  ),
                  child: pw.Text(
                    AnswerSheetLayout.letters[j],
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _identificacao(
    Assessment prova,
    Aluno aluno,
    String secao,
  ) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 18),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'EduTurmas · $secao',
          style: pw.TextStyle(
            color: _accent,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          prova.title,
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Turma: ${prova.className} · ${prova.subject}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Aplicação: ${prova.dateLabel}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Aluno(a): ${aluno.nome} · Matrícula: ${aluno.matricula}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    ),
  );

  static pw.Widget _rodape(pw.Context context) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      'Página ${context.pageNumber}',
      style: const pw.TextStyle(fontSize: 8),
    ),
  );
}
