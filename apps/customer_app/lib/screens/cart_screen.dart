import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/shell_provider.dart';
import 'package:customer_app/widgets/cart_line_tile.dart';
import 'package:customer_app/widgets/checkout_sheet.dart';
import 'package:customer_app/widgets/delivery_bar.dart';
import 'package:customer_app/widgets/location_sheet.dart';

/// The basket, as a destination rather than a drawer.
///
/// It used to be a modal sheet raised from a floating dock. A sheet is the
/// wrong container for the one screen a customer returns to repeatedly — it
/// cannot be reached from anywhere except the dock, it hides the shop behind a
/// scrim, and it loses its scroll position every time it closes.
///
/// This is also where the full [DeliveryBar] lives: the delivery answer stops
/// being background information at the moment it decides whether the checkout
/// button works.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final k = KsvlColors.of(context);
    final fee = cart.deliveryFee(serviceable: catalog.serviceable);
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        titleSpacing: KsvlSpace.lg,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Clear'),
            ),
          const SizedBox(width: KsvlSpace.sm),
        ],
      ),
      body: items.isEmpty
          ? KsvlEmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your cart is empty',
              message: 'Browse the shelves and add something you like.',
              actionLabel: 'Start shopping',
              onAction: () =>
                  context.read<ShellProvider>().go(ShellTab.home),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                    ),
                    children: [
                      KsvlPageWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DeliveryBar(
                              headline: catalog.deliveryHeadline,
                              detail: catalog.deliveryDetail,
                              blocker: catalog.blocker,
                              onTap:
                                  catalog.blocker ==
                                      StorefrontBlocker.storeClosed
                                  ? null
                                  : () => showLocationSheet(context),
                            ),
                            const SizedBox(height: KsvlSpace.md),
                            FreeDeliveryNote(
                              remaining: cart.amountForFreeDelivery(),
                            ),
                            const SizedBox(height: KsvlSpace.lg),
                            for (final item in items)
                              CartLineTile(
                                key: ValueKey(item.key),
                                item: item,
                                onRemove: () => cart.remove(
                                  item.product.id,
                                  item.variant.id,
                                ),
                                onDecrement: () => cart.decrement(
                                  item.product.id,
                                  item.variant.id,
                                ),
                                onIncrement: () => cart.increment(
                                  item.product.id,
                                  item.variant.id,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _CheckoutFooter(
                  subtotal: cart.subtotal,
                  fee: fee,
                  total: cart.total(serviceable: catalog.serviceable),
                  serviceable: catalog.serviceable,
                  border: k.border,
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty the cart?'),
        content: const Text('Every item will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep them'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KsvlColors.of(ctx).danger,
            ),
            child: const Text('Empty cart'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<CartProvider>().clear();
  }
}

/// Totals and the checkout button, docked so they never scroll out of reach.
class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.subtotal,
    required this.fee,
    required this.total,
    required this.serviceable,
    required this.border,
  });

  final double subtotal;
  final double fee;
  final double total;
  final bool serviceable;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shadowColor: KsvlColors.of(context).shadow.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KsvlSpace.lg,
            KsvlSpace.md,
            KsvlSpace.lg,
            KsvlSpace.md,
          ),
          child: KsvlPageWidth(
            maxWidth: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CartSummaryRow(
                  label: 'Item total',
                  value: formatRupee(subtotal),
                ),
                const SizedBox(height: KsvlSpace.sm),
                CartSummaryRow(
                  label: 'Delivery',
                  value: fee == 0 ? 'FREE' : formatRupee(fee),
                  highlight: fee == 0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KsvlSpace.md),
                  child: Divider(height: 1, color: border),
                ),
                CartSummaryRow(
                  label: 'To pay',
                  value: formatRupee(total),
                  bold: true,
                ),
                const SizedBox(height: KsvlSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !serviceable
                        ? null
                        : () => showCheckoutSheet(context),
                    child: Text(
                      serviceable
                          ? 'Proceed to checkout'
                          : 'Delivery unavailable here',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
