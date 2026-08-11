import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

/// Orders grouped by lifecycle stage, one tab per stage.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialFilter});

  /// Status to open on — set when arriving from a dashboard tile.
  final OrderStatus? initialFilter;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = OrderStatus.values;

  late final TabController _tabController = TabController(
    length: _tabs.length,
    vsync: this,
    initialIndex: _indexFor(widget.initialFilter),
  );

  static int _indexFor(OrderStatus? status) =>
      status == null ? 0 : _tabs.indexOf(status);

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Arriving from the dashboard with a status in hand should land on that
    // status, not wherever the tab bar was left last time.
    if (widget.initialFilter != null &&
        widget.initialFilter != oldWidget.initialFilter) {
      _tabController.animateTo(_indexFor(widget.initialFilter));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final k = KsvlColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: KsvlSpace.sm),
              tabs: [
                for (final status in _tabs)
                  _CountTab(
                    label: status.label,
                    count: provider.ordersByStatus(status).length,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final status in _tabs)
            _OrderList(status: status, orders: provider.ordersByStatus(status)),
        ],
      ),
      backgroundColor: k.surfaceSunken,
    );
  }
}

class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Tab(
      height: 46,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: KsvlSpace.sm - 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: k.surfaceSubtle,
              borderRadius: KsvlRadius.allPill,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.4,
                color: k.textMuted,
                fontFeatures: KsvlType.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.status, required this.orders});

  final OrderStatus status;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return KsvlEmptyState(
        icon: switch (status) {
          OrderStatus.pending => Icons.inbox_outlined,
          OrderStatus.inProgress => Icons.local_shipping_outlined,
          OrderStatus.completed => Icons.task_alt_rounded,
          OrderStatus.cancelled => Icons.cancel_outlined,
        },
        tone: switch (status) {
          OrderStatus.pending => KsvlTone.warning,
          OrderStatus.inProgress => KsvlTone.info,
          OrderStatus.completed => KsvlTone.success,
          OrderStatus.cancelled => KsvlTone.neutral,
        },
        title: 'No ${status.label.toLowerCase()} orders',
        message: switch (status) {
          OrderStatus.pending => 'New orders will land here for packing.',
          OrderStatus.inProgress => 'Orders being packed will show up here.',
          OrderStatus.completed => 'Delivered orders are archived here.',
          OrderStatus.cancelled => 'Nothing has been cancelled.',
        },
      );
    }

    final provider = context.read<OrderProvider>();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        KsvlSpace.lg,
        KsvlSpace.lg,
        KsvlSpace.lg,
        KsvlSpace.xxxl,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onPrimaryAction: () {
            final next = OrderProvider.nextStatus(order.status);
            if (next == null) return;
            provider.updateStatus(order.id, next);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('#${order.id} moved to ${next.label}'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () =>
                        provider.updateStatus(order.id, order.status),
                  ),
                ),
              );
          },
          onSecondaryAction: () {
            if (order.status != OrderStatus.inProgress) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('#${order.id} marked out for delivery'),
                ),
              );
          },
          onCancel: () => _confirmCancel(context, order),
        );
      },
    );
  }

  Future<void> _confirmCancel(BuildContext context, Order order) async {
    final k = KsvlColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.cancel_outlined, color: k.danger, size: 28),
        title: Text('Cancel order #${order.id}?'),
        content: Text(
          '${order.customerName} will not receive this order. '
          'Cancelling cannot be undone.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          KsvlSpace.lg,
          0,
          KsvlSpace.lg,
          KsvlSpace.lg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: k.danger),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<OrderProvider>()
          .updateStatus(order.id, OrderStatus.cancelled);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('#${order.id} cancelled')));
    }
  }
}
