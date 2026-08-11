import 'package:flutter/material.dart';

/// The KSVL type scale.
///
/// Sizes step on a ~1.2 ratio and each role owns exactly one weight, which is
/// what stops a UI from looking like it was assembled a screen at a time.
class KsvlType {
  KsvlType._();

  /// Prices and counters use lining tabular figures so digits do not jitter
  /// when a quantity or total changes.
  static const List<FontFeature> tabular = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
    required Color muted,
  }) {
    return TextTheme(
      // Hero numbers and marketing headlines.
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primary,
      ),
      // Screen and card titles.
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      // Running copy.
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      // Buttons, chips, badges.
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: muted,
      ),
    );
  }
}

/// Convenience accessors for the roles used most often, so screens read as
/// `context.text.cardTitle` instead of a chain of `Theme.of` lookups.
extension KsvlTextTheme on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}
