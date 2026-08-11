import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';
import '../models/catalog_category.dart';
import 'ksvl_category_style.dart';

/// One selectable filter.
@immutable
class KsvlFilterOption<T> {
  const KsvlFilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? count;
}

/// Horizontally scrolling filter row driven by live category data.
class KsvlFilterChips<T> extends StatelessWidget {
  const KsvlFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: KsvlSpace.lg),
    this.height = 40,
  });

  /// Builds chips from whatever categories the admin has configured.
  static KsvlFilterChips<String?> categories({
    Key? key,
    required List<CatalogCategory> categories,
    required String? selectedId,
    required ValueChanged<String?> onSelected,
    Map<String, int>? counts,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: KsvlSpace.lg),
  }) {
    final active = categories.where((c) => c.isActive).toList();
    return KsvlFilterChips<String?>(
      key: key,
      selected: selectedId,
      onSelected: onSelected,
      padding: padding,
      options: [
        const KsvlFilterOption<String?>(
          value: null,
          label: 'All',
          icon: Icons.grid_view_rounded,
        ),
        for (final category in active)
          KsvlFilterOption<String?>(
            value: category.id,
            label: category.shortLabel,
            icon: KsvlCategoryStyle.of(category).icon,
            count: counts?[category.id],
          ),
      ],
    );
  }

  final List<KsvlFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, _) => const SizedBox(width: KsvlSpace.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          return _Chip(
            option: option,
            isSelected: option.value == selected,
            onTap: () => onSelected(option.value),
          );
        },
      ),
    );
  }
}

class _Chip<T> extends StatelessWidget {
  const _Chip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final KsvlFilterOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final foreground = isSelected ? Colors.white : k.textSecondary;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allPill,
          child: AnimatedContainer(
            duration: KsvlMotion.fast,
            curve: KsvlMotion.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: KsvlSpace.lg,
              vertical: KsvlSpace.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? k.brand
                  : Theme.of(context).colorScheme.surface,
              borderRadius: KsvlRadius.allPill,
              border: Border.all(
                color: isSelected ? k.brand : k.border,
              ),
              boxShadow: isSelected ? KsvlShadow.sm : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 15, color: foreground),
                  const SizedBox(width: KsvlSpace.xs + 2),
                ],
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: foreground,
                  ),
                ),
                if (option.count != null) ...[
                  const SizedBox(width: KsvlSpace.sm - 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : k.surfaceSubtle,
                      borderRadius: KsvlRadius.allPill,
                    ),
                    child: Text(
                      '${option.count}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: isSelected ? Colors.white : k.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
