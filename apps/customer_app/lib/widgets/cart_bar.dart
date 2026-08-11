import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/shell_provider.dart';

/// Cart summary docked to the bottom of the storefront.
///
/// Adding the first item is the moment the shop has to acknowledge, and this
/// bar arriving *is* that acknowledgement — so it slides and fades up from the
/// bottom edge rather than blinking into existence, and unmounts the same way.
class CartBar extends StatelessWidget {
  const CartBar({super.key});

  static const double maxWidth = 640;

  @override
  Widget build(BuildContext context) {
    final hasItems = context.select<CartProvider, bool>(
      (c) => c.totalQuantity > 0,
    );

    return AnimatedSwitcher(
      duration: KsvlMotion.normal,
      switchInCurve: KsvlMotion.standard,
      switchOutCurve: KsvlMotion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: hasItems
          ? const _CartBarBody(key: ValueKey('cart-bar'))
          : const SizedBox.shrink(key: ValueKey('cart-bar-empty')),
    );
  }
}

class _CartBarBody extends StatelessWidget {
  const _CartBarBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KsvlSpace.lg,
            0,
            KsvlSpace.lg,
            KsvlSpace.md,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: CartBar.maxWidth),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  // Goes to the cart *tab* rather than raising a sheet, so the
                  // dock and the nav bar lead to the same one place.
                  onTap: () =>
                      context.read<ShellProvider>().go(ShellTab.cart),
                  borderRadius: KsvlRadius.allMd,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: k.brand,
                      borderRadius: KsvlRadius.allMd,
                      boxShadow: KsvlShadow.brandGlow(k.brand),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FreeDeliveryProgress(
                          subtotal: cart.subtotal,
                          remaining: cart.amountForFreeDelivery(),
                          threshold: catalog.freeDeliveryThreshold,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KsvlSpace.lg,
                            vertical: KsvlSpace.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: KsvlSpace.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: KsvlRadius.allXs,
                                ),
                                child: Text(
                                  '${cart.totalQuantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    height: 1.3,
                                    fontFeatures: KsvlType.tabular,
                                  ),
                                ),
                              ),
                              const SizedBox(width: KsvlSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cart.totalQuantity == 1
                                          ? '1 item in cart'
                                          : '${cart.totalQuantity} items in cart',
                                      style: text.bodySmall?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    KsvlAmount(
                                      cart.total(
                                        serviceable: catalog.serviceable,
                                      ),
                                      fontSize: 17,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'View cart',
                                style: text.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: KsvlSpace.xs),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeDeliveryProgress extends StatelessWidget {
  const _FreeDeliveryProgress({
    required this.subtotal,
    required this.remaining,
    required this.threshold,
  });

  final double subtotal;
  final double remaining;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final unlocked = remaining <= 0;
    final progress =
        (threshold <= 0 ? 1.0 : subtotal / threshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        KsvlSpace.lg,
        KsvlSpace.sm,
        KsvlSpace.lg,
        KsvlSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KsvlRadius.md),
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked
                ? Icons.check_circle_rounded
                : Icons.local_shipping_outlined,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: KsvlSpace.sm),
          Expanded(
            child: Text(
              unlocked
                  ? 'Free delivery unlocked'
                  : 'Add ${formatRupee(remaining)} more for free delivery',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: KsvlSpace.sm),
          SizedBox(
            width: 56,
            child: ClipRRect(
              borderRadius: KsvlRadius.allPill,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: KsvlMotion.slow,
                curve: KsvlMotion.standard,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.28),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
