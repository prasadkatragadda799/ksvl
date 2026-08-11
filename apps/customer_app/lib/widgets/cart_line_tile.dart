import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

import 'package:customer_app/models/cart_item.dart';

/// One basket line: thumbnail, what it is, quantity control, line total.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: KsvlSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KsvlProductThumb(
            emoji: item.product.imageEmoji,
            imageUrl: item.product.imageUrl,
            styleIndex: item.product.categoryStyleIndex,
            size: 52,
            glyphSize: 26,
            animate: false,
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
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 24,
                      child: IconButton(
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove ${item.product.name}',
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: k.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.variant.title} · ${formatRupee(item.unitPrice)} each',
                  style: text.bodySmall,
                ),
                const SizedBox(height: KsvlSpace.sm),
                Row(
                  children: [
                    KsvlQuantityStepper(
                      quantity: item.quantity,
                      height: 34,
                      style: KsvlStepperStyle.outlined,
                      label: item.product.name,
                      onDecrement: onDecrement,
                      onIncrement: onIncrement,
                    ),
                    const Spacer(),
                    KsvlAmount(item.lineTotal, fontSize: 15),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A label and a figure on one line — item total, delivery, to pay.
class CartSummaryRow extends StatelessWidget {
  const CartSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          label,
          style: bold
              ? text.titleMedium
              : text.bodyMedium?.copyWith(color: k.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            height: 1.2,
            color: highlight ? k.success : k.textPrimary,
            fontFeatures: KsvlType.tabular,
          ),
        ),
      ],
    );
  }
}

/// The free-delivery nudge that sits above the lines.
class FreeDeliveryNote extends StatelessWidget {
  const FreeDeliveryNote({super.key, required this.remaining});

  /// Rupees still needed to cross the threshold. Zero means unlocked.
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final pending = remaining > 0;

    return Container(
      padding: const EdgeInsets.all(KsvlSpace.md),
      decoration: BoxDecoration(
        color: pending ? k.surfaceSubtle : k.successSoft,
        borderRadius: KsvlRadius.allSm,
        border: Border.all(
          color: pending ? k.border : k.success.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            pending
                ? Icons.local_shipping_outlined
                : Icons.celebration_outlined,
            size: 18,
            color: pending ? k.textSecondary : k.success,
          ),
          const SizedBox(width: KsvlSpace.sm),
          Expanded(
            child: Text(
              pending
                  ? 'Add ${formatRupee(remaining)} more to get free delivery'
                  : 'You’ve unlocked free delivery',
              style: text.labelMedium?.copyWith(
                color: pending ? k.textSecondary : k.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
