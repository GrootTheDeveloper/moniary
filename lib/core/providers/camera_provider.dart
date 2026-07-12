import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return availableCameras();
});

/// Reason why the camera screen closed due to failure (not user-initiated close).
enum CameraFailureReason { permissionDenied, generic }

/// Notifier that holds the camera failure reason.
/// CameraScreen writes to it on error; MainShellScreen reads it after camera pop.
class CameraFailureNotifier extends Notifier<CameraFailureReason?> {
  @override
  CameraFailureReason? build() => null;

  void setFailure(CameraFailureReason reason) => state = reason;
  void clear() => state = null;
}

final cameraFailureReasonProvider =
    NotifierProvider<CameraFailureNotifier, CameraFailureReason?>(
      CameraFailureNotifier.new,
    );
