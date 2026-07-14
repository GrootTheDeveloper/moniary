class ExportHistoryEntry {
  const ExportHistoryEntry({
    required this.format,
    required this.path,
    required this.createdAt,
    required this.dataTypes,
    this.startDate,
    this.endDate,
    this.legacyDateRange,
  });

  final String format;
  final String path;
  final DateTime createdAt;
  final List<String> dataTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? legacyDateRange;

  bool get hasDateRange => startDate != null || endDate != null;

  factory ExportHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ExportHistoryEntry(
      format: map['format'] as String? ?? '',
      path: map['path'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      dataTypes: (map['data_types'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
      legacyDateRange: _nonEmptyString(map['date_range']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'format': format,
      'path': path,
      'created_at': createdAt.toIso8601String(),
      'data_types': dataTypes,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };

    if (legacyDateRange != null && !hasDateRange) {
      map['date_range'] = legacyDateRange;
    }

    return map;
  }

  static DateTime? _parseDate(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  static String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
