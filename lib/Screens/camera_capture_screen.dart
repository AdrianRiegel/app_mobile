import 'package:flutter/material.dart';

import '../components/components.dart';
import '../services/camera_service.dart';
import '../theme/app_colors.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, this.service});

  final CameraService? service;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late final CameraService _cameraService =
      widget.service ?? CameraService.instance;

  CameraPermissionStatus _permission = CameraPermissionStatus.granted;
  bool _checkingPermission = true;
  bool _isCapturing = false;
  bool _flashOn = false;
  CapturedImage? _capturedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _checkingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await _cameraService.requestPermission();
    setState(() => _permission = status);
  }

  Future<void> _takePicture() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _cameraService.captureImage();
      if (!mounted) return;
      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isCapturing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro inesperado ao capturar a foto.';
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
            onPressed: () => setState(() => _flashOn = !_flashOn),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'Enquadre o cartão de respostas dentro da área delimitada',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: const Color(0x66000000),
              ),
              child: Stack(
                children: [
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
                  Center(
                    child: Icon(
                      Icons.document_scanner,
                      size: 64,
                      color: const Color(0x4DFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: GestureDetector(
              onTap: _isCapturing ? null : _takePicture,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: AppColors.accent,
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
              ? const BorderSide(color: AppColors.accent, width: 3)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppColors.accent, width: 3)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppColors.accent, width: 3)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppColors.accent, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPreviewState() {
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
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Imagem Capturada com Sucesso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _capturedImage?.name ?? 'folha.jpg',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
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
