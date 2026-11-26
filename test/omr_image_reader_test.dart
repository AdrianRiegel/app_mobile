import 'dart:typed_data';

import 'package:app_mobile/services/camera_service.dart';
import 'package:app_mobile/services/proof_qr_payload.dart';
import 'package:app_mobile/services/omr/answer_sheet_layout.dart';
import 'package:app_mobile/services/omr/omr_image_reader.dart';
import 'package:app_mobile/services/omr/omr_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/answer_sheet_image.dart';

void main() {
  // 10 questões com 2 a 5 alternativas.
  const opcoes = [5, 5, 4, 4, 3, 2, 5, 5, 4, 5];
  const marcas = {
    0: [1], // B
    1: [0], // A
    2: [3], // D
    3: [2], // C
    4: [0], // A
    5: [1], // B
    6: [4], // E
    // 7 em branco
    8: [1], // B
    9: [3], // D
  };
  const esperado = ['B', 'A', 'D', 'C', 'A', 'B', 'E', null, 'B', 'D'];

  List<String?> ler(Uint8List bytes, {List<int> opcoesFolha = opcoes}) {
    final densidades = OmrImageReader.readDensities(bytes, opcoesFolha);
    return OmrProcessor.processDensityMatrix(densidades).formattedAnswers;
  }

  test('lê uma foto de frente', () {
    final foto = renderAnswerSheet(optionCounts: opcoes, marks: marcas);
    final densidades = OmrImageReader.readDensities(foto, opcoes);
    final resultado = OmrProcessor.processDensityMatrix(densidades);
    expect(resultado.formattedAnswers, esperado);
    expect(resultado.needsManualReview, isFalse);
    // Cada questão tem só as alternativas impressas.
    expect(densidades.map((l) => l.length).toList(), opcoes);
  });

  test('lê foto inclinada, em perspectiva, com sombra e fundo', () {
    final foto = renderAnswerSheet(
      optionCounts: opcoes,
      marks: marcas,
      rotationDegrees: 7,
      keystone: 0.08,
      unevenLight: true,
      background: true,
    );
    expect(ler(foto), esperado);
  });

  test('lê foto de cabeça para baixo e deitada', () {
    for (final giro in [180.0, 90.0, -90.0]) {
      final foto = renderAnswerSheet(
        optionCounts: opcoes,
        marks: marcas,
        rotationDegrees: giro,
        background: true,
      );
      expect(ler(foto), esperado, reason: 'giro de $giro°');
    }
  });

  test('marca dupla vai para a revisão', () {
    final foto = renderAnswerSheet(
      optionCounts: opcoes,
      marks: {...marcas, 0: [1, 3]},
    );
    final resultado = OmrProcessor.processDensityMatrix(
      OmrImageReader.readDensities(foto, opcoes),
    );
    expect(resultado.needsManualReview, isTrue);
    expect(resultado.questions.first.isMultipleMarked, isTrue);
  });

  test('folha cheia com 40 questões', () {
    final opcoes40 = List.filled(AnswerSheetLayout.questionsPerPage, 5);
    final marcas40 = {for (var q = 0; q < 40; q++) q: [q % 5]};
    final foto = renderAnswerSheet(
      optionCounts: opcoes40,
      marks: marcas40,
      rotationDegrees: -4,
      background: true,
    );
    expect(ler(foto, opcoesFolha: opcoes40), [
      for (var q = 0; q < 40; q++) AnswerSheetLayout.letters[q % 5],
    ]);
  });

  test('foto sem os quadrados dos cantos é recusada', () {
    final foto = renderAnswerSheet(
      optionCounts: opcoes,
      marks: marcas,
      withMarkers: false,
    );
    expect(
      () => OmrImageReader.readDensities(foto, opcoes),
      throwsA(
        isA<AnswerSheetReadException>().having(
          (e) => e.message,
          'message',
          contains('quadrados pretos'),
        ),
      ),
    );
  });

  test('imagem inválida ou minúscula é recusada', () {
    expect(
      () => OmrImageReader.readDensities(kValid1x1PngBytes, opcoes),
      throwsA(isA<AnswerSheetReadException>()),
    );
    expect(
      () => OmrImageReader.readDensities(
        Uint8List.fromList([1, 2, 3]),
        opcoes,
      ),
      throwsA(isA<AnswerSheetReadException>()),
    );
  });

  group('QR Code', () {
    const payload = ProofQrPayload(
      classId: 'turma-1',
      proofId: 'aval-1',
      studentId: 'aluno-ana',
    );

    test('lê o QR da folha mesmo inclinada e com sombra', () {
      for (final giro in [0.0, 8.0, 180.0]) {
        final foto = renderAnswerSheet(
          optionCounts: opcoes,
          marks: marcas,
          qrText: payload.encode(),
          rotationDegrees: giro,
          keystone: giro == 8 ? 0.06 : 0,
          unevenLight: giro == 8,
          background: giro != 0,
        );
        final scan = OmrImageReader.scan(foto);
        final lido = ProofQrPayload.decode(scan.qrText!);
        expect(lido.proofId, 'aval-1', reason: 'giro de $giro°');
        expect(lido.studentId, 'aluno-ana');
        expect(lido.classId, 'turma-1');
        expect(
          OmrProcessor.processDensityMatrix(
            scan.densities(opcoes),
          ).formattedAnswers,
          esperado,
        );
      }
    });

    test('QR ilegível vem nulo, sem impedir a leitura das bolhas', () {
      final scan = OmrImageReader.scan(
        renderAnswerSheet(optionCounts: opcoes, marks: marcas),
      );
      expect(scan.qrText, isNull);
      expect(
        OmrProcessor.processDensityMatrix(
          scan.densities(opcoes),
        ).formattedAnswers,
        esperado,
      );
    });

    test('decode recusa QR que não é do EduTurmas', () {
      expect(
        () => ProofQrPayload.decode('https://exemplo.com'),
        throwsFormatException,
      );
      expect(
        () => ProofQrPayload.decode('{"version":1,"class_id":"t"}'),
        throwsFormatException,
      );
    });
  });
}
