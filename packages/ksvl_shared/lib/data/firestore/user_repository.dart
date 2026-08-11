import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/saved_address.dart';

/// A cart line saved against the customer's account — just the identifiers
/// and quantity; the live product/price is looked up from the catalogue
/// when rehydrated, so it never goes stale.
class CartLine {
  const CartLine({
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  final String productId;
  final String variantId;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      productId: json['productId'] as String? ?? '',
      variantId: json['variantId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.phone,
    required this.name,
    required this.addresses,
    required this.cart,
  });

  final String phone;
  final String name;
  final List<SavedAddress> addresses;
  final List<CartLine> cart;

  static const empty =
      UserProfile(phone: '', name: '', addresses: [], cart: []);

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'name': name,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'cart': cart.map((c) => c.toJson()).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'] as List<dynamic>? ?? const [];
    final rawCart = json['cart'] as List<dynamic>? ?? const [];
    return UserProfile(
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      addresses: [
        for (final a in rawAddresses)
          SavedAddress.fromJson(Map<String, dynamic>.from(a as Map)),
      ],
      cart: [
        for (final c in rawCart)
          CartLine.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
    );
  }
}

/// Customer profile (name, saved addresses, cart) keyed by the customer's
/// 10-digit phone number — the identity the customer actually re-enters on
/// every login, so the same number sees the same data on any device.
///
/// Note: since OTP verification happens client-side (2Factor.in) rather than
/// through Firebase Phone Auth, there is no cryptographic link between a
/// verified phone and the Firestore auth session. Security rules allow any
/// signed-in (anonymous) client to read/write any phone's document — an
/// accepted tradeoff for this app's scale, not a fit for sensitive data.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('users');

  Stream<UserProfile> watch(String phone) {
    return _col.doc(phone).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return UserProfile.empty;
      return UserProfile.fromJson(snap.data()!);
    });
  }

  Future<void> login({required String phone, String? name}) {
    return _col.doc(phone).set({
      'phone': phone,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateName(String phone, String name) {
    return _col.doc(phone).set({'name': name.trim()}, SetOptions(merge: true));
  }

  Future<void> updateCart(String phone, List<CartLine> cart) {
    return _col.doc(phone).set({
      'cart': cart.map((c) => c.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertAddress(String phone, SavedAddress address) async {
    final doc = _col.doc(phone);
    final snap = await doc.get();
    final current = snap.exists && snap.data() != null
        ? UserProfile.fromJson(snap.data()!)
        : UserProfile.empty;
    final addresses = List<SavedAddress>.from(current.addresses);
    final index = addresses.indexWhere((a) => a.id == address.id);
    if (index == -1) {
      addresses.insert(0, address);
    } else {
      addresses[index] = address;
    }
    await doc.set({
      'addresses': addresses.map((a) => a.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAddress(String phone, String addressId) async {
    final doc = _col.doc(phone);
    final snap = await doc.get();
    if (!snap.exists || snap.data() == null) return;
    final current = UserProfile.fromJson(snap.data()!);
    final addresses =
        current.addresses.where((a) => a.id != addressId).toList();
    await doc.set({
      'addresses': addresses.map((a) => a.toJson()).toList(),
    }, SetOptions(merge: true));
  }
}
