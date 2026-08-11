import 'package:flutter/material.dart';

import '../design/ksvl_palette.dart';

/// Admin-managed store category. New ones appear on the customer app
/// automatically via [AppCatalog] — no frontend code change required.
@immutable
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.shortLabel,
    this.styleIndex = 0,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Compact chip label (can match [name] for short names).
  final String shortLabel;

  /// Picks icon + tint from the shared style palette (wraps by length).
  final int styleIndex;

  /// Inactive categories stay in admin history but hide from the storefront.
  final bool isActive;

  CatalogCategory copyWith({
    String? id,
    String? name,
    String? shortLabel,
    int? styleIndex,
    bool? isActive,
  }) {
    return CatalogCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      shortLabel: shortLabel ?? this.shortLabel,
      styleIndex: styleIndex ?? this.styleIndex,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortLabel': shortLabel,
        'styleIndex': styleIndex,
        'isActive': isActive,
      };

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      shortLabel: json['shortLabel'] as String? ?? '',
      styleIndex: (json['styleIndex'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Visual kit for a category — indexed so newly added categories still look
/// intentional without shipping new frontend styles.
class CategoryStyleKit {
  const CategoryStyleKit({
    required this.tint,
    required this.accent,
    required this.icon,
  });

  final Color tint;
  final Color accent;
  final IconData icon;

  static const List<CategoryStyleKit> palette = [
    CategoryStyleKit(
      tint: KsvlPalette.gold100,
      accent: KsvlPalette.gold500,
      icon: Icons.spa_outlined,
    ),
    CategoryStyleKit(
      tint: KsvlPalette.red100,
      accent: KsvlPalette.red500,
      icon: Icons.local_fire_department_outlined,
    ),
    CategoryStyleKit(
      tint: KsvlPalette.plum100,
      accent: KsvlPalette.plum500,
      icon: Icons.eco_outlined,
    ),
    CategoryStyleKit(
      tint: KsvlPalette.clay100,
      accent: KsvlPalette.clay500,
      icon: Icons.bakery_dining_outlined,
    ),
    CategoryStyleKit(
      tint: KsvlPalette.brand50,
      accent: KsvlPalette.brand500,
      icon: Icons.blender_outlined,
    ),
    CategoryStyleKit(
      tint: Color(0xFFE8F5E9),
      accent: Color(0xFF2E7D32),
      icon: Icons.grass_outlined,
    ),
    CategoryStyleKit(
      tint: Color(0xFFE3F2FD),
      accent: Color(0xFF1565C0),
      icon: Icons.water_drop_outlined,
    ),
    CategoryStyleKit(
      tint: Color(0xFFFFF3E0),
      accent: Color(0xFFEF6C00),
      icon: Icons.cookie_outlined,
    ),
  ];

  static CategoryStyleKit ofIndex(int index) {
    if (palette.isEmpty) {
      return const CategoryStyleKit(
        tint: KsvlPalette.brand50,
        accent: KsvlPalette.brand500,
        icon: Icons.category_outlined,
      );
    }
    final i = index % palette.length;
    return palette[i < 0 ? 0 : i];
  }

  static CategoryStyleKit of(CatalogCategory category) =>
      ofIndex(category.styleIndex);
}
