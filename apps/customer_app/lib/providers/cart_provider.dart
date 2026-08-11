import 'package:flutter/foundation.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:customer_app/models/cart_item.dart';

enum PaymentMethod { cod, upi }

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  String? _lastOrderId;
  String? _phone;
  bool _hydrating = false;

  List<CartItem> get items => _items.values.toList(growable: false);
  PaymentMethod get paymentMethod => _paymentMethod;
  String? get lastOrderId => _lastOrderId;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.lineTotal);

  DeliverySettings get _settings => AppCatalog.instance.deliverySettings;

  double deliveryFee({required bool serviceable}) {
    if (!serviceable) return 0;
    if (subtotal >= _settings.freeDeliveryThreshold) return 0;
    return _settings.deliveryFee;
  }

  double amountForFreeDelivery() {
    final remaining = _settings.freeDeliveryThreshold - subtotal;
    return remaining > 0 ? remaining : 0;
  }

  double total({required bool serviceable}) =>
      subtotal + deliveryFee(serviceable: serviceable);

  int quantityFor(String productId, String variantId) {
    return _items['${productId}_$variantId']?.quantity ?? 0;
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Called whenever the logged-in account changes (login, logout, switch
  /// account) so the cart follows the phone number rather than the device.
  void syncAccount(String? phone, List<CartLine> remoteCart) {
    if (phone == _phone) return;
    final wasGuest = _phone == null;
    _phone = phone;

    if (phone == null) {
      // Logged out — keep the current items as a local guest cart.
      return;
    }

    if (wasGuest && remoteCart.isEmpty && _items.isNotEmpty) {
      // Had a guest cart, logging into an account with nothing saved yet —
      // adopt the guest cart into the account instead of discarding it.
      _persist();
      return;
    }

    _hydrating = true;
    _items
      ..clear()
      ..addEntries(_rehydrate(remoteCart));
    _hydrating = false;
    notifyListeners();
  }

  Iterable<MapEntry<String, CartItem>> _rehydrate(List<CartLine> lines) sync* {
    final products = AppCatalog.instance.products;
    for (final line in lines) {
      Product? product;
      for (final p in products) {
        if (p.id == line.productId) {
          product = p;
          break;
        }
      }
      if (product == null) continue;
      ProductVariant? variant;
      for (final v in product.variants) {
        if (v.id == line.variantId) {
          variant = v;
          break;
        }
      }
      if (variant == null) continue;
      yield MapEntry(
        '${product.id}_${variant.id}',
        CartItem(product: product, variant: variant, quantity: line.quantity),
      );
    }
  }

  void _persist() {
    final phone = _phone;
    if (phone == null || _hydrating) return;
    UserRepository.instance.updateCart(
      phone,
      _items.values
          .map((i) => CartLine(
                productId: i.product.id,
                variantId: i.variant.id,
                quantity: i.quantity,
              ))
          .toList(),
    );
  }

  void add(Product product, ProductVariant variant) {
    if (!variant.isAvailable || !product.isAvailable) return;
    final key = '${product.id}_${variant.id}';
    final existing = _items[key];
    if (existing == null) {
      _items[key] = CartItem(product: product, variant: variant, quantity: 1);
    } else {
      _items[key] = existing.copyWith(quantity: existing.quantity + 1);
    }
    notifyListeners();
    _persist();
  }

  void increment(String productId, String variantId) {
    final key = '${productId}_$variantId';
    final existing = _items[key];
    if (existing == null) return;
    _items[key] = existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
    _persist();
  }

  void decrement(String productId, String variantId) {
    final key = '${productId}_$variantId';
    final existing = _items[key];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _items.remove(key);
    } else {
      _items[key] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
    _persist();
  }

  void remove(String productId, String variantId) {
    _items.remove('${productId}_$variantId');
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  String placeOrder() {
    final id =
        'ORD-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}';
    _lastOrderId = id;
    _items.clear();
    notifyListeners();
    _persist();
    return id;
  }
}
