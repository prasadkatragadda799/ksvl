import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';

/// Bottom-tab shell. Keeps each tab alive so filters and scroll position
/// survive a trip to another tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  OrderStatus? _ordersInitialFilter;

  void _goTo(int index, {OrderStatus? orderFilter}) {
    setState(() {
      _index = index;
      _ordersInitialFilter = orderFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final pendingCount = context.select<OrderProvider, int>(
      (p) => p.pendingOrdersCount,
    );

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onViewOrders: (status) => _goTo(2, orderFilter: status),
            onViewProducts: () => _goTo(1),
          ),
          const ProductsScreen(),
          OrdersScreen(initialFilter: _ordersInitialFilter),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: k.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => _goTo(i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Products',
            ),
            NavigationDestination(
              // A manager should never have to open the tab to learn there is
              // something waiting in it.
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                backgroundColor: k.danger,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                backgroundColor: k.danger,
                child: const Icon(Icons.receipt_long_rounded),
              ),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
