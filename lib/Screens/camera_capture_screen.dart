import 'dart:io' show Platform;
import 'package:camera/camera.dart' hide CameraLensDirection, CameraException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/components.dart';
import '../services/camera_service.dart';
import '../theme/app_colors.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, this.service, this.instruction});

  final CameraService? service;

  /// Orientação exibida acima do visor.
  final String? instruction;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  late final CameraService _cameraService =
      widget.service ?? CameraService.instance;

  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;

  CameraPermissionStatus _permission = CameraPermissionStatus.granted;
  bool _checkingPermission = true;
  bool _isCapturing = false;
  bool _flashOn = false;
  CapturedImage? _capturedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initLiveCameraController();
    }
  }

  Future<void> _checkPermission() async {
    setState(() {
      _checkingPermission = true;
      _errorMessage = null;
    });

    try {
      final available = await _cameraService.isCameraAvailable();
      if (!available) {
        setState(() {
          _errorMessage = 'Nenhuma câmera encontrada neste dispositivo.';
          _checkingPermission = false;
        });
        return;
      }

      final status = await _cameraService.checkPermission();
      setState(() {
        _permission = status;
        _checkingPermission = false;
      });

      if (status == CameraPermissionStatus.granted && widget.service == null) {
        await _initLiveCameraController();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _checkingPermission = false;
      });
    }
  }

  Future<void> _initLiveCameraController() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return;

      final lensDirection = _cameraService.lensDirection == CameraLensDirection.front
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final targetCamera = _availableCameras.firstWhere(
        (c) => c.lensDirection.name == lensDirection.name,
        orElse: () => _availableCameras.first,
      );

      final controller = CameraController(
        targetCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller?.dispose();
        _controller = controller;
        _isCameraInitialized = true;
      });
    } catch (_) {
      // Falha graciosa: caso o controller do CameraX/AVFoundation falhe,
      // a captura funcionará diretamente via ImagePicker nativo
      _controller = null;
      _isCameraInitialized = false;
    }
  }

  Future<void> _requestPermission() async {
    final status = await _cameraService.requestPermission();
    setState(() => _permission = status);
    if (status == CameraPermissionStatus.granted && widget.service == null) {
      await _initLiveCameraController();
    }
  }

  Future<void> _toggleFlash() async {
    final nextFlash = !_flashOn;
    setState(() => _flashOn = nextFlash);
    await _cameraService.toggleFlash();

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setFlashMode(
          nextFlash ? FlashMode.torch : FlashMode.off,
        );
      } catch (_) {}
    }
  }

  Future<void> _switchCamera() async {
    await _cameraService.switchCamera();
    if (_availableCameras.length > 1) {
      await _initLiveCameraController();
    }
  }

  Future<void> _takePicture() async {
    setState(() => _isCapturing = true);
    try {
      CapturedImage? image;

      if (_controller != null && _controller!.value.isInitialized) {
        try {
          final xFile = await _controller!.takePicture();
          final bytes = await xFile.readAsBytes();
          image = CapturedImage(
            path: xFile.path,
            name: xFile.name.isNotEmpty ? xFile.name : 'folha_resposta.jpg',
            bytes: bytes,
            sizeInBytes: bytes.length,
          );
        } catch (_) {
          // Fallback para CameraService caso takePicture do controller falhe
          image = await _cameraService.captureImage();
        }
      } else {
        image = await _cameraService.captureImage();
      }

      if (!mounted) return;
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isCapturing = false;
        });
      } else {
        setState(() => _isCapturing = false);
      }
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isCapturing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro inesperado ao capturar a foto da folha.';
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _cameraService.pickImageFromGallery();
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isCapturing = false;
        });
      } else {
        setState(() => _isCapturing = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isCapturing = false;
      });
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _errorMessage = null;
    });
  }

  void _confirm() {
    if (_capturedImage != null) {
      Navigator.pop(context, _capturedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Escanear Folha de Resposta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.amber : Colors.white70,
            ),
            tooltip: 'Alternar Flash',
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_checkingPermission) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accent),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_permission != CameraPermissionStatus.granted) {
      return _buildPermissionDeniedState();
    }

    if (_capturedImage != null) {
      return _buildPreviewState();
    }

    return _buildCameraViewfinder();
  }

  Widget _buildCameraViewfinder() {
    final hasLivePreview =
        _isCameraInitialized && _controller != null && _controller!.value.isInitialized;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            widget.instruction ??
                'Enquadre a folha de respostas inteira, com os 4 quadrados '
                    'pretos dos cantos visíveis',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.accent, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: const Color(0x66000000),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasLivePreview)
                      Center(
                        child: CameraPreview(_controller!),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.document_scanner,
                          size: 64,
                          color: const Color(0x4DFFFFFF),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _cornerMarker(top: true, left: true),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _cornerMarker(top: true, left: false),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _cornerMarker(top: false, left: true),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _cornerMarker(top: false, left: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botão Galeria
              IconButton(
                onPressed: _isCapturing ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                tooltip: 'Escolher da Galeria',
              ),
              // Botão Principal Disparador
              GestureDetector(
                onTap: _isCapturing ? null : _takePicture,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: context.colors.accent,
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
              ),
              // Botão Alternar Câmera
              IconButton(
                onPressed: _isCapturing ? null : _switchCamera,
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                tooltip: 'Alternar Lente',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cornerMarker({required bool top, required bool left}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: context.colors.accent, width: 3)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: context.colors.accent, width: 3)
              : BorderSide.none,
          left: left
              ? BorderSide(color: context.colors.accent, width: 3)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: context.colors.accent, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
    final imageBytes = _capturedImage?.bytes;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1F222A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (imageBytes != null && imageBytes.isNotEmpty)
                      Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackPreview(),
                      )
                    else
                      _buildFallbackPreview(),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: context.colors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Imagem Capturada com Sucesso',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _capturedImage?.name ?? 'folha.jpg',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Tirar outra',
                  icon: Icons.refresh,
                  onPressed: _retake,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Usar foto',
                  icon: Icons.check,
                  onPressed: _confirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner,
          color: context.colors.accent,
          size: 64,
        ),
        const SizedBox(height: 12),
        const Text(
          'Imagem Capturada',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 64,
              color: Colors.white60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acesso à Câmera Negado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O EduTurmas precisa de permissão de câmera para fotografar e ler o cartão de respostas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Permitir acesso à câmera',
              onPressed: _requestPermission,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 56,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              label: 'Tentar novamente',
              onPressed: _checkPermission,
            ),
          ],
        ),
      ),
    );
  }
}
