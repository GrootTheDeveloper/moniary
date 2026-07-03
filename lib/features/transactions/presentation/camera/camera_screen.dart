import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/providers/camera_provider.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../scanning/presentation/scanning_screen.dart';
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
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    final cameras = await ref.read(cameraProvider.future);
    if (!mounted) return;
    if (cameras.isEmpty) {
      // No cameras available on this device — signal failure immediately
      ref
          .read(cameraFailureReasonProvider.notifier)
          .setFailure(CameraFailureReason.generic);
      AppLogger.warning('No cameras available — signalling fallback');
      context.pop();
      return;
    }
    _cameras = cameras;
    await _initializeCamera(cameras, index: _selectedCameraIndex);
  }

  Future<void> _initializeCamera(
    List<CameraDescription> cameras, {
    int index = 0,
  }) async {
    final oldController = _controller;
    if (oldController != null) {
      _controller = null;
      setState(() {});
      await oldController.dispose();
    }

    final controller = CameraController(
      cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;

      _controller = controller;
      // Re-apply flash mode
      await controller.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (e.toString().contains('disposed')) {
        // Ignore disposed errors from interrupted initializations
        return;
      }
      if (mounted) {
        // Signal failure reason to MainShellScreen via provider,
        // then auto-pop — no error UI shown to the user.
        final reason = (e is CameraException && e.code == 'CameraAccessDenied')
            ? CameraFailureReason.permissionDenied
            : CameraFailureReason.generic;
        ref.read(cameraFailureReasonProvider.notifier).setFailure(reason);
        AppLogger.error(
          'Camera init failed ($reason) — signalling fallback',
          e,
        );
        context.pop();
      }
    }
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

  Future<void> _takePicture({bool useOcr = false}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final router = GoRouter.of(context);

    try {
      final image = await controller.takePicture();
      if (!mounted) return;

      final result = useOcr
          ? await router.push<TransactionMutationResult>(
              ScanningScreen.routePath,
              extra: image.path,
            )
          : await router.push<TransactionMutationResult>(
              '/transaction-form',
              extra: {'imagePath': image.path},
            );

      if (result != null && mounted) {
        router.pop(result);
      }
    } catch (e, st) {
      AppLogger.error('Error taking picture', e, st);
    }
  }

  Future<void> _pickFromAlbum() async {
    final router = GoRouter.of(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final result = await router.push<TransactionMutationResult>(
        '/transaction-form',
        extra: {'imagePath': image.path},
      );

      if (result != null && mounted) {
        router.pop(result);
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
        body: Center(
          child: _isInitializing
              ? const CircularProgressIndicator(color: Colors.white)
              : const SizedBox.shrink(),
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
                  Text(
                    context.l10n.cameraTitle,
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: const _ReceiptFramePainter()),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 24,
                    right: 24,
                    child: Text(
                      context.l10n.cameraFrameHint.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
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
                    label: context.l10n.cameraOcrScan,
                    onTap: () => _takePicture(useOcr: true),
                  ),

                  // Big Capture Button
                  GestureDetector(
                    onTap: () => _takePicture(),
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
                    label: context.l10n.cameraGallery,
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
              ? AppTheme.amber.withValues(alpha: 0.8)
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

class _ReceiptFramePainter extends CustomPainter {
  const _ReceiptFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 18.0;
    const arm = 42.0;
    final paint = Paint()
      ..color = AppTheme.terracottaBright
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(inset, inset + arm)
      ..lineTo(inset, inset)
      ..lineTo(inset + arm, inset)
      ..moveTo(size.width - inset - arm, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + arm)
      ..moveTo(size.width - inset, size.height - inset - arm)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset - arm, size.height - inset)
      ..moveTo(inset + arm, size.height - inset)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset, size.height - inset - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
