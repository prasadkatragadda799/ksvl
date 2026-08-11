import 'package:flutter/material.dart';

import '../design/ksvl_tokens.dart';
import '../models/order.dart';
import 'ksvl_tone.dart';

/// Small status pill: tinted background, matching border, saturated label.
///
/// The tint/border/label all derive from one [KsvlTone], so a status can never
/// end up with, say, green text on an amber chip.
class KsvlBadge extends StatelessWidget {
  const KsvlBadge({
    super.key,
    required this.label,
    this.tone = KsvlTone.neutral,
    this.icon,
    this.dense = false,
    this.solid = false,
  });

  /// Badge for an order's lifecycle state.
  factory KsvlBadge.orderStatus(OrderStatus status, {bool dense = false}) {
    return KsvlBadge(
      label: status.label,
      dense: dense,
      icon: switch (status) {
        OrderStatus.pending => Icons.schedule_rounded,
        OrderStatus.inProgress => Icons.local_shipping_outlined,
        OrderStatus.completed => Icons.check_circle_outline_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
      },
      tone: switch (status) {
        OrderStatus.pending => KsvlTone.warning,
        OrderStatus.inProgress => KsvlTone.info,
        OrderStatus.completed => KsvlTone.success,
        OrderStatus.cancelled => KsvlTone.neutral,
      },
    );
  }

  /// Badge for stock availability.
  factory KsvlBadge.stock({required bool inStock, bool dense = false}) {
    return KsvlBadge(
      label: inStock ? 'In Stock' : 'Out of Stock',
      tone: inStock ? KsvlTone.success : KsvlTone.danger,
      icon: inStock
          ? Icons.check_circle_outline_rounded
          : Icons.remove_circle_outline_rounded,
      dense: dense,
    );
  }

  final String label;
  final KsvlTone tone;
  final IconData? icon;

  /// Tighter padding and 11px label, for placement inside dense rows.
  final bool dense;

  /// Filled with the saturated colour and a white label — for the one badge on
  /// a screen that has to win attention.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final colors = tone.resolve(context);
    final foreground = solid ? Colors.white : colors.foreground;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? KsvlSpace.sm : KsvlSpace.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: solid ? colors.foreground : colors.background,
        borderRadius: KsvlRadius.allPill,
        border: Border.all(
          color: solid ? Colors.transparent : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: foreground),
            const SizedBox(width: KsvlSpace.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Percentage-off flag shown over product imagery.
class KsvlDiscountFlag extends StatelessWidget {
  const KsvlDiscountFlag({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    final colors = KsvlTone.success.resolve(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KsvlSpace.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.foreground,
        borderRadius: KsvlRadius.allXs,
        boxShadow: KsvlShadow.sm,
      ),
      child: Text(
        '$percent% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
    );
  }
}
