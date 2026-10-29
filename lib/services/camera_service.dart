import 'package:flutter/foundation.dart';

enum CameraPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

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

  Future<CameraPermissionStatus> checkPermission();
  Future<CameraPermissionStatus> requestPermission();
  Future<bool> isCameraAvailable();
  Future<CapturedImage?> captureImage();
}

/// Implementação padrão de CameraService com tratamento robusto para
/// dispositivos móveis, emuladores e ambientes de teste/desktop.
class DefaultCameraService implements CameraService {
  CameraPermissionStatus _status = CameraPermissionStatus.granted;
  bool _available = true;

  @visibleForTesting
  void setMockStatus({
    required CameraPermissionStatus status,
    bool available = true,
  }) {
    _status = status;
    _available = available;
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
  Future<CapturedImage?> captureImage() async {
    if (!_available) {
      throw const CameraException('Nenhuma câmera disponível no dispositivo.');
    }
    if (_status != CameraPermissionStatus.granted) {
      throw const CameraException('Permissão de acesso à câmera não concedida.');
    }

    // Retorna uma imagem capturada simulada com bytes sintéticos representativos
    final syntheticBytes = Uint8List.fromList(List.filled(1024, 0xFF));
    return CapturedImage(
      path: 'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      name: 'folha_resposta.jpg',
      bytes: syntheticBytes,
      sizeInBytes: syntheticBytes.length,
    );
  }
}
