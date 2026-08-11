import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/shell_provider.dart';
import 'package:customer_app/screens/cart_screen.dart';
import 'package:customer_app/screens/categories_screen.dart';
import 'package:customer_app/screens/orders_screen.dart';
import 'package:customer_app/screens/profile_screen.dart';
import 'package:customer_app/screens/store_home_screen.dart';

/// The five destinations, under a persistent bottom bar.
///
/// The app used to be one screen with everything else raised as a modal sheet.
/// That works while a shop has one job; it stops working the moment a customer
/// wants to check an order, because a sheet has no address — you can only get
/// to it from wherever it was raised.
///
/// An [IndexedStack] rather than swapped children: switching to the cart and
/// back must not reset the grid's scroll position or re-fetch the catalogue,
/// which is exactly what rebuilding the home tree would do.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellProvider>();
    final cartQuantity = context.select<CartProvider, int>(
      (c) => c.totalQuantity,
    );
    final k = KsvlColors.of(context);

    return PopScope(
      // Android back from any tab returns to the shop rather than closing it.
      canPop: shell.tab == ShellTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<ShellProvider>().go(ShellTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: shell.index,
          children: const [
            StoreHomeScreen(),
            CategoriesScreen(),
            CartScreen(),
            OrdersScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: k.border)),
          ),
          child: NavigationBar(
            selectedIndex: shell.index,
            onDestinationSelected:
                context.read<ShellProvider>().goIndex,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartQuantity > 0,
                  label: Text('$cartQuantity'),
                  backgroundColor: k.brand,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartQuantity > 0,
                  label: Text('$cartQuantity'),
                  backgroundColor: k.brand,
                  child: const Icon(Icons.shopping_cart_rounded),
                ),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
