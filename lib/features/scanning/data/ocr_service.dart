import '../domain/ocr_result.dart';

abstract interface class OcrService {
  Future<OcrResult> extractFromImage(String imagePath);
}
