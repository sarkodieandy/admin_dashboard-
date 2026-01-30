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

  static ColorScheme darkScheme() {
    // Keep brand warmth but shift surfaces for dark UI.
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF6B4A),
      onPrimary: Color(0xFF1A1210),
      primaryContainer: Color(0xFF4A2219),
      onPrimaryContainer: Color(0xFFFFD7CD),
      secondary: Color(0xFF4BD19A),
      onSecondary: Color(0xFF06150F),
      secondaryContainer: Color(0xFF123226),
      onSecondaryContainer: Color(0xFFCDEEDD),
      tertiary: Color(0xFFFFC07A),
      onTertiary: Color(0xFF1A1206),
      tertiaryContainer: Color(0xFF3A2A14),
      onTertiaryContainer: Color(0xFFFFE2CD),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0F0E0D),
      onSurface: Color(0xFFF3EFE7),
      surfaceContainerHighest: Color(0xFF1A1816),
      onSurfaceVariant: Color(0xFFCFC6BD),
      outline: Color(0xFF3B3733),
      shadow: Colors.black,
      inverseSurface: Color(0xFFF3EFE7),
      onInverseSurface: Color(0xFF1C1B1A),
      inversePrimary: Color(0xFFE3512B),
      surfaceTint: Color(0xFFFF6B4A),
      outlineVariant: Color(0xFF2A2622),
      scrim: Colors.black,
    );
  }
}
