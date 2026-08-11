import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// Phone + OTP gate for the store manager app. Only phone numbers on the
/// `adminPhones` Firestore allow-list can get in — the OTP itself is fixed
/// to 1234 for every number (no SMS provider wired up yet).
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.onAdminVerified});

  final VoidCallback onAdminVerified;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

enum _Step { phone, otp }

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  _Step _step = _Step.phone;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = AuthService.normalizePhone(_phoneController.text);
    if (phone.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() {
      _error = null;
      _step = _Step.otp;
    });
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    final phone = _phoneController.text;
    if (!AuthService.instance.verifyOtp(phone, code)) {
      setState(() => _error = 'Incorrect OTP. Demo code is 1234.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final isAdmin = await AuthService.instance.claimAdminAccess(phone);
    if (!mounted) return;
    setState(() => _busy = false);
    if (isAdmin) {
      widget.onAdminVerified();
    } else {
      setState(() {
        _error =
            'This number is not authorized for admin access. Contact the store owner.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KsvlSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.storefront_rounded, size: 48, color: k.brand),
                  const SizedBox(height: KsvlSpace.md),
                  Text(
                    'KSVL Store Manager',
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KsvlSpace.xs),
                  Text(
                    _step == _Step.phone
                        ? 'Sign in with your admin phone number'
                        : 'Enter the OTP sent to ${_phoneController.text}',
                    style: text.bodyMedium?.copyWith(color: k.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KsvlSpace.xl),
                  if (_step == _Step.phone)
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixText: '+91 ',
                      ),
                      onSubmitted: (_) => _sendOtp(),
                    )
                  else
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        hintText: 'Demo OTP: 1234',
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: KsvlSpace.sm),
                    Text(
                      _error!,
                      style: text.bodySmall?.copyWith(color: k.danger),
                    ),
                  ],
                  const SizedBox(height: KsvlSpace.lg),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : (_step == _Step.phone ? _sendOtp : _verify),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == _Step.phone ? 'Send OTP' : 'Verify'),
                  ),
                  if (_step == _Step.otp)
                    TextButton(
                      onPressed: () => setState(() {
                        _step = _Step.phone;
                        _error = null;
                        _otpController.clear();
                      }),
                      child: const Text('Change phone number'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
