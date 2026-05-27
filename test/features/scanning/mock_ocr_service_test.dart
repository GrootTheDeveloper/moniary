import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/scanning/data/mock_ocr_service.dart';

void main() {
  test('mock OCR trả về dữ liệu giao dịch hợp lệ', () async {
    const service = MockOcrService(delay: Duration.zero);

    final result = await service.extractFromImage('/tmp/receipt.jpg');

    expect(result.merchantName, isNotEmpty);
    expect(result.totalAmount, greaterThan(0));
    expect(result.transactionDate, isNotNull);
    expect(result.confidence, inInclusiveRange(0, 1));
  });

  test('mock OCR từ chối đường dẫn ảnh rỗng', () async {
    const service = MockOcrService(delay: Duration.zero);

    await expectLater(service.extractFromImage(''), throwsArgumentError);
  });
}
