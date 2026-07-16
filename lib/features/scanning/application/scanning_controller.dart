import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';

import '../data/fast_api_ocr_service.dart';
import '../data/ocr_repository.dart';
import '../data/ocr_service.dart';
import '../domain/ocr_result.dart';

final ocrHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return FastApiOcrService(
    baseUrl: AppConstants.ocrApiUrl,
    client: ref.watch(ocrHttpClientProvider),
    accessTokenProvider: () => ref.read(currentSessionProvider)?.accessToken,
    timeout: AppConstants.ocrRequestTimeout,
  );
});

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  return OcrRepository(ref.watch(ocrServiceProvider));
});

final ocrExtractionControllerProvider = Provider<OcrExtractionController>((
  ref,
) {
  return OcrExtractionController(ref.watch(ocrRepositoryProvider));
});

final scanningControllerProvider =
    NotifierProvider.autoDispose<ScanningController, ScanningState>(
      ScanningController.new,
    );

enum ScanningStatus { empty, imageReady, scanning, success, failure }

enum ScanningError { imageSelect, imageRequired, ocrFailed }

class OcrExtractionController {
  const OcrExtractionController(this._repository);

  final OcrRepository _repository;

  Future<OcrResult> extractFromImage(String imagePath) {
    return _repository.extractFromImage(imagePath);
  }
}

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
    final stopwatch = Stopwatch()..start();

    try {
      final result = await ref
          .read(ocrExtractionControllerProvider)
          .extractFromImage(imagePath);
      stopwatch.stop();
      AppLogger.info(
        'OCR completed in ${stopwatch.elapsedMilliseconds}ms '
        '(server ${result.processingTime.inMilliseconds}ms)',
      );
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
