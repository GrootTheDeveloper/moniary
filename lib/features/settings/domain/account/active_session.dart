import 'package:flutter/foundation.dart';

@immutable
class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.userAgent,
    this.ip,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userAgent;
  final String? ip;

  factory ActiveSession.fromMap(Map<String, dynamic> map) {
    return ActiveSession(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      userAgent: map['user_agent'] as String?,
      ip: map['ip'] as String?,
    );
  }

  @override
  bool operator ==(covariant ActiveSession other) {
    if (identical(this, other)) return true;
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
