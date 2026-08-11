import 'package:flutter/material.dart';

/// 4pt spacing scale. Every gap, pad and inset in the apps comes from here so
/// vertical rhythm stays consistent across screens.
class KsvlSpace {
  KsvlSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Horizontal page gutter. Slightly wider on tablet/desktop.
  static double gutter(double width) => width >= 720 ? xxl : lg;
}

/// Corner radii. Three tiers only — control, container, sheet — plus `pill`.
class KsvlRadius {
  KsvlRadius._();

  /// Badges, small chips, inline tags.
  static const double xs = 8;

  /// Buttons, inputs, thumbnails.
  static const double sm = 12;

  /// Cards and panels.
  static const double md = 16;

  /// Hero surfaces and large media.
  static const double lg = 20;

  /// Modal sheets.
  static const double sheet = 24;

  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius topSheet = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Layered shadows. Two-shadow recipes read as real depth where a single
/// large-blur shadow reads as a grey smudge.
class KsvlShadow {
  KsvlShadow._();

  /// Resting cards.
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D1A1512),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A1A1512),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Raised cards, hovered tiles, sticky bars.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F1A1512),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x141A1512),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// Floating action surfaces and bottom bars.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x141A1512),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x1F1A1512),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];

  /// Tinted glow used under primary-coloured floating elements.
  static List<BoxShadow> brandGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Motion. Short and purposeful — nothing in a shop should feel slow.
class KsvlMotion {
  KsvlMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
}

/// Layout breakpoints. The customer app is a PWA that has to survive a 1920px
/// desktop window as gracefully as a 360px phone.
class KsvlBreakpoint {
  KsvlBreakpoint._();

  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1240;

  /// Storefront content never grows past this — long unbroken product rows are
  /// harder to scan than a centred column.
  static const double maxContentWidth = 1180;

  static bool isPhone(double width) => width < phone;
  static bool isTablet(double width) => width >= phone && width < desktop;
  static bool isDesktop(double width) => width >= desktop;

  /// Product grid columns for a given viewport width.
  static int productColumns(double width) {
    if (width >= 1240) return 5;
    if (width >= 980) return 4;
    if (width >= 700) return 3;
    return 2;
  }
}
