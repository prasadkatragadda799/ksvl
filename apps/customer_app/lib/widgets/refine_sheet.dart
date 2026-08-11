import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/catalog_provider.dart';

Future<void> showRefineSheet(BuildContext context) {
  return showKsvlSheet<void>(context, builder: (_) => const RefineSheet());
}

/// Sort and narrow the grid.
///
/// Every control here writes straight through to [CatalogProvider], so the
/// grid behind the sheet updates as it is touched — a shopper can see how many
/// items a filter costs them before committing to it. There is no "Apply"
/// button for the same reason.
class RefineSheet extends StatelessWidget {
  const RefineSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final shown = catalog.products.length;
    final total = catalog.totalProductCount;

    return KsvlSheetScaffold(
      title: 'Sort & filter',
      subtitle: shown == total
          ? '$total ${total == 1 ? 'item' : 'items'} in the shop'
          : 'Showing $shown of $total items',
      heightFactor: 0.8,
      footer: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: catalog.activeRefinementCount == 0
                    ? null
                    : () => context.read<CatalogProvider>().resetRefinements(),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: KsvlSpace.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  shown == 0 ? 'Nothing matches' : 'Show $shown',
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KsvlOverline('Sort by'),
          const SizedBox(height: KsvlSpace.sm),
          for (final option in ProductSort.values)
            _SortRow(
              option: option,
              selected: catalog.sort == option,
              onTap: () => context.read<CatalogProvider>().setSort(option),
            ),
          const SizedBox(height: KsvlSpace.xl),

          const KsvlOverline('Category'),
          const SizedBox(height: KsvlSpace.sm),
          KsvlFilterChips.categories(
            categories: catalog.categories,
            selectedId: catalog.selectedCategoryId,
            onSelected: context.read<CatalogProvider>().setCategory,
            counts: catalog.categoryCounts,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: KsvlSpace.xl),

          const KsvlOverline('Show only'),
          const SizedBox(height: KsvlSpace.xs),
          _ToggleRow(
            icon: Icons.local_offer_outlined,
            title: 'On offer',
            caption: 'Items with a discount running',
            value: catalog.offersOnly,
            onChanged: context.read<CatalogProvider>().setOffersOnly,
          ),
          Divider(height: 1, color: k.border),
          _ToggleRow(
            icon: Icons.inventory_2_outlined,
            title: 'In stock',
            caption: 'Hide anything we have run out of',
            value: catalog.inStockOnly,
            onChanged: context.read<CatalogProvider>().setInStockOnly,
          ),

          if (catalog.searchQuery.trim().isNotEmpty) ...[
            const SizedBox(height: KsvlSpace.lg),
            Text(
              'Search for “${catalog.searchQuery.trim()}” is also narrowing '
              'these results.',
              style: text.bodySmall?.copyWith(color: k.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ProductSort option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KsvlSpace.sm,
              vertical: KsvlSpace.md - 2,
            ),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 18,
                  color: selected ? k.brand : k.textMuted,
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? k.textPrimary : k.textSecondary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 18, color: k.brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, size: 20, color: k.textSecondary),
      title: Text(title, style: text.titleSmall),
      subtitle: Text(
        caption,
        style: text.bodySmall?.copyWith(color: k.textMuted),
      ),
    );
  }
}
