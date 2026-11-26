import 'dart:typed_data';

import 'package:app_mobile/Screens/correction_start_screen.dart';
import 'package:app_mobile/models/assessment.dart';
import 'package:app_mobile/services/camera_service.dart';
import 'package:app_mobile/services/database/database.dart';
import 'package:app_mobile/services/omr/omr_image_reader.dart';
import 'package:app_mobile/services/proof_qr_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/answer_sheet_image.dart';
import 'helpers/fake_database.dart';

/// Câmera que "fotografa" sempre a imagem em [foto].
class _CameraFalsa implements CameraService {
  _CameraFalsa(this.foto);

  Uint8List foto;

  @override
  bool get isFlashOn => false;
  @override
  CameraLensDirection get lensDirection => CameraLensDirection.back;
  @override
  Future<CameraPermissionStatus> checkPermission() async =>
      CameraPermissionStatus.granted;
  @override
  Future<CameraPermissionStatus> requestPermission() async =>
      CameraPermissionStatus.granted;
  @override
  Future<bool> isCameraAvailable() async => true;
  @override
  Future<CapturedImage?> captureImage() async => CapturedImage(
    path: 'folha.jpg',
    name: 'folha.jpg',
    bytes: foto,
    sizeInBytes: foto.length,
  );
  @override
  Future<CapturedImage?> pickImageFromGallery() => captureImage();
  @override
  Future<bool> toggleFlash() async => false;
  @override
  Future<CameraLensDirection> switchCamera() async => lensDirection;
}

/// Leitura síncrona: o isolate do `compute` não roda no relógio falso dos
/// testes de widget.
Future<(AnswerSheetScan?, String?)> _lerAgora(Uint8List foto) async =>
    CorrectionStartScreen.lerFolhaAgora(foto);

String _qr(String alunoId, {String prova = 'aval-1'}) => ProofQrPayload(
  classId: 'turma-1',
  proofId: prova,
  studentId: alunoId,
).encode();

// A `aval-1` tem 4 questões com gabarito A, B, C, D e sem o conteúdo das
// questões, então a folha tem A a E em todas.
const _marcas = {
  0: [0], // A (certa)
  1: [1], // B (certa)
  2: [3], // D (errada)
  3: [3], // D (certa)
};

Uint8List _folha({String? qr, bool cantos = true}) => renderAnswerSheet(
  optionCounts: const [5, 5, 5, 5],
  marks: _marcas,
  qrText: qr,
  withMarkers: cantos,
  rotationDegrees: 4,
  background: true,
);

void main() {
  final folhaDaAna = _folha(qr: _qr('aluno-1'));
  final folhaDoCarlos = _folha(qr: _qr('aluno-2'));
  final folhaSemQr = _folha();

  late _CameraFalsa camera;
  setUp(() {
    camera = _CameraFalsa(folhaDaAna);
    CameraService.setInstance(camera);
  });
  tearDown(() => CameraService.setInstance(null));

  Future<void> abrir(WidgetTester tester, {Assessment? avaliacao}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CorrectionStartScreen(
          assessment: avaliacao,
          leitorFolha: _lerAgora,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fotografar(WidgetTester tester) async {
    await tester.tap(find.text('Fotografar folha'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar foto'));
    await tester.pumpAndSettle();
  }

  group('Pelo QR Code', () {
    testWidgets('a foto identifica prova e aluno e calcula a nota', (
      tester,
    ) async {
      await configurarBancoFalso();
      await abrir(tester);

      // Não pergunta avaliação nem aluno.
      expect(find.text('Selecione um aluno...'), findsNothing);
      expect(find.text('Continuar para identificação do aluno'), findsNothing);

      await fotografar(tester);

      expect(find.text('Folha lida com sucesso'), findsOneWidget);
      expect(
        find.text('Aluno(a): Ana Beatriz · Matrícula 2026041'),
        findsOneWidget,
      );
      expect(find.text('Avaliação bimestral — Cap. 4'), findsOneWidget);

      await tester.tap(find.text('Continuar para resultado'));
      await tester.pumpAndSettle();
      expect(find.text('Nota Final'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget); // 3 acertos em 4

      final salvo = await ResultadoRepository().listarPorAvaliacao('aval-1');
      expect(salvo.single.alunoId, 'aluno-1');
      expect(
        salvo.single.respostas.map((r) => r.alternativaMarcada).toList(),
        ['A', 'B', 'D', 'D'],
      );

      // A próxima folha é de outro aluno, identificado pelo QR.
      camera.foto = folhaDoCarlos;
      await tester.tap(find.text('Corrigir próxima folha'));
      await tester.pumpAndSettle();
      await fotografar(tester);
      expect(
        find.text('Aluno(a): Carlos Dias · Matrícula 2026042'),
        findsOneWidget,
      );
    });

    testWidgets('folha já corrigida é recusada', (tester) async {
      final firestore = await configurarBancoFalso();
      await adicionarResultado(
        firestore,
        alunoId: 'aluno-1',
        acertos: [true, true, false, false],
      );
      await abrir(tester);
      await fotografar(tester);

      expect(
        find.text('A prova de Ana Beatriz já foi corrigida (nota 5.0).'),
        findsOneWidget,
      );
      expect(find.text('Folha lida com sucesso'), findsNothing);
    });

    testWidgets('aberta numa avaliação, recusa folha de outra prova', (
      tester,
    ) async {
      await configurarBancoFalso();
      final avaliacao = await AvaliacaoRepository().buscar('aval-1');
      camera.foto = _folha(qr: _qr('aluno-1', prova: 'outra-prova'));
      await abrir(tester, avaliacao: avaliacao);
      await fotografar(tester);

      expect(
        find.text(
          'Esta folha é de outra prova, não de "Avaliação bimestral — Cap. 4".',
        ),
        findsOneWidget,
      );
      expect(await ResultadoRepository().listarPorAvaliacao('aval-1'), isEmpty);
    });

    testWidgets('QR ilegível pede nova foto ou a escolha manual', (
      tester,
    ) async {
      await configurarBancoFalso();
      camera.foto = folhaSemQr;
      await abrir(tester);
      await fotografar(tester);

      expect(find.textContaining('Não consegui ler o QR Code'), findsOneWidget);
      expect(find.text('Folha lida com sucesso'), findsNothing);
    });

    testWidgets('foto que não é a folha mostra o motivo', (tester) async {
      await configurarBancoFalso();
      camera.foto = _folha(qr: _qr('aluno-1'), cantos: false);
      await abrir(tester);
      await fotografar(tester);

      expect(find.textContaining('quadrados pretos'), findsWidgets);
      expect(find.text('Folha lida com sucesso'), findsNothing);
      expect(await ResultadoRepository().listarPorAvaliacao('aval-1'), isEmpty);
    });
  });

  group('Escolha manual', () {
    Future<void> escolherAna(WidgetTester tester) async {
      await tester.tap(find.text('QR Code ilegível? Escolher avaliação e aluno'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecione uma avaliação...'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Avaliação bimestral').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar para identificação do aluno'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecione um aluno...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Beatriz (2026041)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar para leitura da folha'));
      await tester.pumpAndSettle();
    }

    testWidgets('lê as bolhas de folha sem QR legível', (tester) async {
      await configurarBancoFalso();
      camera.foto = folhaSemQr;
      await abrir(tester);
      await escolherAna(tester);
      await fotografar(tester);

      expect(find.text('Folha lida com sucesso'), findsOneWidget);
      await tester.tap(find.text('Continuar para resultado'));
      await tester.pumpAndSettle();
      expect(find.text('7.5'), findsOneWidget);
    });

    testWidgets('confere o QR com o aluno escolhido', (tester) async {
      await configurarBancoFalso();
      camera.foto = folhaDoCarlos;
      await abrir(tester);
      await escolherAna(tester);
      await fotografar(tester);

      expect(
        find.text('Esta folha é de Carlos Dias, não de Ana Beatriz.'),
        findsOneWidget,
      );
      expect(find.text('Folha lida com sucesso'), findsNothing);
    });

    testWidgets('sem foto, o professor digita as respostas', (tester) async {
      await configurarBancoFalso();
      await abrir(tester);
      await escolherAna(tester);
      await tester.tap(find.text('Digitar respostas'));
      await tester.pumpAndSettle();

      expect(find.text('Revisão do Cartão'), findsOneWidget);
      // Questão 1 = A, 2 = B, 3 = C, 4 em branco.
      for (final (questao, letra) in [(0, 'A'), (1, 'B'), (2, 'C')]) {
        await tester.tap(
          find
              .descendant(
                of: find.byType(Wrap).at(questao),
                matching: find.widgetWithText(ChoiceChip, letra),
              )
              .first,
        );
        await tester.pump();
      }
      await tester.scrollUntilVisible(
        find.text('Confirmar respostas e continuar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Confirmar respostas e continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Folha lida com sucesso'), findsOneWidget);
      await tester.tap(find.text('Continuar para resultado'));
      await tester.pumpAndSettle();
      expect(find.text('7.5'), findsOneWidget);
    });
  });
}
