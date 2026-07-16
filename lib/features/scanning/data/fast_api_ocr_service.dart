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
    required this.accessTokenProvider,
    required this.timeout,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _client = client;

  final String _baseUrl;
  final http.Client _client;
  final FutureOr<String?> Function() accessTokenProvider;
  final Duration timeout;

  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const AppException('errorGeneric', code: 'OCR_IMAGE_NOT_FOUND');
    }

    try {
      final accessToken = (await accessTokenProvider())?.trim();
      if (accessToken == null || accessToken.isEmpty) {
        throw const AppException('errorNotLoggedIn', code: 'AUTH_REQUIRED');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/extract'),
      )..headers['authorization'] = 'Bearer $accessToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imagePath,
          contentType: _mediaTypeForPath(imagePath),
        ),
      );

      final streamedResponse = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const AppException('errorNotLoggedIn', code: 'AUTH_REQUIRED');
        }
        if (response.statusCode == 429) {
          throw const AppException('errorConnection', code: 'OCR_RATE_LIMITED');
        }
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
    final confidenceByField = _fieldConfidence(payload['field_confidence']);
    final merchant = _stringOrNull(data['merchant']);
    final total = _positiveIntOrNull(data['total']);
    final date = _dateOrNull(data['date']);
    final address = _stringOrNull(data['address']);
    final category = _stringOrNull(data['suggested_category']);
    final paymentMethod = _stringOrNull(data['payment_method']);
    final currency = _stringOrNull(data['currency']) ?? 'VND';
    final issues = validationIssues is List
        ? validationIssues.whereType<String>().toList(growable: false)
        : const <String>[];

    return OcrResult(
      merchantSuggestion: merchant == null
          ? null
          : OcrSuggestion(
              value: merchant,
              confidence: confidenceByField['merchant'] ?? 0.65,
              source: OcrSuggestionSource.ocr,
            ),
      totalSuggestion: total == null
          ? null
          : OcrSuggestion(
              value: total,
              confidence: confidenceByField['total'] ?? 0.65,
              source: OcrSuggestionSource.ocr,
            ),
      dateSuggestion: date == null
          ? null
          : OcrSuggestion(
              value: date,
              confidence: confidenceByField['date'] ?? 0.65,
              source: OcrSuggestionSource.ocr,
            ),
      noteSuggestion: address == null
          ? null
          : OcrSuggestion(
              value: address,
              confidence: confidenceByField['address'] ?? 0.60,
              source: OcrSuggestionSource.ocr,
            ),
      categorySuggestion: category == null
          ? null
          : OcrSuggestion(
              value: category,
              confidence: confidenceByField['category'] ?? 0.55,
              source: OcrSuggestionSource.classifier,
            ),
      paymentMethod: paymentMethod,
      currency: currency,
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
      processingTime: Duration(
        milliseconds: _nonNegativeInt(payload['processing_ms']) ?? 0,
      ),
      validationIssues: issues,
      fieldConfidence: confidenceByField,
    );
  }

  OcrLineItem _mapLineItem(Map<String, dynamic> item) {
    final quantity = _positiveDoubleOrNull(item['qty']);
    return OcrLineItem(
      name: _stringOrNull(item['name']) ?? '',
      quantity: quantity,
      price:
          _positiveIntOrNull(item['amount']) ??
          _positiveIntOrNull(item['unit_price']),
      confidence: 0.75,
    );
  }

  Map<String, double> _fieldConfidence(Object? value) {
    if (value is! Map<String, dynamic>) return const {};
    return {
      for (final entry in value.entries)
        if (_positiveDoubleOrNull(entry.value) case final confidence?)
          entry.key: confidence.clamp(0.0, 1.0).toDouble(),
    };
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

  int? _positiveIntOrNull(Object? value) {
    final parsed = switch (value) {
      num number => number.round(),
      String text => double.tryParse(text)?.round(),
      _ => null,
    };
    return parsed == null || parsed <= 0 ? null : parsed;
  }

  int? _nonNegativeInt(Object? value) {
    final parsed = switch (value) {
      num number => number.round(),
      String text => double.tryParse(text)?.round(),
      _ => null,
    };
    return parsed == null || parsed < 0 ? null : parsed;
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
