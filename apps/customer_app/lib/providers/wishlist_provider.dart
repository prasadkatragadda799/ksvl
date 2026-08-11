import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Products the customer has saved for later.
///
/// Stored on the device rather than against the account on purpose: a shopper
/// browsing before they have ever signed in still gets to keep their list, and
/// nothing here is worth a network round trip on every tap.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider() {
    _restore();
  }

  static const String _storageKey = 'ksvl_wishlist_v1';

  final Set<String> _productIds = <String>{};

  Set<String> get productIds => Set.unmodifiable(_productIds);
  int get count => _productIds.length;
  bool get isEmpty => _productIds.isEmpty;

  bool contains(String productId) => _productIds.contains(productId);

  /// Flips the saved state and returns what it became, so the caller can say
  /// "Saved" or "Removed" without re-reading the set.
  bool toggle(String productId) {
    final added = _productIds.add(productId);
    if (!added) _productIds.remove(productId);
    notifyListeners();
    _persist();
    return added;
  }

  void clear() {
    if (_productIds.isEmpty) return;
    _productIds.clear();
    notifyListeners();
    _persist();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);
      if (saved == null || saved.isEmpty) return;
      _productIds.addAll(saved);
      notifyListeners();
    } catch (_) {
      // A wishlist that cannot be read is not worth surfacing an error for.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _productIds.toList());
    } catch (_) {
      // Same: failing to save a like must never break the shop.
    }
  }
}
