import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

import '../providers/order_provider.dart';

/// A full order, packing-slip style.
///
/// The layout follows the order in which the shop actually uses it: who and
/// where first, then what to pack, then what to collect, then the one button
/// that moves the order forward.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onCancel,
    this.compact = false,
    this.onTap,
  });

  final Order order;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onCancel;

  /// Summary form for the dashboard: header, total and status only.
  final bool compact;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final primaryLabel = OrderProvider.nextActionLabel(order.status);
    final secondaryLabel = OrderProvider.secondaryActionLabel(order.status);
    final itemCount = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? KsvlSpace.sm : KsvlSpace.md),
      child: KsvlCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(KsvlSpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id}',
                          style: text.titleMedium?.copyWith(
                            fontFeatures: KsvlType.tabular,
                          ),
                        ),
                        const SizedBox(height: KsvlSpace.xxs),
                        Text(
                          '${_relativeDay(order.createdAt)} · '
                          '${_time(order.createdAt)} · '
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  KsvlBadge.orderStatus(order.status, dense: true),
                ],
              ),
            ),
            if (compact) ...[
              Divider(height: 1, color: k.border),
              Padding(
                padding: const EdgeInsets.all(KsvlSpace.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: k.textMuted,
                    ),
                    const SizedBox(width: KsvlSpace.sm),
                    Expanded(
                      child: Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: k.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    KsvlAmount(order.totalAmount, color: k.brand),
                  ],
                ),
              ),
            ] else ...[
              Divider(height: 1, color: k.border),
              Padding(
                padding: const EdgeInsets.all(KsvlSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KsvlOverline('Deliver to'),
                    const SizedBox(height: KsvlSpace.sm),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      value: order.customerName,
                      emphasise: true,
                    ),
                    const SizedBox(height: KsvlSpace.sm),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      value: order.phone,
                      trailing: _CopyButton(
                        value: order.phone,
                        label: 'phone number',
                      ),
                    ),
                    const SizedBox(height: KsvlSpace.sm),
                    _InfoRow(
                      icon: Icons.home_outlined,
                      value: order.address,
                    ),
                    const SizedBox(height: KsvlSpace.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KsvlSpace.md,
                        vertical: KsvlSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: k.infoSoft,
                        borderRadius: KsvlRadius.allXs,
                        border: Border.all(
                          color: k.info.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: k.info,
                          ),
                          const SizedBox(width: KsvlSpace.sm),
                          Expanded(
                            child: Text(
                              '${order.locationTag} · PIN ${order.pincode}',
                              style: text.labelMedium?.copyWith(
                                color: k.info,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KsvlSpace.xl),
                    const KsvlOverline('Items to pack'),
                    const SizedBox(height: KsvlSpace.sm),
                    for (final item in order.items) _ItemRow(item: item),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(
                  KsvlSpace.lg,
                  0,
                  KsvlSpace.lg,
                  KsvlSpace.lg,
                ),
                padding: const EdgeInsets.all(KsvlSpace.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: KsvlRadius.allSm,
                  border: Border.all(color: k.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total amount', style: text.bodySmall),
                          const SizedBox(height: KsvlSpace.xxs),
                          KsvlAmount(
                            order.totalAmount,
                            fontSize: 20,
                            color: k.brand,
                          ),
                        ],
                      ),
                    ),
                    KsvlBadge(
                      label: order.paymentType == PaymentType.cod
                          ? 'Cash on delivery'
                          : 'Paid online',
                      tone: order.paymentType == PaymentType.cod
                          ? KsvlTone.warning
                          : KsvlTone.success,
                      icon: order.paymentType == PaymentType.cod
                          ? Icons.payments_outlined
                          : Icons.credit_card_rounded,
                      dense: true,
                    ),
                  ],
                ),
              ),
              if (order.receiptUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KsvlSpace.lg,
                    0,
                    KsvlSpace.lg,
                    KsvlSpace.lg,
                  ),
                  child: InkWell(
                    borderRadius: KsvlRadius.allSm,
                    onTap: () => _showReceipt(context, order.receiptUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KsvlSpace.md,
                        vertical: KsvlSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: k.successSoft,
                        borderRadius: KsvlRadius.allSm,
                        border: Border.all(
                          color: k.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 17, color: k.success),
                          const SizedBox(width: KsvlSpace.sm),
                          Expanded(
                            child: Text(
                              'View payment receipt',
                              style: text.labelMedium?.copyWith(
                                color: k.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.open_in_new_rounded,
                              size: 15, color: k.success),
                        ],
                      ),
                    ),
                  ),
                ),
              if (primaryLabel != null || secondaryLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KsvlSpace.lg,
                    0,
                    KsvlSpace.lg,
                    KsvlSpace.lg,
                  ),
                  child: Row(
                    children: [
                      if (secondaryLabel != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: order.status == OrderStatus.pending
                                ? onCancel
                                : onSecondaryAction,
                            style: order.status == OrderStatus.pending
                                ? OutlinedButton.styleFrom(
                                    foregroundColor: k.danger,
                                    side: BorderSide(
                                      color: k.danger.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                  )
                                : null,
                            child: Text(
                              secondaryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (secondaryLabel != null && primaryLabel != null)
                        const SizedBox(width: KsvlSpace.md),
                      if (primaryLabel != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onPrimaryAction,
                            child: Text(
                              primaryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static void _showReceipt(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(KsvlSpace.lg),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: KsvlRadius.allMd,
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String _relativeDay(DateTime dt) {
    final now = DateTime.now();
    final date = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
    this.trailing,
    this.emphasise = false,
  });

  final IconData icon;
  final String value;
  final Widget? trailing;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: k.textMuted),
        ),
        const SizedBox(width: KsvlSpace.sm),
        Expanded(
          child: SelectableText(
            value,
            style: emphasise
                ? text.titleSmall
                : text.bodyMedium?.copyWith(color: k.textPrimary),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: 'Copy $label',
        icon: const Icon(Icons.copy_rounded, size: 15),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('Copied $label')),
            );
        },
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: KsvlSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: k.brandSoft,
              borderRadius: KsvlRadius.allXs,
            ),
            alignment: Alignment.center,
            child: Text(
              '×${item.quantity}',
              style: text.labelSmall?.copyWith(
                color: k.onBrandSoft,
                letterSpacing: 0,
                fontFeatures: KsvlType.tabular,
              ),
            ),
          ),
          const SizedBox(width: KsvlSpace.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: text.bodyMedium?.copyWith(
                  color: k.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: item.productName),
                  TextSpan(
                    text: '  ${item.variantTitle}',
                    style: text.bodySmall?.copyWith(color: k.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: KsvlSpace.sm),
          KsvlAmount(
            item.lineTotal,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: k.textSecondary,
          ),
        ],
      ),
    );
  }
}
