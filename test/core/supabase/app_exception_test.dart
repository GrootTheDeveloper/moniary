import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';

void main() {
  group('AppException Tests', () {
    test('toString returns the custom error message', () {
      const exception = AppException('Lỗi kết nối mạng');
      expect(exception.toString(), 'Lỗi kết nối mạng');
    });

    test('code property is correctly preserved and accessible', () {
      const exception = AppException('Lỗi database', code: 'POSTGRES_500');
      expect(exception.message, 'Lỗi database');
      expect(exception.code, 'POSTGRES_500');
    });
  });
}
