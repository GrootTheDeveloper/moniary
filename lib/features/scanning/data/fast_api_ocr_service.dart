import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/supabase/app_exception.dart';
import '../domain/ocr_result.dart';
import 'ocr_service.dart';

class FastApiOcrService implements OcrService {
  FastApiOcrService({
    required String baseUrl,
    required http.Client client,
    required this.timeout,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _client = client;

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const AppException('errorGeneric', code: 'OCR_IMAGE_NOT_FOUND');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/extract'),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imagePath,
        contentType: _mediaTypeForPath(imagePath),
      ),
    );

    try {
      final streamedResponse = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 504) {
          throw const AppException(
            'errorConnection',
            code: 'OCR_REQUEST_TIMEOUT',
          );
        }
        throw AppException(
          'errorConnection',
          code: 'OCR_HTTP_${response.statusCode}',
        );
      }

      final payload = _decodePayload(response.body);
      if (payload['success'] != true) {
        throw const AppException('errorGeneric', code: 'OCR_EXTRACTION_FAILED');
      }

      final rawData = payload['data'];
      if (rawData is! Map<String, dynamic>) {
        throw const AppException('errorGeneric', code: 'OCR_INVALID_RESPONSE');
      }

      return _mapResult(payload, rawData);
    } on TimeoutException {
      throw const AppException('errorConnection', code: 'OCR_REQUEST_TIMEOUT');
    } on SocketException {
      throw const AppException('errorConnection', code: 'OCR_API_UNAVAILABLE');
    } on http.ClientException {
      throw const AppException('errorConnection', code: 'OCR_API_UNAVAILABLE');
    } on FormatException {
      throw const AppException('errorGeneric', code: 'OCR_INVALID_RESPONSE');
    }
  }

  Map<String, dynamic> _decodePayload(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('OCR response must be a JSON object.');
    }
    return decoded;
  }

  OcrResult _mapResult(
    Map<String, dynamic> payload,
    Map<String, dynamic> data,
  ) {
    final validationIssues = payload['validation_issues'];
    final hasValidationIssues =
        validationIssues is List && validationIssues.isNotEmpty;
    final items = data['items'];

    return OcrResult(
      merchantName: _stringOrNull(data['merchant']),
      totalAmount: _positiveDoubleOrNull(data['total']),
      transactionDate: _dateOrNull(data['date']),
      note: _stringOrNull(data['address']),
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(_mapLineItem)
                .where((item) => item.name.isNotEmpty)
                .toList(growable: false)
          : const [],
      confidence:
          _positiveDoubleOrNull(payload['confidence']) ??
          (hasValidationIssues ? 0.65 : 0.85),
    );
  }

  OcrLineItem _mapLineItem(Map<String, dynamic> item) {
    final quantity = _positiveDoubleOrNull(item['qty']);
    return OcrLineItem(
      name: _stringOrNull(item['name']) ?? '',
      quantity: quantity,
      price:
          _positiveDoubleOrNull(item['amount']) ??
          _positiveDoubleOrNull(item['unit_price']),
    );
  }

  String? _stringOrNull(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  double? _positiveDoubleOrNull(Object? value) {
    final parsed = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };
    return parsed == null || parsed <= 0 ? null : parsed;
  }

  DateTime? _dateOrNull(Object? value) {
    final raw = _stringOrNull(value);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  MediaType _mediaTypeForPath(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (normalized.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
