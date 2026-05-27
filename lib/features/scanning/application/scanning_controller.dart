import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ScanningState {
  const ScanningState({
    this.status = ScanningStatus.empty,
    this.imagePath,
    this.result,
    this.errorMessage,
  });

  final ScanningStatus status;
  final String? imagePath;
  final OcrResult? result;
  final String? errorMessage;
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
      errorMessage: 'Không thể chọn ảnh. Vui lòng thử lại.',
    );
  }

  Future<OcrResult?> extract() async {
    final imagePath = state.imagePath;
    if (imagePath == null) {
      state = const ScanningState(
        status: ScanningStatus.failure,
        errorMessage: 'Vui lòng chọn ảnh hóa đơn trước.',
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
    } catch (_) {
      state = ScanningState(
        status: ScanningStatus.failure,
        imagePath: imagePath,
        errorMessage: 'Không thể đọc hóa đơn. Vui lòng thử lại.',
      );
      return null;
    }
  }
}
