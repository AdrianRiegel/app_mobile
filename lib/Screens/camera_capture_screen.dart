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
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  CapturedImage? _capturedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _flashOn = _cameraService.isFlashOn;
    _lensDirection = _cameraService.lensDirection;
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

  Future<void> _toggleFlash() async {
    final newState = await _cameraService.toggleFlash();
    if (!mounted) return;
    setState(() => _flashOn = newState);
  }

  Future<void> _switchCamera() async {
    final newDirection = await _cameraService.switchCamera();
    if (!mounted) return;
    setState(() => _lensDirection = newDirection);
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao selecionar imagem da galeria.';
        _isCapturing = false;
      });
    }
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
            tooltip: _flashOn ? 'Desativar flash' : 'Ativar flash',
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.amber : Colors.white70,
            ),
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
    return Column(
      children: [
        if (_flashOn)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text(
                  'Flash Ativado',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
                border: Border.all(color: context.colors.accent, width: 2),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Galeria',
                onPressed: _isCapturing ? null : _pickFromGallery,
              ),
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
              IconButton(
                icon: Icon(
                  _lensDirection == CameraLensDirection.front
                      ? Icons.camera_front_outlined
                      : Icons.flip_camera_ios_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Alternar câmera',
                onPressed: _isCapturing ? null : _switchCamera,
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF1F222A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_capturedImage?.hasBytes == true)
                    Image.memory(
                      _capturedImage!.bytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderPreview(),
                    )
                  else
                    _buildPlaceholderPreview(),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Imagem Capturada com Sucesso',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _capturedImage?.name ?? 'folha.jpg',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
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

  Widget _buildPlaceholderPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          color: context.colors.accent,
          size: 64,
        ),
        const SizedBox(height: 12),
        Text(
          _capturedImage?.name ?? 'folha.jpg',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedState() {
    final bool permanentlyDenied =
        _permission == CameraPermissionStatus.permanentlyDenied;

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
            Text(
              permanentlyDenied
                  ? 'Acesso à Câmera Bloqueado'
                  : 'Acesso à Câmera Negado',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              permanentlyDenied
                  ? 'O acesso à câmera foi permanentemente negado. Conceda a permissão nas configurações do seu sistema operacional para continuar.'
                  : 'O EduTurmas precisa de permissão de câmera para fotografar e ler o cartão de respostas.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
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
