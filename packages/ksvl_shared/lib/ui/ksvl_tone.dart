import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';

/// The meaning a small surface carries — badges, banners, icon tiles.
///
/// Widgets take a [KsvlTone] rather than raw colours so "this is a warning"
/// is expressed once and rendered identically everywhere.
enum KsvlTone { neutral, brand, success, warning, danger, info }

/// Foreground / background / border triple for a tone.
@immutable
class KsvlToneColors {
  const KsvlToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

extension KsvlToneResolver on KsvlTone {
  KsvlToneColors resolve(BuildContext context) {
    final k = KsvlColors.of(context);
    final (Color fg, Color bg) = switch (this) {
      KsvlTone.neutral => (k.textSecondary, k.surfaceSubtle),
      KsvlTone.brand => (k.brand, k.brandSoft),
      KsvlTone.success => (k.success, k.successSoft),
      KsvlTone.warning => (k.warning, k.warningSoft),
      KsvlTone.danger => (k.danger, k.dangerSoft),
      KsvlTone.info => (k.info, k.infoSoft),
    };
    return KsvlToneColors(
      foreground: fg,
      background: bg,
      border: this == KsvlTone.neutral
          ? k.border
          : fg.withValues(alpha: 0.22),
    );
  }

  /// The saturated colour on its own, for icons and solid fills.
  Color solid(BuildContext context) => resolve(context).foreground;
}
