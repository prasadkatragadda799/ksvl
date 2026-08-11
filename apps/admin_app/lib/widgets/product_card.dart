import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// Catalogue row: identity and stock at rest, per-variant pricing on expand.
///
/// Collapsed it answers "is this sellable and roughly what does it cost";
/// expanded it becomes the pricing workbench. Keeping those two jobs in one
/// card is what lets the products screen stay a single scrollable list.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onToggleProduct,
    required this.onToggleVariant,
    required this.onEditVariant,
    required this.onEditProduct,
  });

  final Product product;
  final ValueChanged<bool> onToggleProduct;
  final void Function(String variantId, bool value) onToggleVariant;
  final void Function(ProductVariant variant) onEditVariant;
  final VoidCallback onEditProduct;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final style = KsvlCategoryStyle.ofIndex(
      product.categoryStyleIndex,
      shortLabel: product.categoryLabel,
    );
    final available = product.isAvailable;

    final prices = product.variants.map((v) => v.specialPrice).toList()..sort();
    final priceRange = prices.isEmpty
        ? '—'
        : prices.first == prices.last
            ? formatRupee(prices.first)
            : '${formatRupee(prices.first)} – ${formatRupee(prices.last)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: KsvlSpace.md),
      child: KsvlCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(KsvlSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Opacity(
                        opacity: available ? 1 : 0.45,
                        child: KsvlProductThumb(
                          emoji: product.imageEmoji,
                          imageUrl: product.imageUrl,
                          styleIndex: product.categoryStyleIndex,
                          size: 60,
                          glyphSize: 28,
                          animate: false,
                        ),
                      ),
                      if (product.isFeatured)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: k.brand,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: KsvlSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: text.titleMedium?.copyWith(
                                  color:
                                      available ? k.textPrimary : k.textMuted,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              height: 32,
                              child: IconButton(
                                onPressed: widget.onEditProduct,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit ${product.name}',
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KsvlSpace.xs),
                        Row(
                          children: [
                            Icon(style.icon, size: 13, color: k.textMuted),
                            const SizedBox(width: KsvlSpace.xs),
                            Expanded(
                              child: Text(
                                product.categoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KsvlSpace.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                priceRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: available
                                      ? k.textPrimary
                                      : k.textDisabled,
                                  fontFeatures: KsvlType.tabular,
                                ),
                              ),
                            ),
                            KsvlBadge.stock(inStock: available, dense: true),
                            const SizedBox(width: KsvlSpace.xs),
                            Transform.scale(
                              scale: 0.85,
                              child: Switch(
                                value: available,
                                onChanged: widget.onToggleProduct,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _ExpandBar(
              expanded: _expanded,
              total: product.variants.length,
              availableCount: product.availableVariantCount,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            AnimatedSize(
              duration: KsvlMotion.fast,
              curve: KsvlMotion.standard,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Column(
                      children: [
                        for (final variant in product.variants)
                          _VariantRow(
                            variant: variant,
                            onToggle: (value) =>
                                widget.onToggleVariant(variant.id, value),
                            onEdit: () => widget.onEditVariant(variant),
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandBar extends StatelessWidget {
  const _ExpandBar({
    required this.expanded,
    required this.total,
    required this.availableCount,
    required this.onTap,
  });

  final bool expanded;
  final int total;
  final int availableCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final allAvailable = availableCount == total;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: KsvlSpace.md,
            vertical: KsvlSpace.md,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: k.border)),
          ),
          child: Row(
            children: [
              Text(
                '$total ${total == 1 ? 'variant' : 'variants'}',
                style: text.labelMedium?.copyWith(color: k.textSecondary),
              ),
              const SizedBox(width: KsvlSpace.sm),
              Container(width: 3, height: 3, decoration: BoxDecoration(
                color: k.textDisabled,
                shape: BoxShape.circle,
              )),
              const SizedBox(width: KsvlSpace.sm),
              Text(
                allAvailable
                    ? 'all available'
                    : '$availableCount of $total available',
                style: text.bodySmall?.copyWith(
                  color: allAvailable ? k.textMuted : k.warning,
                  fontWeight: allAvailable ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                expanded ? 'Hide' : 'Manage',
                style: text.labelMedium?.copyWith(
                  color: k.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: KsvlMotion.fast,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: k.brand,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.onToggle,
    required this.onEdit,
  });

  final ProductVariant variant;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final on = variant.isAvailable;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        KsvlSpace.md,
        KsvlSpace.sm,
        KsvlSpace.sm,
        KsvlSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: k.border)),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 54),
            padding: const EdgeInsets.symmetric(
              horizontal: KsvlSpace.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: KsvlRadius.allXs,
              border: Border.all(color: k.border),
            ),
            alignment: Alignment.center,
            child: Text(
              variant.title,
              style: text.labelMedium?.copyWith(
                color: on ? k.textPrimary : k.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: KsvlSpace.md),
          Expanded(
            child: Opacity(
              opacity: on ? 1 : 0.5,
              child: KsvlPriceText(
                regularPrice: variant.regularPrice,
                specialPrice: variant.specialPrice,
                size: KsvlPriceSize.small,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.tune_rounded, size: 18),
            color: k.brand,
            tooltip: 'Edit ${variant.title} pricing',
            visualDensity: VisualDensity.compact,
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: on,
              onChanged: onToggle,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
