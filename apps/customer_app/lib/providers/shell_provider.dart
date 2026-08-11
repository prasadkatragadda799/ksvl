import 'package:flutter/foundation.dart';

/// The five places a customer can be in the storefront.
///
/// Kept as an enum rather than a bare index so a call site reads
/// `go(ShellTab.cart)` — an off-by-one in a nav index is the kind of bug that
/// only shows up after a tab is inserted.
enum ShellTab { home, categories, cart, orders, profile }

/// Which bottom-nav tab is showing.
///
/// Lives above the screens so any surface — the cart dock, a category tile, the
/// header avatar — can move the customer without knowing how the shell is
/// built.
class ShellProvider extends ChangeNotifier {
  ShellTab _tab = ShellTab.home;

  ShellTab get tab => _tab;
  int get index => _tab.index;

  void go(ShellTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void goIndex(int index) {
    if (index < 0 || index >= ShellTab.values.length) return;
    go(ShellTab.values[index]);
  }
}
