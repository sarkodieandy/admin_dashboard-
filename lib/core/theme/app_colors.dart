import 'package:flutter/material.dart';

class AppColors {
  static const charcoal = Color(0xFF1C1B1A);
  static const cream = Color(0xFFF7F2E8);
  static const cream2 = Color(0xFFF2EAD8);
  static const spicy = Color(0xFFE3512B);
  static const spicyDark = Color(0xFFB93A1F);
  static const fresh = Color(0xFF2E8B57);
  static const gold = Color(0xFFF4A261);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: spicy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFD7CD),
      onPrimaryContainer: charcoal,
      secondary: fresh,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFCDEEDD),
      onSecondaryContainer: charcoal,
      tertiary: gold,
      onTertiary: charcoal,
      tertiaryContainer: Color(0xFFFFE2CD),
      onTertiaryContainer: charcoal,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: charcoal,
      surface: cream,
      onSurface: charcoal,
      surfaceContainerHighest: cream2,
      onSurfaceVariant: Color(0xFF4A4642),
      outline: Color(0x33211F1D),
      shadow: Colors.black,
      inverseSurface: charcoal,
      onInverseSurface: cream,
      inversePrimary: Color(0xFFFFB4A5),
      surfaceTint: spicy,
      outlineVariant: Color(0x1F211F1D),
      scrim: Colors.black,
    );
  }
}

