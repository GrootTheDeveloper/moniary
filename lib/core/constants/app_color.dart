import 'package:flutter/material.dart';

class AppColor {
  const AppColor._();

  static Color fromHex(String? hex, {Color fallback = const Color(0xFF4EA1FF)}) {
    if (hex == null || hex.isEmpty) {
      return fallback;
    }

    final sanitized = hex.replaceFirst('#', '');
    if (sanitized.length != 6 && sanitized.length != 8) {
      return fallback;
    }

    final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
    return Color(int.parse(normalized, radix: 16));
  }
}

