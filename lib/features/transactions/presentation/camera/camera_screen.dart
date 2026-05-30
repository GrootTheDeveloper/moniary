import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/camera_provider.dart';
import '../../domain/models/transaction_mutation_result.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  static const routePath = '/camera';

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    final cameras = await ref.read(cameraProvider.future);
    if (mounted && cameras.isNotEmpty) {
      _cameras = cameras;
      _initializeCamera(cameras, index: _selectedCameraIndex);
    }
  }

  String? _errorMessage;

  void _initializeCamera(List<CameraDescription> cameras, {int index = 0}) {
    final oldController = _controller;
    if (oldController != null) {
      oldController.dispose();
    }

    final controller = CameraController(
      cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = controller;
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          if (_controller != controller) return;

          // Re-apply flash mode
          controller.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
          setState(() {
            _errorMessage = null;
          });
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              if (e is CameraException && e.code == 'CameraAccessDenied') {
                _errorMessage =
                    'Không thể kết nối Camera. Vui lòng cấp quyền trong Cài đặt.';
              } else {
                _errorMessage = 'Lỗi khởi tạo Camera: ${e.toString()}';
              }
            });
          }
          debugPrint('Error initializing camera: $e');
        });
  }

  void _flipCamera() {
    if (_cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _initializeCamera(_cameras, index: _selectedCameraIndex);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _initCameras();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final image = await controller.takePicture();
      if (!mounted) return;

      final result = await context.push<TransactionMutationResult>(
        '/transaction-form',
        extra: {'imagePath': image.path},
      );

      if (result != null && mounted) {
        context.pop(result);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickFromAlbum() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final result = await context.push<TransactionMutationResult>(
        '/transaction-form',
        extra: {'imagePath': image.path},
      );

      if (result != null && mounted) {
        context.pop(result);
      }
    }
  }

  void _toggleFlash() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
      controller.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final squareSize = size.width - 32;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Chụp hóa đơn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Squared Camera Preview
            Center(
              child: Stack(
                children: [
                  Container(
                    width: squareSize,
                    height: squareSize,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width:
                              controller.value.previewSize?.height ??
                              squareSize,
                          height:
                              controller.value.previewSize?.width ?? squareSize,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                  ),
                  // In-frame Controls
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _buildInFrameButton(
                          icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          onTap: _toggleFlash,
                          isActive: _isFlashOn,
                        ),
                        const SizedBox(width: 12),
                        _buildInFrameButton(
                          icon: Icons.flip_camera_ios_outlined,
                          onTap: _flipCamera,
                          isActive: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bottom Action Controls
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // OCR Scan Button
                  _buildBottomActionButton(
                    icon: Icons.document_scanner_outlined,
                    label: 'Quét OCR',
                    onTap:
                        _takePicture, // Will capture image, OCR logic can be injected here later
                  ),

                  // Big Capture Button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Gallery Pick Button
                  _buildBottomActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Thư viện',
                    onTap: _pickFromAlbum,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildInFrameButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
