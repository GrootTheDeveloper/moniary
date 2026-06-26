import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/scanning/data/fast_api_ocr_service.dart';

void main() {
  late Directory tempDirectory;
  late File imageFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('moniary_ocr_test_');
    imageFile = File('${tempDirectory.path}/receipt.jpg');
    await imageFile.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('maps FastAPI receipt response to OcrResult', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://localhost:8000/extract');
      expect(request.headers['content-type'], contains('multipart/form-data'));

      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'merchant': 'Cửa hàng A',
            'address': '1 Nguyễn Huệ',
            'date': '2026-06-09',
            'items': [
              {
                'name': 'Cà phê sữa',
                'qty': 1.5,
                'unit_price': 23.833333,
                'amount': 35.75,
              },
            ],
            'total': 117.25,
          },
          'validation_issues': <String>[],
          'confidence': 0.92,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final service = FastApiOcrService(
      baseUrl: 'http://localhost:8000/',
      client: client,
      timeout: const Duration(seconds: 1),
    );

    final result = await service.extractFromImage(imageFile.path);

    expect(result.merchantName, 'Cửa hàng A');
    expect(result.note, '1 Nguyễn Huệ');
    expect(result.transactionDate, DateTime(2026, 6, 9));
    expect(result.totalAmount, 117.25);
    expect(result.items, hasLength(1));
    expect(result.items.single.name, 'Cà phê sữa');
    expect(result.items.single.quantity, 1.5);
    expect(result.items.single.price, 35.75);
    expect(result.confidence, 0.92);
  });

  test('maps backend HTTP failures to AppException', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'Only JPEG images are accepted'}),
        415,
      );
    });
    addTearDown(client.close);

    final service = FastApiOcrService(
      baseUrl: 'http://localhost:8000',
      client: client,
      timeout: const Duration(seconds: 1),
    );

    await expectLater(
      service.extractFromImage(imageFile.path),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'OCR_HTTP_415',
        ),
      ),
    );
  });

  test('maps backend inference timeout to OCR timeout', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': false,
          'error': 'Ollama did not respond within 240 seconds.',
        }),
        504,
      );
    });
    addTearDown(client.close);

    final service = FastApiOcrService(
      baseUrl: 'http://localhost:8000',
      client: client,
      timeout: const Duration(seconds: 1),
    );

    await expectLater(
      service.extractFromImage(imageFile.path),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'OCR_REQUEST_TIMEOUT',
        ),
      ),
    );
  });

  test('rejects a missing local image before sending a request', () async {
    final client = MockClient((request) async {
      fail('HTTP request should not be sent for a missing image.');
    });
    addTearDown(client.close);

    final service = FastApiOcrService(
      baseUrl: 'http://localhost:8000',
      client: client,
      timeout: const Duration(seconds: 1),
    );

    await expectLater(
      service.extractFromImage('${tempDirectory.path}/missing.jpg'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'OCR_IMAGE_NOT_FOUND',
        ),
      ),
    );
  });
}
