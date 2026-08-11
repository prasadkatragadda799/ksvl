import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/wishlist_provider.dart';
import 'package:customer_app/widgets/product_detail_sheet.dart';

/// Storefront product tile.
///
/// Sections have fixed heights on purpose: in a grid, a card whose price row
/// shifts because one name wrapped to two lines makes the whole page look
/// unaligned. The image area is the only flexible part.
///
/// Reading order matches how someone actually decides — picture, what it is,
/// how much you get, what it costs, buy — and the buy control is the only
/// filled element on the card, so a grid of ten never has ten things shouting.
class StoreProductCard extends StatefulWidget {
  const StoreProductCard({
    super.key,
    required this.product,
    this.imageHeight = 112,
  });

  final Product product;
  final double imageHeight;

  /// Fixed vertical cost of everything below the image: card padding, the
  /// two-line name, the quality line, the size row, the price and the action
  /// button.
  ///
  /// Vitamin chips used to sit here, between the name and the price. On a
  /// two-column phone card that put decorative metadata directly in the path
  /// of the only two facts a shopper decides on, so they now live on the
  /// detail sheet where the decision is actually made.
  static const double _chromeHeight = 182;

  /// Height a grid cell must give this card, given its image height.
  ///
  /// The image is the flexible part, so a cell that is a few pixels off still
  /// lays out cleanly instead of overflowing.
  static double extentFor(double imageHeight) => imageHeight + _chromeHeight;

  @override
  State<StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<StoreProductCard> {
  late ProductVariant _selected = _defaultVariant(widget.product);

  @override
  void didUpdateWidget(covariant StoreProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _selected = _defaultVariant(widget.product);
    }
  }

  static ProductVariant _defaultVariant(Product product) {
    return product.variants.firstWhere(
      (v) => v.isAvailable,
      orElse: () => product.variants.first,
    );
  }

  /// One short line under the name. The admin's own description wins; the
  /// category is the fallback, so the slot is never blank and never invented.
  static String _subtitleFor(Product product) {
    final description = product.description.trim();
    if (description.isNotEmpty) {
      final firstClause = description.split(RegExp(r'[.\n]')).first.trim();
      if (firstClause.isNotEmpty) return firstClause;
    }
    final category = product.categoryLabel.trim();
    return category.isNotEmpty ? category : 'Premium quality';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final cart = context.watch<CartProvider>();
    final quantity = cart.quantityFor(product.id, _selected.id);
    final available = product.isAvailable && _selected.isAvailable;
    final percent = discountPercent(
      _selected.regularPrice,
      _selected.specialPrice,
    );

    return KsvlCard(
      padding: const EdgeInsets.all(KsvlSpace.md),
      onTap: () => showProductDetailSheet(
        context,
        product: product,
        initialVariant: _selected,
      ),
      semanticLabel: product.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: available ? 1 : 0.4,
                      child: KsvlProductThumb(
                        emoji: product.imageEmoji,
                        imageUrl: product.imageUrl,
                        styleIndex: product.categoryStyleIndex,
                      ),
                    ),
                  ),
                  if (percent > 0 && available)
                    Positioned(
                      top: KsvlSpace.sm,
                      left: KsvlSpace.sm,
                      child: KsvlDiscountFlag(percent: percent),
                    ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _WishlistButton(product: product),
                  ),
                  if (product.isFeatured && available)
                    Positioned(
                      left: KsvlSpace.sm,
                      bottom: KsvlSpace.sm,
                      child: const _BestsellerFlag(),
                    ),
                  if (!available)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KsvlSpace.md,
                            vertical: KsvlSpace.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: KsvlRadius.allPill,
                            border: Border.all(
                              color: k.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Out of stock',
                            style: text.labelSmall?.copyWith(
                              color: k.danger,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KsvlSpace.md),
          SizedBox(
            height: 36,
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(height: 1.28),
            ),
          ),
          SizedBox(
            height: 13,
            child: Text(
              _subtitleFor(product),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: k.textMuted,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            // A lone size is a fact, not a choice. Rendering it as a chip that
            // looks identical to a selectable one invites a tap that does
            // nothing, so a single-variant product states its weight plainly —
            // and the space that buys is where the sourcing promise goes. A
            // product with real sizes to pick from needs the whole row.
            child: product.variants.length == 1
                ? Row(
                    children: [
                      Text(
                        _selected.title,
                        style: text.bodySmall?.copyWith(
                          color: k.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const _NaturalMark(),
                    ],
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.variants.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: KsvlSpace.xs),
                    itemBuilder: (context, index) {
                      final variant = product.variants[index];
                      return _VariantChip(
                        variant: variant,
                        selected: variant.id == _selected.id,
                        onTap: variant.isAvailable
                            ? () => setState(() => _selected = variant)
                            : null,
                      );
                    },
                  ),
          ),
          const SizedBox(height: KsvlSpace.xs),
          SizedBox(
            height: 21,
            child: Align(
              alignment: Alignment.centerLeft,
              child: KsvlPriceText(
                regularPrice: _selected.regularPrice,
                specialPrice: _selected.specialPrice,
                size: KsvlPriceSize.small,
              ),
            ),
          ),
          const SizedBox(height: KsvlSpace.sm),
          SizedBox(
            height: 38,
            width: double.infinity,
            // No AnimatedSwitcher here — stacking the outgoing Add button with
            // StackFit.expand left a ghost outlined rectangle over the stepper.
            child: !available
                ? const _UnavailableAction()
                : quantity == 0
                    ? ElevatedButton.icon(
                        onPressed: () {
                          cart.add(product, _selected);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(double.infinity, 38),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 16,
                        ),
                        label: const Text('Add to Cart'),
                      )
                    : KsvlQuantityStepper(
                        quantity: quantity,
                        height: 38,
                        expand: true,
                        label: product.name,
                        onDecrement: () =>
                            cart.decrement(product.id, _selected.id),
                        onIncrement: () =>
                            cart.increment(product.id, _selected.id),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Save-for-later toggle, floated over the product photo.
///
/// It sits on its own opaque disc rather than directly on the image, because a
/// bare outline heart disappears entirely over a light-coloured cashew.
class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final saved = context.select<WishlistProvider, bool>(
      (w) => w.contains(product.id),
    );

    return Tooltip(
      message: saved ? 'Saved' : 'Save for later',
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shadowColor: k.shadow.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            final added = context.read<WishlistProvider>().toggle(product.id);
            final messenger = ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                content: Text(
                  added
                      ? '${product.name} saved for later'
                      : '${product.name} removed from saved',
                ),
              ),
            );
          },
          child: SizedBox.square(
            dimension: 28,
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 15,
              color: saved ? k.danger : k.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks the shop's own picks. It sits at the bottom of the photo so the top
/// corners stay reserved for the two controls a customer acts on.
class _BestsellerFlag extends StatelessWidget {
  const _BestsellerFlag();

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: KsvlRadius.allPill,
        border: Border.all(color: k.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 11, color: k.warning),
          const SizedBox(width: 3),
          Text(
            'Bestseller',
            style: TextStyle(
              fontSize: 9.5,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: k.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NaturalMark extends StatelessWidget {
  const _NaturalMark();

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_outlined, size: 12, color: k.success),
        const SizedBox(width: 3),
        Text(
          '100% Natural',
          style: TextStyle(
            fontSize: 9.5,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: k.success,
          ),
        ),
      ],
    );
  }
}

/// Placeholder shown while the catalogue streams in.
///
/// It is built from the same [StoreProductCard.extentFor] geometry as the real
/// card and mirrors its internal rhythm, so the grid does not reflow the moment
/// data lands — a skeleton that jumps on load is worse than no skeleton.
class StoreProductCardSkeleton extends StatelessWidget {
  const StoreProductCardSkeleton({super.key, this.imageHeight = 124});

  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return KsvlCard(
      padding: const EdgeInsets.all(KsvlSpace.md),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: KsvlSkeleton(
              width: double.infinity,
              height: double.infinity,
              radius: KsvlRadius.sm,
            ),
          ),
          SizedBox(height: KsvlSpace.md),
          SizedBox(
            height: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KsvlSkeleton(height: 13, width: double.infinity),
                SizedBox(height: KsvlSpace.sm),
                KsvlSkeleton(height: 13, width: 78),
              ],
            ),
          ),
          SizedBox(
            height: 13,
            child: Align(
              alignment: Alignment.centerLeft,
              child: KsvlSkeleton(height: 10, width: 62),
            ),
          ),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: KsvlSkeleton(height: 12, width: 44),
            ),
          ),
          SizedBox(height: KsvlSpace.xs),
          SizedBox(
            height: 21,
            child: Align(
              alignment: Alignment.centerLeft,
              child: KsvlSkeleton(height: 18, width: 88),
            ),
          ),
          SizedBox(height: KsvlSpace.sm),
          KsvlSkeleton(
            height: 38,
            width: double.infinity,
            radius: KsvlRadius.sm,
          ),
        ],
      ),
    );
  }
}

class _UnavailableAction extends StatelessWidget {
  const _UnavailableAction();

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: k.surfaceSubtle,
        borderRadius: KsvlRadius.allSm,
      ),
      child: Text(
        'Notify when back',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: k.textMuted),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
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
    final disabled = onTap == null;

    return Semantics(
      selected: selected,
      button: !disabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allXs,
          child: AnimatedContainer(
            duration: KsvlMotion.instant,
            // Tight enough that three sizes fit a phone-width card without the
            // last chip being clipped by the card edge.
            padding: const EdgeInsets.symmetric(horizontal: KsvlSpace.sm - 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? k.brandSoft : Colors.transparent,
              borderRadius: KsvlRadius.allXs,
              border: Border.all(
                color: selected ? k.brand : k.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Text(
              variant.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: disabled
                    ? k.textDisabled
                    : selected
                    ? k.onBrandSoft
                    : k.textSecondary,
                decoration: disabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
