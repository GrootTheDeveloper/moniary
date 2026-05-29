import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/features/scanning/application/scanning_controller.dart';
import 'package:moniary/features/scanning/data/ocr_service.dart';
import 'package:moniary/features/scanning/domain/ocr_result.dart';

class ErrorOcrService implements OcrService {
  const ErrorOcrService();

  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    throw Exception('Failed to extract');
  }
}

void main() {
  group('ScanningController Tests', () {
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

    test('extract with image transition flow to success using MockOcrService', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(scanningControllerProvider, (previous, next) {});

      final controller = container.read(scanningControllerProvider.notifier);
      controller.selectImage('test_image.png');

      final result = await controller.extract();

      final state = container.read(scanningControllerProvider);
      expect(result, isNotNull);
      expect(state.status, ScanningStatus.success);
      expect(state.result?.merchantName, isNotNull);
    });

    test('extract with image transition flow to failure when service throws', () async {
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
    });
  });
}
