import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  static const Color _fallbackColor = Color(0xFF2196F3);

  static Color fromHex(String? hex, {Color fallback = _fallbackColor}) {
    if (hex == null) {
      return fallback;
    }

    final normalized = hex.replaceFirst('#', '').trim();
    if (normalized.length != 6) {
      return fallback;
    }

    try {
      return Color(int.parse('FF$normalized', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
