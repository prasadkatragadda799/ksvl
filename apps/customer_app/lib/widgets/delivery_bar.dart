import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

import 'package:customer_app/providers/catalog_provider.dart';

/// Tone and glyph for a given blocker, shared by both presentations below so
/// the compact line and the full bar can never disagree about severity.
///
/// A first-time visitor who simply has not set a location yet has done nothing
/// wrong, so that state is brand-coloured, not red. Red is reserved for a
/// location we genuinely cannot serve.
KsvlTone deliveryTone(StorefrontBlocker blocker) => switch (blocker) {
      StorefrontBlocker.none => KsvlTone.success,
      StorefrontBlocker.noLocation => KsvlTone.brand,
      StorefrontBlocker.outOfZone => KsvlTone.danger,
      StorefrontBlocker.storeClosed => KsvlTone.warning,
    };

IconData deliveryIcon(StorefrontBlocker blocker) => switch (blocker) {
      StorefrontBlocker.none => Icons.local_shipping_outlined,
      StorefrontBlocker.noLocation => Icons.pin_drop_outlined,
      StorefrontBlocker.outOfZone => Icons.wrong_location_outlined,
      StorefrontBlocker.storeClosed => Icons.bedtime_outlined,
    };

/// The delivery answer as a single line, sized to sit directly under the shop
/// name in the header.
///
/// This replaces a full-width card that cost roughly 70px of every phone
/// viewport — on a 360x780 screen that is a tenth of the shop, spent restating
/// something the customer resolves once. The line keeps the same colour
/// language, stays permanently visible because the header is pinned (so an
/// unserviceable location can no longer be scrolled past), and hands the
/// detail sentence to the sheet that can actually act on it.
class DeliveryPill extends StatelessWidget {
  const DeliveryPill({
    super.key,
    required this.headline,
    required this.detail,
    required this.blocker,
    this.onTap,
  });

  final String headline;
  final String detail;
  final StorefrontBlocker blocker;
  final VoidCallback? onTap;

  /// Short enough to survive a 360px viewport beside the shop name.
  String get _label => switch (blocker) {
        StorefrontBlocker.none => headline,
        StorefrontBlocker.noLocation => 'Set delivery location',
        StorefrontBlocker.outOfZone => 'Outside delivery area',
        StorefrontBlocker.storeClosed => 'Store closed right now',
      };

  @override
  Widget build(BuildContext context) {
    final colors = deliveryTone(blocker).resolve(context);
    final interactive = onTap != null;

    return Semantics(
      button: interactive,
      label: '$_label. $detail',
      excludeSemantics: true,
      child: Tooltip(
        message: detail,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: KsvlRadius.allPill,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(KsvlSpace.sm, 3, 6, 3),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: KsvlRadius.allPill,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    deliveryIcon(blocker),
                    size: 13,
                    color: colors.foreground,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  if (interactive)
                    Icon(
                      Icons.expand_more_rounded,
                      size: 15,
                      color: colors.foreground,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The delivery answer in full: headline, the promise or the problem, and the
/// way to change it.
///
/// The storefront header only has room for [DeliveryPill], so this lives where
/// the answer is about to cost money — the cart, right above checkout.
class DeliveryBar extends StatelessWidget {
  const DeliveryBar({
    super.key,
    required this.headline,
    required this.detail,
    required this.blocker,
    this.onTap,
  });

  final String headline;
  final String detail;
  final StorefrontBlocker blocker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = deliveryTone(blocker).resolve(context);
    final text = Theme.of(context).textTheme;
    final interactive = onTap != null;

    return Semantics(
      button: interactive,
      label: '$headline. $detail',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allMd,
          child: Ink(
            padding: const EdgeInsets.all(KsvlSpace.md),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: KsvlRadius.allMd,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.foreground.withValues(alpha: 0.12),
                    borderRadius: KsvlRadius.allSm,
                  ),
                  child: Icon(
                    deliveryIcon(blocker),
                    size: 19,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: colors.foreground.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                if (interactive) ...[
                  const SizedBox(width: KsvlSpace.sm),
                  Text(
                    blocker == StorefrontBlocker.none ? 'Change' : 'Set',
                    style: text.labelMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.foreground,
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
