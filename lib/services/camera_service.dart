import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

enum CameraPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

enum CameraLensDirection {
  back,
  front,
  external,
}

/// Bytes válidos de um PNG 1x1 transparente para evitar erros de decodificação
/// nativa durante testes, pré-visualizações e emuladores/desktop.
final Uint8List kValid1x1PngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class CapturedImage {
  const CapturedImage({
    required this.path,
    required this.name,
    this.bytes,
    this.sizeInBytes = 0,
  });

  final String path;
  final String name;
  final Uint8List? bytes;
  final int sizeInBytes;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

class CameraException implements Exception {
  const CameraException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Interface abstrata para controle de câmera e captura de fotos.
abstract class CameraService {
  static CameraService? _instance;

  static CameraService get instance => _instance ??= DefaultCameraService();

  @visibleForTesting
  static void setInstance(CameraService? service) {
    _instance = service;
  }

  bool get isFlashOn;
  CameraLensDirection get lensDirection;

  Future<CameraPermissionStatus> checkPermission();
  Future<CameraPermissionStatus> requestPermission();
  Future<bool> isCameraAvailable();
  Future<CapturedImage?> captureImage();
  Future<CapturedImage?> pickImageFromGallery();
  Future<bool> toggleFlash();
  Future<CameraLensDirection> switchCamera();
}

/// Implementação de CameraService que se integra à câmera nativa do dispositivo
/// móvel via `image_picker`, com fallback seguro e determinístico para testes e desktop.
class DefaultCameraService implements CameraService {
  DefaultCameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  CameraPermissionStatus _status = CameraPermissionStatus.granted;
  bool _available = true;
  bool _isMockMode = false;
  bool _flashOn = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  @override
  bool get isFlashOn => _flashOn;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @visibleForTesting
  void setMockStatus({
    required CameraPermissionStatus status,
    bool available = true,
  }) {
    _status = status;
    _available = available;
    _isMockMode = true;
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<CameraPermissionStatus> checkPermission() async {
    return _status;
  }

  @override
  Future<CameraPermissionStatus> requestPermission() async {
    if (_status == CameraPermissionStatus.permanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    _status = CameraPermissionStatus.granted;
    return _status;
  }

  @override
  Future<bool> isCameraAvailable() async {
    return _available;
  }

  @override
  Future<bool> toggleFlash() async {
    _flashOn = !_flashOn;
    return _flashOn;
  }

  @override
  Future<CameraLensDirection> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    return _lensDirection;
  }

  @override
  Future<CapturedImage?> captureImage() async {
    if (!_available) {
      throw const CameraException('Nenhuma câmera disponível no dispositivo.');
    }
    if (_status != CameraPermissionStatus.granted) {
      throw const CameraException('Permissão de acesso à câmera não concedida.');
    }

    if (_isMockMode || !_isMobile) {
      return CapturedImage(
        path: 'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
        name: 'folha_resposta.jpg',
        bytes: kValid1x1PngBytes,
        sizeInBytes: kValid1x1PngBytes.length,
      );
    }

    try {
      final preferredDevice = _lensDirection == CameraLensDirection.front
          ? CameraDevice.front
          : CameraDevice.rear;

      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredDevice,
        imageQuality: 95,
      );

      if (xFile == null) return null; // Usuário cancelou ou fechou a câmera

      final bytes = await xFile.readAsBytes();
      return CapturedImage(
        path: xFile.path,
        name: xFile.name.isNotEmpty ? xFile.name : 'folha_resposta.jpg',
        bytes: bytes,
        sizeInBytes: bytes.length,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('denied') || errStr.contains('permission')) {
        _status = CameraPermissionStatus.denied;
        throw const CameraException('Permissão de acesso à câmera negada pelo usuário.');
      }
      throw CameraException('Falha ao abrir a câmera do celular: $e');
    }
  }

  @override
  Future<CapturedImage?> pickImageFromGallery() async {
    if (_isMockMode || !_isMobile) {
      return CapturedImage(
        path: 'gallery_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        name: 'folha_resposta_galeria.jpg',
        bytes: kValid1x1PngBytes,
        sizeInBytes: kValid1x1PngBytes.length,
      );
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (xFile == null) return null;

      final bytes = await xFile.readAsBytes();
      return CapturedImage(
        path: xFile.path,
        name: xFile.name.isNotEmpty ? xFile.name : 'folha_resposta_galeria.jpg',
        bytes: bytes,
        sizeInBytes: bytes.length,
      );
    } catch (e) {
      throw CameraException('Falha ao selecionar imagem da galeria: $e');
    }
  }
}
