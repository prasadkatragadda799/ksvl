import 'package:flutter/material.dart';

/// Raw colour ramps for KSVL Naturals.
///
/// Every ramp is warm-tinted so the neutrals sit naturally beside the
/// terracotta brand colour instead of reading as cold grey.
///
/// Contrast ratios quoted below are measured against `neutral0` (white) for
/// light-mode use and are the reason each step exists — do not swap a step for
/// a "nicer looking" nearby value without re-checking it.
class KsvlPalette {
  KsvlPalette._();

  // ---------------------------------------------------------------------------
  // Brand — terracotta / roasted saffron. The identity colour of the store.
  // ---------------------------------------------------------------------------

  static const Color brand50 = Color(0xFFFDF5F0);
  static const Color brand100 = Color(0xFFF9E4D8);
  static const Color brand200 = Color(0xFFF1C6AE);
  static const Color brand300 = Color(0xFFE4A17E);
  static const Color brand400 = Color(0xFFD2662F);

  /// Primary interactive colour. 5.37:1 on white **and** 5.37:1 under white
  /// text, so it is safe as a label colour and as a button fill.
  static const Color brand500 = Color(0xFFB4491F);
  static const Color brand600 = Color(0xFF9A3D19);
  static const Color brand700 = Color(0xFF7C3014);
  static const Color brand800 = Color(0xFF5B2210);
  static const Color brand900 = Color(0xFF3A160A);

  // ---------------------------------------------------------------------------
  // Leaf — the "natural / fresh / saved money" green.
  // ---------------------------------------------------------------------------

  static const Color leaf50 = Color(0xFFF0F7F3);
  static const Color leaf100 = Color(0xFFD9EDE1);
  static const Color leaf200 = Color(0xFFA9D5BD);
  static const Color leaf300 = Color(0xFF6DB58F);

  /// 6.42:1 on white. Safe for text, badges and fills with white labels.
  static const Color leaf500 = Color(0xFF1F6B45);
  static const Color leaf600 = Color(0xFF175636);
  static const Color leaf700 = Color(0xFF104028);

  // ---------------------------------------------------------------------------
  // Warm neutrals — hue ≈ 25°, very low chroma.
  // ---------------------------------------------------------------------------

  static const Color neutral0 = Color(0xFFFFFFFF);

  /// App background. Warm off-white, not clinical grey.
  static const Color neutral25 = Color(0xFFFDFBF9);
  static const Color neutral50 = Color(0xFFF8F4F0);

  /// Subtle fills: chips, thumbnails, inset panels.
  static const Color neutral100 = Color(0xFFF1EBE5);

  /// Default border / divider.
  static const Color neutral200 = Color(0xFFE5DDD5);

  /// Stronger border, used on tinted surfaces where 200 disappears.
  static const Color neutral300 = Color(0xFFD3C8BE);

  /// Decorative icons and disabled text only — 2.6:1, never for real content.
  static const Color neutral400 = Color(0xFFA99C93);

  /// Muted text. 5.0:1 — the lightest step allowed to carry words.
  static const Color neutral500 = Color(0xFF7A6D65);

  /// Secondary text. 7.55:1.
  static const Color neutral600 = Color(0xFF5E524B);
  static const Color neutral700 = Color(0xFF443A34);
  static const Color neutral800 = Color(0xFF2B231F);

  /// Primary text. 18.1:1.
  static const Color neutral900 = Color(0xFF1A1512);

  // ---------------------------------------------------------------------------
  // Dark-mode surfaces — warm charcoals, not pure black.
  // ---------------------------------------------------------------------------

  static const Color dark900 = Color(0xFF14100E);
  static const Color dark800 = Color(0xFF1D1815);
  static const Color dark700 = Color(0xFF272120);
  static const Color dark600 = Color(0xFF352D2A);
  static const Color dark500 = Color(0xFF473D38);

  // ---------------------------------------------------------------------------
  // Status colours. Each is ≥ 4.5:1 on white and under white text.
  // ---------------------------------------------------------------------------

  /// 5.93:1 — deep amber. The old #D4920A was 2.65:1 and unreadable.
  static const Color amber500 = Color(0xFF8A5A05);
  static const Color amber100 = Color(0xFFFBEFD6);
  static const Color amber300 = Color(0xFFE0A21C);

  /// 6.54:1 — brick red.
  static const Color red500 = Color(0xFFB3261E);
  static const Color red100 = Color(0xFFFBE6E4);
  static const Color red300 = Color(0xFFE0685F);

  /// 6.84:1 — deep teal-blue for informational states.
  static const Color blue500 = Color(0xFF1E5F8C);
  static const Color blue100 = Color(0xFFE1EDF5);
  static const Color blue300 = Color(0xFF5B9BC4);

  /// WhatsApp brand green — only ever used as a fill behind white text.
  static const Color whatsapp = Color(0xFF1EA952);

  // ---------------------------------------------------------------------------
  // Category accents. Purely decorative: they tint product thumbnails so a
  // grid of emoji reads as a grid of *categories* at a glance. Never used for
  // text, so they are tuned for pleasantness rather than contrast.
  // ---------------------------------------------------------------------------

  static const Color plum500 = Color(0xFF6B3F7A);
  static const Color plum100 = Color(0xFFF3ECF6);

  static const Color gold500 = Color(0xFF9A6B12);
  static const Color gold100 = Color(0xFFFAF1DF);

  static const Color clay500 = Color(0xFF8C5A3C);
  static const Color clay100 = Color(0xFFF7EEE7);
}
