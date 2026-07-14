import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/features/scanning/application/scanning_controller.dart';
import 'package:moniary/features/scanning/data/fast_api_ocr_service.dart';
import 'package:moniary/features/scanning/data/ocr_service.dart';
import 'package:moniary/features/scanning/domain/ocr_result.dart';

class ErrorOcrService implements OcrService {
  const ErrorOcrService();

  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    throw Exception('Failed to extract');
  }
}

class SuccessOcrService implements OcrService {
  const SuccessOcrService();

  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    return const OcrResult(
      merchantSuggestion: OcrSuggestion(
        value: 'Test merchant',
        confidence: 0.9,
        source: OcrSuggestionSource.ocr,
      ),
      totalSuggestion: OcrSuggestion(
        value: 117,
        confidence: 0.9,
        source: OcrSuggestionSource.ocr,
      ),
      confidence: 0.9,
    );
  }
}

void main() {
  group('ScanningController Tests', () {
    test('default OCR provider always uses FastAPI', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(ocrServiceProvider), isA<FastApiOcrService>());
      expect(AppConstants.ocrApiUrl, 'http://10.0.2.2:8000');
    });

    test('Initial state is ScanningStatus.empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(scanningControllerProvider, (previous, next) {});

      final state = container.read(scanningControllerProvider);
      expect(state.status, ScanningStatus.empty);
      expect(state.imagePath, isNull);
      expect(state.result, isNull);
      expect(state.errorType, isNull);
    });

    test('selectImage sets state to imageReady', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(scanningControllerProvider, (previous, next) {});

      final controller = container.read(scanningControllerProvider.notifier);
      controller.selectImage('test_image.png');

      final state = container.read(scanningControllerProvider);
      expect(state.status, ScanningStatus.imageReady);
      expect(state.imagePath, 'test_image.png');
    });

    test('clearImage resets state to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(scanningControllerProvider, (previous, next) {});

      final controller = container.read(scanningControllerProvider.notifier);
      controller.selectImage('test_image.png');
      controller.clearImage();

      final state = container.read(scanningControllerProvider);
      expect(state.status, ScanningStatus.empty);
      expect(state.imagePath, isNull);
    });

    test('setImageError transitions status to failure', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(scanningControllerProvider, (previous, next) {});

      final controller = container.read(scanningControllerProvider.notifier);
      controller.selectImage('test_image.png');
      controller.setImageError();

      final state = container.read(scanningControllerProvider);
      expect(state.status, ScanningStatus.failure);
      expect(state.errorType, ScanningError.imageSelect);
    });

    test('extract without image fails immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(scanningControllerProvider, (previous, next) {});

      final controller = container.read(scanningControllerProvider.notifier);
      final result = await controller.extract();

      final state = container.read(scanningControllerProvider);
      expect(result, isNull);
      expect(state.status, ScanningStatus.failure);
      expect(state.errorType, ScanningError.imageRequired);
    });

    test(
      'extract with image transitions to success when OCR service succeeds',
      () async {
        final container = ProviderContainer(
          overrides: [
            ocrServiceProvider.overrideWithValue(const SuccessOcrService()),
          ],
        );
        addTearDown(container.dispose);
        container.listen(scanningControllerProvider, (previous, next) {});

        final controller = container.read(scanningControllerProvider.notifier);
        controller.selectImage('test_image.png');

        final result = await controller.extract();

        final state = container.read(scanningControllerProvider);
        expect(result, isNotNull);
        expect(state.status, ScanningStatus.success);
        expect(state.result?.merchantName, 'Test merchant');
        expect(state.result?.totalAmount, 117);
      },
    );

    test(
      'extract with image transition flow to failure when service throws',
      () async {
        final container = ProviderContainer(
          overrides: [
            ocrServiceProvider.overrideWithValue(const ErrorOcrService()),
          ],
        );
        addTearDown(container.dispose);
        container.listen(scanningControllerProvider, (previous, next) {});

        final controller = container.read(scanningControllerProvider.notifier);
        controller.selectImage('test_image.png');

        final result = await controller.extract();

        final state = container.read(scanningControllerProvider);
        expect(result, isNull);
        expect(state.status, ScanningStatus.failure);
        expect(state.errorType, ScanningError.ocrFailed);
      },
    );
  });
}
