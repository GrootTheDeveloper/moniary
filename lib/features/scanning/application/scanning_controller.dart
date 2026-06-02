import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/app_logger.dart';

import '../data/mock_ocr_service.dart';
import '../data/ocr_service.dart';
import '../domain/ocr_result.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  return const MockOcrService();
});

final scanningControllerProvider =
    NotifierProvider.autoDispose<ScanningController, ScanningState>(
      ScanningController.new,
    );

enum ScanningStatus { empty, imageReady, scanning, success, failure }

enum ScanningError { imageSelect, imageRequired, ocrFailed }

class ScanningState {
  const ScanningState({
    this.status = ScanningStatus.empty,
    this.imagePath,
    this.result,
    this.errorType,
  });

  final ScanningStatus status;
  final String? imagePath;
  final OcrResult? result;
  final ScanningError? errorType;
}

class ScanningController extends Notifier<ScanningState> {
  @override
  ScanningState build() => const ScanningState();

  void selectImage(String imagePath) {
    state = ScanningState(
      status: ScanningStatus.imageReady,
      imagePath: imagePath,
    );
  }

  void clearImage() {
    state = const ScanningState();
  }

  void setImageError() {
    state = ScanningState(
      status: ScanningStatus.failure,
      imagePath: state.imagePath,
      errorType: ScanningError.imageSelect,
    );
  }

  Future<OcrResult?> extract() async {
    final imagePath = state.imagePath;
    if (imagePath == null) {
      state = const ScanningState(
        status: ScanningStatus.failure,
        errorType: ScanningError.imageRequired,
      );
      return null;
    }

    state = ScanningState(
      status: ScanningStatus.scanning,
      imagePath: imagePath,
    );

    try {
      final result = await ref
          .read(ocrServiceProvider)
          .extractFromImage(imagePath);
      state = ScanningState(
        status: ScanningStatus.success,
        imagePath: imagePath,
        result: result,
      );
      return result;
    } catch (e, st) {
      AppLogger.error('Failed to extract text from image', e, st);
      state = ScanningState(
        status: ScanningStatus.failure,
        imagePath: imagePath,
        errorType: ScanningError.ocrFailed,
      );
      return null;
    }
  }
}
