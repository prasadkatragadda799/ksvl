import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/catalog_provider.dart';

/// Opens the full product view.
Future<void> showProductDetailSheet(
  BuildContext context, {
  required Product product,
  required ProductVariant initialVariant,
}) {
  return showKsvlSheet<void>(
    context,
    builder: (_) => ProductDetailSheet(
      product: product,
      initialVariant: initialVariant,
    ),
  );
}

/// Everything about one product: description, every size with its own price,
/// and the add-to-cart control.
///
/// The grid card can only show a name and a price; this is where a customer
/// actually decides. Its absence was the biggest gap in the storefront.
class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.initialVariant,
  });

  final Product product;
  final ProductVariant initialVariant;

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  late ProductVariant _selected = widget.initialVariant;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final quantity = cart.quantityFor(product.id, _selected.id);
    final available = product.isAvailable && _selected.isAvailable;
    final saving = _selected.regularPrice - _selected.specialPrice;

    return KsvlSheetScaffold(
      title: product.name,
      subtitle: product.categoryLabel,
      leading: KsvlProductThumb(
        emoji: product.imageEmoji,
        imageUrl: product.imageUrl,
        styleIndex: product.categoryStyleIndex,
        size: 46,
        glyphSize: 24,
        animate: false,
      ),
      footer: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selected.title, style: text.bodySmall),
                  KsvlPriceText(
                    regularPrice: _selected.regularPrice,
                    specialPrice: _selected.specialPrice,
                    size: KsvlPriceSize.large,
                  ),
                ],
              ),
            ),
            const SizedBox(width: KsvlSpace.lg),
            Expanded(
              child: SizedBox(
                height: 50,
                child: !available
                    ? OutlinedButton(
                        onPressed: null,
                        child: const Text('Out of stock'),
                      )
                    : quantity == 0
                        ? ElevatedButton.icon(
                            onPressed: () => cart.add(product, _selected),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                            ),
                            label: const Text('Add to cart'),
                          )
                        : KsvlQuantityStepper(
                            quantity: quantity,
                            height: 50,
                            expand: true,
                            label: product.name,
                            onDecrement: () =>
                                cart.decrement(product.id, _selected.id),
                            onIncrement: () =>
                                cart.increment(product.id, _selected.id),
                          ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                Positioned.fill(
                  child: KsvlProductThumb(
                    emoji: product.imageEmoji,
                    imageUrl: product.imageUrl,
                    styleIndex: product.categoryStyleIndex,
                    radius: KsvlRadius.md,
                    glyphSize: 84,
                  ),
                ),
                if (product.isFeatured)
                  Positioned(
                    top: KsvlSpace.md,
                    right: KsvlSpace.md,
                    child: KsvlBadge(
                      label: 'Featured',
                      tone: KsvlTone.brand,
                      icon: Icons.star_rounded,
                      dense: true,
                    ),
                  ),
                if (saving > 0 && available)
                  Positioned(
                    top: KsvlSpace.md,
                    left: KsvlSpace.md,
                    child: KsvlDiscountFlag(
                      percent: discountPercent(
                        _selected.regularPrice,
                        _selected.specialPrice,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: KsvlSpace.lg),
          Text(product.description, style: text.bodyMedium),
          if (product.vitamins.isNotEmpty) ...[
            const SizedBox(height: KsvlSpace.md),
            const KsvlOverline('Vitamins & highlights'),
            const SizedBox(height: KsvlSpace.sm),
            KsvlVitaminChips(vitamins: product.vitamins),
          ],
          const SizedBox(height: KsvlSpace.xl),
          const KsvlOverline('Choose a size'),
          const SizedBox(height: KsvlSpace.md),
          for (final variant in product.variants)
            _VariantRow(
              variant: variant,
              selected: variant.id == _selected.id,
              onTap: variant.isAvailable
                  ? () => setState(() => _selected = variant)
                  : null,
            ),
          if (saving > 0 && available) ...[
            const SizedBox(height: KsvlSpace.xs),
            Container(
              padding: const EdgeInsets.all(KsvlSpace.md),
              decoration: BoxDecoration(
                color: k.successSoft,
                borderRadius: KsvlRadius.allSm,
                border: Border.all(color: k.success.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings_outlined, size: 18, color: k.success),
                  const SizedBox(width: KsvlSpace.sm),
                  Text(
                    'You save ${formatRupee(saving)} on this size',
                    style: text.labelMedium?.copyWith(color: k.success),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: KsvlSpace.lg),
          Container(
            padding: const EdgeInsets.all(KsvlSpace.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: KsvlRadius.allSm,
              border: Border.all(color: k.border),
            ),
            child: Row(
              children: [
                Icon(
                  catalog.serviceable
                      ? Icons.local_shipping_outlined
                      : Icons.location_off_outlined,
                  size: 18,
                  color: catalog.serviceable ? k.textSecondary : k.danger,
                ),
                const SizedBox(width: KsvlSpace.sm),
                Expanded(
                  child: Text(
                    catalog.serviceable
                        ? 'Inside ${catalog.storeLocation.radiusKm.toStringAsFixed(0)} km zone · free over '
                            '${formatRupee(catalog.freeDeliveryThreshold)}'
                        : 'Set a location within '
                            '${catalog.storeLocation.radiusKm.toStringAsFixed(0)} km to order',
                    style: text.bodySmall?.copyWith(
                      color: catalog.serviceable ? k.textSecondary : k.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ProductVariant variant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final disabled = onTap == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: KsvlSpace.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allSm,
          child: AnimatedContainer(
            duration: KsvlMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: KsvlSpace.lg,
              vertical: KsvlSpace.md,
            ),
            decoration: BoxDecoration(
              color: selected ? k.brandSoft : Colors.transparent,
              borderRadius: KsvlRadius.allSm,
              border: Border.all(
                color: selected ? k.brand : k.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 19,
                  color: disabled
                      ? k.textDisabled
                      : selected
                          ? k.brand
                          : k.borderStrong,
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: Text(
                    variant.title,
                    style: text.titleSmall?.copyWith(
                      color: disabled ? k.textDisabled : k.textPrimary,
                    ),
                  ),
                ),
                if (disabled)
                  Text(
                    'Unavailable',
                    style: text.bodySmall?.copyWith(color: k.textDisabled),
                  )
                else
                  KsvlPriceText(
                    regularPrice: variant.regularPrice,
                    specialPrice: variant.specialPrice,
                    size: KsvlPriceSize.small,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
