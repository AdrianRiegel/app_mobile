import 'package:app_mobile/Screens/camera_capture_screen.dart';
import 'package:app_mobile/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraService', () {
    test('verifica e solicita permissões', () async {
      final service = DefaultCameraService();
      expect(await service.checkPermission(), CameraPermissionStatus.granted);
      expect(await service.isCameraAvailable(), isTrue);

      final image = await service.captureImage();
      expect(image, isNotNull);
      expect(image!.hasBytes, isTrue);
      expect(image.name, contains('folha_resposta'));
    });

    test('lança CameraException quando indisponível', () async {
      final service = DefaultCameraService();
      service.setMockStatus(
        status: CameraPermissionStatus.granted,
        available: false,
      );

      expect(await service.isCameraAvailable(), isFalse);
      expect(service.captureImage(), throwsA(isA<CameraException>()));
    });

    test('lança CameraException quando permissão é negada', () async {
      final service = DefaultCameraService();
      service.setMockStatus(status: CameraPermissionStatus.denied);

      expect(service.captureImage(), throwsA(isA<CameraException>()));
    });
  });

  group('CameraCaptureScreen Widget', () {
    testWidgets('exibe visor da câmera e captura foto com sucesso', (
      tester,
    ) async {
      final service = DefaultCameraService();
      service.setMockStatus(status: CameraPermissionStatus.granted);

      CapturedImage? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<CapturedImage>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraCaptureScreen(service: service),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Escanear Folha de Resposta'), findsOneWidget);
      expect(
        find.text('Enquadre o cartão de respostas dentro da área delimitada'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // Clica no botão de captura
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // Confirma transição para tela de preview
      expect(find.text('Imagem Capturada com Sucesso'), findsOneWidget);
      expect(find.text('Tirar outra'), findsOneWidget);
      expect(find.text('Usar foto'), findsOneWidget);

      // Confirma e retorna a foto
      await tester.tap(find.text('Usar foto'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'folha_resposta.jpg');
    });

    testWidgets('exibe estado de permissão negada com opção de autorizar', (
      tester,
    ) async {
      final service = DefaultCameraService();
      service.setMockStatus(status: CameraPermissionStatus.denied);

      await tester.pumpWidget(
        MaterialApp(home: CameraCaptureScreen(service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acesso à Câmera Negado'), findsOneWidget);
      expect(find.text('Permitir acesso à câmera'), findsOneWidget);

      // Tenta autorizar
      await tester.tap(find.text('Permitir acesso à câmera'));
      await tester.pumpAndSettle();

      // Transiciona para o visor
      expect(find.text('Escanear Folha de Resposta'), findsOneWidget);
    });

    testWidgets('permite tirar outra foto após a captura', (tester) async {
      final service = DefaultCameraService();
      service.setMockStatus(status: CameraPermissionStatus.granted);

      await tester.pumpWidget(
        MaterialApp(home: CameraCaptureScreen(service: service)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(find.text('Imagem Capturada com Sucesso'), findsOneWidget);

      await tester.tap(find.text('Tirar outra'));
      await tester.pumpAndSettle();

      // Volta ao visor
      expect(
        find.text('Enquadre o cartão de respostas dentro da área delimitada'),
        findsOneWidget,
      );
    });
  });
}
