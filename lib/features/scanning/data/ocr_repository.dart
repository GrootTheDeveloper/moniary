import '../../../core/supabase/app_exception.dart';
import '../domain/ocr_result.dart';
import 'ocr_service.dart';

class OcrRepository {
  const OcrRepository(this._dataSource);

  final OcrService _dataSource;

  Future<OcrResult> extractFromImage(String imagePath) async {
    try {
      return await _dataSource.extractFromImage(imagePath);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('errorGeneric', code: 'OCR_EXTRACTION_FAILED');
    }
  }
}
