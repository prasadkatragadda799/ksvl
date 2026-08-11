import 'dart:convert';

import 'package:http/http.dart' as http;

import '../env.dart';

/// Real SMS OTP via 2Factor.in, called directly from the client.
///
/// Note: this ships the 2Factor API key inside the compiled web bundle,
/// where it is extractable by anyone who inspects network requests. That
/// tradeoff was chosen deliberately to avoid standing up a paid Cloud
/// Function; keep the key's 2Factor account funded conservatively.
class OtpService {
  OtpService._();

  static final OtpService instance = OtpService._();

  static String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Sends an OTP SMS to [phone] (10-digit Indian number). Returns the
  /// 2Factor session id to verify against, or null if sending failed.
  Future<String?> sendOtp(String phone) async {
    final national = _normalizePhone(phone);
    if (national.length != 10 || Env.twoFactorApiKey.isEmpty) return null;

    final uri = Uri.parse(
      'https://2factor.in/API/V1/${Env.twoFactorApiKey}/SMS/$national/AUTOGEN/${Env.twoFactorOtpTemplate}',
    );
    try {
      final res = await http.get(uri);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['Status'] != 'Success') return null;
      return body['Details'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> verifyOtp({required String sessionId, required String otp}) async {
    if (Env.twoFactorApiKey.isEmpty) return false;
    final uri = Uri.parse(
      'https://2factor.in/API/V1/${Env.twoFactorApiKey}/SMS/VERIFY/$sessionId/$otp',
    );
    try {
      final res = await http.get(uri);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['Status'] == 'Success';
    } catch (_) {
      return false;
    }
  }
}
