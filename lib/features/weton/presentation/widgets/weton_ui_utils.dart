import 'package:flutter/material.dart';

/// Parses a hex color string (e.g. `"#RRGGBB"`) into a [Color].
/// Returns `null` if the string is null, malformed, or not exactly 6 hex digits.
Color? parseWetonHexColor(String? hexWithHash) {
  if (hexWithHash == null) return null;
  try {
    final hex = hexWithHash.replaceAll('#', '');
    if (hex.length != 6) return null;
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return null;
  }
}
