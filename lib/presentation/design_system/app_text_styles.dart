import 'package:flutter/material.dart';

/// Centralized typography helpers. Keep this UI-only and derive from Theme.
class AppTextStyles {
  static TextStyle? titleL(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.3, height: 1.08);

  static TextStyle? titleM(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2);

  static TextStyle? titleS(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2);

  static TextStyle? bodyMuted(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.25);

  static TextStyle? captionMuted(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.2);
}

