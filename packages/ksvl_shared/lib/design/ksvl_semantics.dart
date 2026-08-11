import 'package:flutter/material.dart';

import 'ksvl_palette.dart';

/// Semantic colours that Material's [ColorScheme] has no slot for.
///
/// Read them with `KsvlColors.of(context)` — never reach for [KsvlPalette]
/// directly inside a widget, or the widget stops responding to theme changes.
@immutable
class KsvlColors extends ThemeExtension<KsvlColors> {
  const KsvlColors({
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.onBrandSoft,
    required this.brandGradient,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.border,
    required this.borderStrong,
    required this.surfaceSubtle,
    required this.surfaceSunken,
    required this.overlayScrim,
    required this.shadow,
  });

  /// Brand colour safe for both text-on-surface and white-on-fill.
  final Color brand;

  /// Pressed / emphasis step of [brand].
  final Color brandStrong;

  /// Tinted background for brand-flavoured panels.
  final Color brandSoft;

  /// Readable foreground on [brandSoft].
  final Color onBrandSoft;

  /// Decorative gradient for hero surfaces. Never put small text on it.
  final List<Color> brandGradient;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  /// Headings and primary content.
  final Color textPrimary;

  /// Supporting copy.
  final Color textSecondary;

  /// Metadata, timestamps, captions. Still passes AA.
  final Color textMuted;

  /// Disabled labels only.
  final Color textDisabled;

  final Color border;
  final Color borderStrong;

  /// Chips, thumbnails and inset panels sitting on a card.
  final Color surfaceSubtle;

  /// The page behind the cards.
  final Color surfaceSunken;

  final Color overlayScrim;
  final Color shadow;

  static const KsvlColors light = KsvlColors(
    brand: KsvlPalette.brand500,
    brandStrong: KsvlPalette.brand600,
    brandSoft: KsvlPalette.brand50,
    onBrandSoft: KsvlPalette.brand600,
    brandGradient: [KsvlPalette.brand400, KsvlPalette.brand600],
    success: KsvlPalette.leaf500,
    successSoft: KsvlPalette.leaf50,
    warning: KsvlPalette.amber500,
    warningSoft: KsvlPalette.amber100,
    danger: KsvlPalette.red500,
    dangerSoft: KsvlPalette.red100,
    info: KsvlPalette.blue500,
    infoSoft: KsvlPalette.blue100,
    textPrimary: KsvlPalette.neutral900,
    textSecondary: KsvlPalette.neutral600,
    textMuted: KsvlPalette.neutral500,
    textDisabled: KsvlPalette.neutral400,
    border: KsvlPalette.neutral200,
    borderStrong: KsvlPalette.neutral300,
    surfaceSubtle: KsvlPalette.neutral100,
    surfaceSunken: KsvlPalette.neutral25,
    overlayScrim: Color(0x66201814),
    shadow: Color(0xFF1A1512),
  );

  static const KsvlColors dark = KsvlColors(
    brand: KsvlPalette.brand300,
    brandStrong: KsvlPalette.brand200,
    brandSoft: Color(0xFF3A2118),
    onBrandSoft: KsvlPalette.brand200,
    brandGradient: [KsvlPalette.brand500, KsvlPalette.brand700],
    success: KsvlPalette.leaf300,
    successSoft: Color(0xFF163324),
    warning: KsvlPalette.amber300,
    warningSoft: Color(0xFF3A2C0D),
    danger: KsvlPalette.red300,
    dangerSoft: Color(0xFF3A1D1A),
    info: KsvlPalette.blue300,
    infoSoft: Color(0xFF162C3A),
    textPrimary: Color(0xFFF6F1ED),
    textSecondary: Color(0xFFC9BEB6),
    textMuted: Color(0xFFA2958C),
    textDisabled: Color(0xFF6E625B),
    border: KsvlPalette.dark500,
    borderStrong: Color(0xFF5A4E48),
    surfaceSubtle: KsvlPalette.dark600,
    surfaceSunken: KsvlPalette.dark900,
    overlayScrim: Color(0x99000000),
    shadow: Color(0xFF000000),
  );

  /// Semantic colours for the current theme.
  static KsvlColors of(BuildContext context) {
    return Theme.of(context).extension<KsvlColors>() ?? light;
  }

  @override
  KsvlColors copyWith({
    Color? brand,
    Color? brandStrong,
    Color? brandSoft,
    Color? onBrandSoft,
    List<Color>? brandGradient,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? border,
    Color? borderStrong,
    Color? surfaceSubtle,
    Color? surfaceSunken,
    Color? overlayScrim,
    Color? shadow,
  }) {
    return KsvlColors(
      brand: brand ?? this.brand,
      brandStrong: brandStrong ?? this.brandStrong,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrandSoft: onBrandSoft ?? this.onBrandSoft,
      brandGradient: brandGradient ?? this.brandGradient,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      overlayScrim: overlayScrim ?? this.overlayScrim,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  KsvlColors lerp(ThemeExtension<KsvlColors>? other, double t) {
    if (other is! KsvlColors) return this;
    return KsvlColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrandSoft: Color.lerp(onBrandSoft, other.onBrandSoft, t)!,
      brandGradient: [
        for (var i = 0; i < brandGradient.length; i++)
          Color.lerp(brandGradient[i], other.brandGradient[i], t)!,
      ],
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// `context.ksvl` reads nicer at a call site than the full static lookup.
extension KsvlColorsContext on BuildContext {
  KsvlColors get ksvl => KsvlColors.of(this);
}
