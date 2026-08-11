import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider() {
    _sub = OrderRepository.instance.watchAll().listen((v) {
      _orders = v;
      notifyListeners();
    });
  }

  late final StreamSubscription<List<Order>> _sub;

  List<Order> _orders = const [];

  List<Order> get orders => List.unmodifiable(_orders);

  int get todaysOrdersCount {
    final now = DateTime.now();
    return _orders.where((o) {
      return o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day &&
          o.status != OrderStatus.cancelled;
    }).length;
  }

  int get pendingOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  double get todaysSales {
    final now = DateTime.now();
    return _orders.where((o) {
      final sameDay = o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
      return sameDay &&
          (o.status == OrderStatus.completed ||
              o.status == OrderStatus.inProgress ||
              o.status == OrderStatus.pending);
    }).fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  List<Order> ordersByStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).toList();

  /// Newest orders first, for the dashboard summary.
  List<Order> recentOrders(int count) {
    final sorted = List<Order>.from(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(count).toList();
  }

  void updateStatus(String orderId, OrderStatus status) {
    OrderRepository.instance.updateStatus(orderId, status);
  }

  /// Returns next suggested status action label, or null if none.
  static String? nextActionLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Mark as Packed';
      case OrderStatus.inProgress:
        return 'Mark Completed';
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  static OrderStatus? nextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.inProgress;
      case OrderStatus.inProgress:
        return OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  static String? secondaryActionLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Cancel Order';
      case OrderStatus.inProgress:
        return 'Send Out for Delivery';
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
