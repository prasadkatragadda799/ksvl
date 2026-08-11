import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// In-app customer account: login state, order history, saved addresses,
/// and cart — all keyed by phone number so the same phone sees the same
/// data on any device/browser, not just the one that logged in first.
class UserAccountProvider extends ChangeNotifier {
  UserAccountProvider() {
    _ensureAnonymousAuth();
  }

  UserProfile _profile = UserProfile.empty;
  List<Order> _orders = const [];
  bool _ready = false;
  StreamSubscription<UserProfile>? _profileSub;
  StreamSubscription<List<Order>>? _ordersSub;

  bool get ready => _ready;
  bool get isLoggedIn => _profile.phone.length == 10;
  String? get phone => _profile.phone.isEmpty ? null : _profile.phone;
  String get name => _profile.name;
  String get displayName =>
      _profile.name.trim().isEmpty ? 'Customer' : _profile.name.trim();
  String get initials {
    final parts = displayName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    final s = displayName;
    return s.isEmpty ? 'U' : s[0].toUpperCase();
  }

  List<SavedAddress> get addresses => List.unmodifiable(_profile.addresses);
  List<CartLine> get cartLines => List.unmodifiable(_profile.cart);
  List<Order> get orders => List.unmodifiable(_orders);

  Future<void> _ensureAnonymousAuth() async {
    await AuthService.instance.ensureSignedIn();
    _ready = true;
    notifyListeners();
  }

  void _watch(String phone) {
    _profileSub?.cancel();
    _ordersSub?.cancel();
    _profileSub = UserRepository.instance.watch(phone).listen((profile) {
      _profile = profile;
      notifyListeners();
    });
    _ordersSub = OrderRepository.instance.watchForPhone(phone).listen((v) {
      _orders = v;
      notifyListeners();
    });
  }

  /// Called after a successful OTP verify (checkout or account login).
  Future<void> login({required String phone, String? name}) async {
    final national = AuthService.normalizePhone(phone);
    if (national.length != 10) return;
    if (national != _profile.phone) _watch(national);
    await UserRepository.instance.login(phone: national, name: name);
  }

  Future<void> updateProfile({String? name}) async {
    if (name == null || !isLoggedIn) return;
    await UserRepository.instance.updateName(_profile.phone, name);
  }

  Future<void> logout() async {
    _profileSub?.cancel();
    _ordersSub?.cancel();
    _profile = UserProfile.empty;
    _orders = const [];
    notifyListeners();
  }

  Future<void> upsertAddress(SavedAddress address) async {
    if (!isLoggedIn) return;
    await UserRepository.instance.upsertAddress(_profile.phone, address);
  }

  Future<void> deleteAddress(String id) async {
    if (!isLoggedIn) return;
    await UserRepository.instance.deleteAddress(_profile.phone, id);
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}
