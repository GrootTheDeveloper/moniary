class ExportHistoryEntry {
  const ExportHistoryEntry({
    required this.format,
    required this.path,
    required this.createdAt,
    required this.dataTypes,
    required this.dateRange,
  });

  final String format;
  final String path;
  final DateTime createdAt;
  final List<String> dataTypes;
  final String dateRange;

  factory ExportHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ExportHistoryEntry(
      format: map['format'] as String? ?? 'unknown',
      path: map['path'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      dataTypes: (map['data_types'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      dateRange: map['date_range'] as String? ?? 'Tất cả thời gian',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'format': format,
      'path': path,
      'created_at': createdAt.toIso8601String(),
      'data_types': dataTypes,
      'date_range': dateRange,
    };
  }
}
