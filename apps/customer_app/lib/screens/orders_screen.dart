import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/shell_provider.dart';
import 'package:customer_app/providers/user_account_provider.dart';
import 'package:customer_app/widgets/login_sheet.dart';

/// Order history.
///
/// Signed out, this is a sign-in prompt rather than an empty list: "no orders"
/// would be a lie for someone who has ordered before on another device, and
/// the account is keyed by phone number precisely so that history follows the
/// customer.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserAccountProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        titleSpacing: KsvlSpace.lg,
      ),
      body: account.isLoggedIn
          ? const OrdersList()
          : KsvlEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to see your orders',
              message: 'Verify your mobile number and every order placed on '
                  'that number shows up here.',
              actionLabel: 'Sign in',
              onAction: () => showLoginSheet(context),
            ),
    );
  }
}

/// The list itself, so the profile tab can show a short version of the same
/// history without a second implementation.
class OrdersList extends StatelessWidget {
  const OrdersList({super.key, this.limit});

  /// Show at most this many, newest first. Null means all of them.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<UserAccountProvider>().orders;
    final orders = limit == null ? all : all.take(limit!).toList();

    if (orders.isEmpty) {
      return KsvlEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Orders you place will show up here with their status.',
        compact: limit != null,
        actionLabel: 'Start shopping',
        onAction: () => context.read<ShellProvider>().go(ShellTab.home),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        KsvlSpace.lg,
        KsvlSpace.md,
        KsvlSpace.lg,
        KsvlSpace.xxxl,
      ),
      shrinkWrap: limit != null,
      physics: limit != null ? const NeverScrollableScrollPhysics() : null,
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: KsvlSpace.md),
      itemBuilder: (context, index) => KsvlPageWidth(
        child: _OrderCard(order: orders[index]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('#${order.id}', style: text.titleSmall)),
              KsvlBadge.orderStatus(order.status, dense: true),
            ],
          ),
          const SizedBox(height: KsvlSpace.xs),
          Text(
            _formatDate(order.createdAt),
            style: text.bodySmall?.copyWith(color: k.textMuted),
          ),
          if (order.deliverySlot.isNotEmpty) ...[
            const SizedBox(height: KsvlSpace.xs),
            Text('Slot · ${order.deliverySlot}', style: text.bodySmall),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KsvlSpace.sm),
            child: Divider(height: 1, color: k.border),
          ),
          for (final item in order.items.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item.displayLine, style: text.bodySmall),
            ),
          if (order.items.length > 3)
            Text(
              '+${order.items.length - 3} more',
              style: text.labelSmall?.copyWith(color: k.textMuted),
            ),
          const SizedBox(height: KsvlSpace.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: k.textMuted),
                ),
              ),
              const SizedBox(width: KsvlSpace.md),
              KsvlAmount(order.totalAmount, fontSize: 16),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} · $h:$m $period';
  }
}
