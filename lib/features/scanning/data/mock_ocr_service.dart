import '../domain/ocr_result.dart';
import 'ocr_service.dart';

class MockOcrService implements OcrService {
  const MockOcrService({this.delay = const Duration(seconds: 2)});

  final Duration delay;

  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      throw ArgumentError('Cần chọn ảnh hóa đơn trước khi quét.');
    }

    await Future<void>.delayed(delay);

    return OcrResult(
      merchantName: 'Cửa hàng mẫu',
      totalAmount: 125000,
      transactionDate: DateTime.now(),
      note: 'Tự động trích xuất từ hóa đơn',
      items: const [
        OcrLineItem(name: 'Sản phẩm mẫu', quantity: 1, price: 125000),
      ],
      confidence: 0.85,
    );
  }
}
