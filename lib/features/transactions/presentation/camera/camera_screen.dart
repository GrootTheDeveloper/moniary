import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isFlashOn = false;
  bool _isInitializing = true;
  bool _isCameraInitInFlight = false;
  bool _cameraInitBlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    if (_cameraInitBlocked || _isCameraInitInFlight) return;
    _isCameraInitInFlight = true;
    try {
      final cameras = await ref.read(cameraProvider.future);
      if (!mounted) return;
      if (cameras.isEmpty) {
        ref
            .read(cameraFailureReasonProvider.notifier)
            .setFailure(CameraFailureReason.generic);
        AppLogger.warning('No cameras available — showing scanner fallback');
        setState(() {
          _isInitializing = false;
          _cameraInitBlocked = true;
        });
        return;
      }
      await _initializeCamera(cameras);
    } finally {
      _isCameraInitInFlight = false;
    }
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
        final reason = (e is CameraException && e.code == 'CameraAccessDenied')
            ? CameraFailureReason.permissionDenied
            : CameraFailureReason.generic;
        ref.read(cameraFailureReasonProvider.notifier).setFailure(reason);
        AppLogger.error(
          'Camera init failed ($reason) — showing scanner fallback',
          e,
        );
        setState(() {
          _isInitializing = false;
          _cameraInitBlocked = true;
        });
      }
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
        ScanningScreen.routePath,
        extra: image.path,
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
    final isReady = controller != null && controller.value.isInitialized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _CameraStyle.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _CameraStyle.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 393),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 12, 30, 18),
                    child: Row(
                      children: [
                        _CameraIconButton(
                          icon: Icons.close_rounded,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onTap: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            context.l10n.scanTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _CameraStyle.title,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                        _CameraIconButton(
                          icon: Icons.flash_on_rounded,
                          tooltip: context.l10n.cameraFlash,
                          onTap: _toggleFlash,
                          active: _isFlashOn,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: _ReceiptScannerFrame(
                        controller: isReady ? controller : null,
                        loading: _isInitializing,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 18, 72, 26),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CameraIconButton(
                          icon: Icons.image_outlined,
                          tooltip: context.l10n.cameraGallery,
                          onTap: _pickFromAlbum,
                          size: 46,
                        ),
                        _CaptureButton(onTap: () => _takePicture(useOcr: true)),
                        _CameraIconButton(
                          icon: Icons.camera_alt_outlined,
                          tooltip: context.l10n.cameraTakePhoto,
                          onTap: () => _takePicture(),
                          size: 46,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptScannerFrame extends StatelessWidget {
  const _ReceiptScannerFrame({required this.controller, required this.loading});

  final CameraController? controller;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _CameraStyle.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 393,
                  height: controller.value.previewSize?.width ?? 595,
                  child: CameraPreview(controller),
                ),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(color: _CameraStyle.panel),
              ),
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ReceiptFramePainter()),
              ),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _CameraStyle.accent,
                        ),
                      )
                    : Text(
                        context.l10n.cameraFrameHint.toUpperCase(),
                        key: const ValueKey('hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _CameraStyle.title,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.8,
                          letterSpacing: 2.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _CameraStyle.ring, width: 4),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: _CameraStyle.capture,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.size = 38,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? _CameraStyle.accent.withValues(alpha: 0.18)
            : _CameraStyle.control,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active
                ? _CameraStyle.accent.withValues(alpha: 0.78)
                : _CameraStyle.stroke,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: onTap == null
                  ? _CameraStyle.icon.withValues(alpha: 0.38)
                  : _CameraStyle.icon,
              size: size < 40 ? 17 : 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraStyle {
  const _CameraStyle._();

  static const background = Color(0xFF130F0B);
  static const panel = Color(0xFF241C13);
  static const control = Color(0xFF17120D);
  static const stroke = Color(0xFF44382D);
  static const grid = Color(0xFF31261B);
  static const title = Color(0xFFC7D1D2);
  static const icon = Color(0xFFD6D0C7);
  static const accent = Color(0xFFE77A4B);
  static const capture = Color(0xFFE8794C);
  static const ring = Color(0xFFE8DFD2);
}

class _ReceiptFramePainter extends CustomPainter {
  const _ReceiptFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _CameraStyle.grid.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    for (var y = 28.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final midY = size.height * 0.46;
    final guidePaint = Paint()
      ..color = _CameraStyle.accent.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.12, midY),
      Offset(size.width * 0.88, midY),
      guidePaint,
    );

    final cornerPaint = Paint()
      ..color = _CameraStyle.accent
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corner = 33.0;
    final arm = 32.0;
    final top = size.height * 0.10;
    final bottom = size.height * 0.895;
    final left = 36.0;
    final right = size.width - 36;

    final path = Path()
      ..moveTo(left, top + arm)
      ..lineTo(left, top + 8)
      ..quadraticBezierTo(left, top, left + 8, top)
      ..lineTo(left + corner, top)
      ..moveTo(right - corner, top)
      ..lineTo(right - 8, top)
      ..quadraticBezierTo(right, top, right, top + 8)
      ..lineTo(right, top + arm)
      ..moveTo(right, bottom - arm)
      ..lineTo(right, bottom - 8)
      ..quadraticBezierTo(right, bottom, right - 8, bottom)
      ..lineTo(right - corner, bottom)
      ..moveTo(left + corner, bottom)
      ..lineTo(left + 8, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - 8)
      ..lineTo(left, bottom - arm);
    canvas.drawPath(path, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
