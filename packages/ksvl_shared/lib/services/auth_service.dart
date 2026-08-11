import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Phone + OTP auth for KSVL. There is no SMS provider wired up yet, so the
/// OTP is fixed to [fixedOtp] for every phone number — swap [verifyOtp] for a
/// real SMS/Firebase Phone Auth check later without touching call sites.
///
/// Every device gets a stable identity via Firebase anonymous auth so
/// Firestore security rules have a `request.auth.uid` to key data on, even
/// though there is no real password/SMS verification behind it.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String fixedOtp = '1234';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get uid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Ensures the device has a Firebase Auth identity. Call once at app start.
  Future<String> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Checks the entered code against the fixed demo OTP. Returns true and
  /// accepts any 10-digit phone number.
  bool verifyOtp(String phone, String code) {
    final national = normalizePhone(phone);
    return national.length == 10 && code.trim() == fixedOtp;
  }

  /// Grants admin access only if [phone] is on the `adminPhones` allow-list.
  /// Writes an `admins/{uid}` audit doc on success so Firestore rules can
  /// check `exists(/databases/$(db)/documents/admins/$(request.auth.uid))`.
  Future<bool> claimAdminAccess(String phone) async {
    final uid = await ensureSignedIn();
    final national = normalizePhone(phone);
    final allowListed =
        await _db.collection('adminPhones').doc(national).get();
    if (!allowListed.exists) return false;
    await _db.collection('admins').doc(uid).set({
      'phone': national,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<bool> isAdmin() async {
    final id = uid;
    if (id == null) return false;
    final doc = await _db.collection('admins').doc(id).get();
    return doc.exists;
  }

  Future<void> signOut() => _auth.signOut();

  @visibleForTesting
  FirebaseAuth get rawAuth => _auth;
}
