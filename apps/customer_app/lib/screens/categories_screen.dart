import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/shell_provider.dart';

/// The whole shop laid out as shelves.
///
/// The home tab's chip rail is a filter you scroll past; this is the map. It
/// exists because a chip rail only shows three or four categories at a phone
/// width, so anything the shop adds beyond that is effectively hidden.
///
/// Picking a shelf sets the filter and hands the customer back to the grid —
/// this screen never lists products itself, so there is exactly one place in
/// the app where a product can be looked at.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final categories = catalog.categories;
    final counts = catalog.categoryCounts;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= KsvlBreakpoint.desktop
        ? 4
        : width >= KsvlBreakpoint.phone
            ? 3
            : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        titleSpacing: KsvlSpace.lg,
      ),
      body: catalog.isLoading
          ? const Center(child: KsvlLoader.page())
          : categories.isEmpty
              ? const KsvlEmptyState(
                  icon: Icons.category_outlined,
                  title: 'No shelves yet',
                  message: 'The shop has not published any categories.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    KsvlSpace.lg,
                    KsvlSpace.lg,
                    KsvlSpace.lg,
                    KsvlSpace.xxxl,
                  ),
                  children: [
                    KsvlPageWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AllProductsTile(
                            total: catalog.totalProductCount,
                            onTap: () => _open(context, null),
                          ),
                          const SizedBox(height: KsvlSpace.lg),
                          const KsvlOverline('Browse by shelf'),
                          const SizedBox(height: KsvlSpace.md),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: KsvlSpace.md,
                              crossAxisSpacing: KsvlSpace.md,
                              mainAxisExtent: 124,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return _CategoryTile(
                                category: category,
                                count: counts[category.id] ?? 0,
                                onTap: () => _open(context, category.id),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  static void _open(BuildContext context, String? categoryId) {
    final catalog = context.read<CatalogProvider>();
    catalog
      ..setSearchQuery('')
      ..setCategory(categoryId);
    context.read<ShellProvider>().go(ShellTab.home);
  }
}

class _AllProductsTile extends StatelessWidget {
  const _AllProductsTile({required this.total, required this.onTap});

  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlCard(
      onTap: onTap,
      color: k.brandSoft,
      borderColor: k.brand.withValues(alpha: 0.25),
      semanticLabel: 'Show everything',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: k.brand.withValues(alpha: 0.14),
              borderRadius: KsvlRadius.allSm,
            ),
            child: Icon(Icons.grid_view_rounded, color: k.onBrandSoft),
          ),
          const SizedBox(width: KsvlSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Everything in the shop',
                  style: text.titleSmall?.copyWith(color: k.onBrandSoft),
                ),
                Text(
                  total == 1 ? '1 item' : '$total items',
                  style: text.bodySmall?.copyWith(
                    color: k.onBrandSoft.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: k.onBrandSoft),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.onTap,
  });

  final CatalogCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = KsvlCategoryStyle.of(category);
    final tint = isDark
        ? Color.alphaBlend(
            style.accent.withValues(alpha: 0.20),
            k.surfaceSubtle,
          )
        : style.tint;

    return KsvlCard(
      onTap: onTap,
      padding: const EdgeInsets.all(KsvlSpace.md),
      semanticLabel: '${category.name}, $count items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: KsvlRadius.allSm,
            ),
            child: Icon(style.icon, size: 22, color: style.accent),
          ),
          const Spacer(),
          Text(
            category.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? '1 item' : '$count items',
            style: text.bodySmall?.copyWith(color: k.textMuted),
          ),
        ],
      ),
    );
  }
}
