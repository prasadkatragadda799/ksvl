import 'package:flutter/material.dart';

import '../models/catalog_category.dart';

/// Compatibility wrapper around [CategoryStyleKit] for existing call sites.
@immutable
class KsvlCategoryStyle {
  const KsvlCategoryStyle({
    required this.tint,
    required this.accent,
    required this.icon,
    required this.shortLabel,
  });

  final Color tint;
  final Color accent;
  final IconData icon;
  final String shortLabel;

  factory KsvlCategoryStyle.of(CatalogCategory category) {
    final kit = CategoryStyleKit.of(category);
    return KsvlCategoryStyle(
      tint: kit.tint,
      accent: kit.accent,
      icon: kit.icon,
      shortLabel: category.shortLabel,
    );
  }

  factory KsvlCategoryStyle.ofIndex(int styleIndex, {String shortLabel = ''}) {
    final kit = CategoryStyleKit.ofIndex(styleIndex);
    return KsvlCategoryStyle(
      tint: kit.tint,
      accent: kit.accent,
      icon: kit.icon,
      shortLabel: shortLabel,
    );
  }
}
