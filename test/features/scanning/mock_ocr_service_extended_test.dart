import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/scanning/data/mock_ocr_service.dart';

void main() {
  group('MockOcrService Extended Tests', () {
    test('returns valid OcrResult with correct field values', () async {
      const service = MockOcrService(delay: Duration.zero);
      final result = await service.extractFromImage('some_path.jpg');

      expect(result.merchantName, equals('Cửa hàng mẫu'));
      expect(result.totalAmount, equals(125000.0));
      expect(result.note, equals('Tự động trích xuất từ hóa đơn'));
      expect(result.transactionDate, isNotNull);
    });

    test('returns correct contents of line items', () async {
      const service = MockOcrService(delay: Duration.zero);
      final result = await service.extractFromImage('some_path.jpg');

      expect(result.items, isNotEmpty);
      expect(result.items.length, equals(1));

      final item = result.items.first;
      expect(item.name, equals('Sản phẩm mẫu'));
      expect(item.quantity, equals(1));
      expect(item.price, equals(125000.0));
    });

    test('returns confidence value within 0 and 1 range', () async {
      const service = MockOcrService(delay: Duration.zero);
      final result = await service.extractFromImage('some_path.jpg');

      expect(result.confidence, equals(0.85));
      expect(result.confidence, greaterThanOrEqualTo(0.0));
      expect(result.confidence, lessThanOrEqualTo(1.0));
    });

    test('throws ArgumentError on whitespace-only path', () async {
      const service = MockOcrService(delay: Duration.zero);

      await expectLater(service.extractFromImage('   '), throwsArgumentError);
    });
  });
}
