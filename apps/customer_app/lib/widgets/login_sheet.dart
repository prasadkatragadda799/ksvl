import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/user_account_provider.dart';
import 'package:customer_app/services/otp_service.dart';
import 'package:customer_app/widgets/verification_animation.dart';

/// Phone + real SMS OTP login for the account area (2Factor.in, same flow
/// used at checkout).
Future<bool> showLoginSheet(BuildContext context) async {
  final result = await showKsvlSheet<bool>(
    context,
    builder: (_) => const LoginSheet(),
  );
  return result ?? false;
}

class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneKey = GlobalKey<FormState>();
  bool _otpStep = false;
  bool _busy = false;
  String? _sessionId;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlSheetScaffold(
      title: _otpStep ? 'Enter OTP' : 'Sign in',
      subtitle: _otpStep
          ? 'Code sent by SMS to +91 $_phone'
          : 'Verify your mobile to see orders & addresses',
      footer: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy
                ? null
                : (_otpStep ? _verify : _sendOtp),
            child: _busy
                ? const KsvlLoader.button()
                : Text(_otpStep ? 'Verify & continue' : 'Send OTP'),
          ),
        ),
      ),
      child: AnimatedSwitcher(
        duration: KsvlMotion.normal,
        child: _otpStep ? _otpBody(k, text) : _phoneBody(),
      ),
    );
  }

  Widget _phoneBody() {
    return Form(
      key: _phoneKey,
      child: Column(
        key: const ValueKey('login-phone'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            autofocus: true,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixText: '+91  ',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              helperText: 'We text a 6-digit code to confirm it is you',
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.length != 10) return 'Enter a 10-digit number';
              if (!RegExp(r'^[6-9]').hasMatch(value)) {
                return 'Enter a valid Indian mobile number';
              }
              return null;
            },
            onFieldSubmitted: (_) => _sendOtp(),
          ),
          if (_error != null) ...[
            const SizedBox(height: KsvlSpace.md),
            _ErrorNote(_error!),
          ],
        ],
      ),
    );
  }

  Widget _otpBody(KsvlColors k, TextTheme text) {
    return Column(
      key: const ValueKey('login-otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _otpController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          // Lets the platform drop the SMS code straight in — on a phone this
          // is the difference between a two-tap sign-in and app-switching to
          // read the message.
          autofillHints: const [AutofillHints.oneTimeCode],
          style: const TextStyle(
            fontSize: 28,
            letterSpacing: 10,
            fontWeight: FontWeight.w800,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            hintText: '••••••',
            counterText: '',
          ),
          // A filled-in code with a "Verify" button still to press is a step
          // the customer should not have to take.
          onChanged: (value) {
            if (_error != null) setState(() => _error = null);
            if (value.length == 6 && !_busy) _verify();
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: KsvlSpace.md),
          _ErrorNote(_error!),
        ],
        const SizedBox(height: KsvlSpace.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                _timer?.cancel();
                _otpController.clear();
                setState(() {
                  _otpStep = false;
                  _error = null;
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Change number'),
            ),
            if (_resendIn == 0)
              TextButton(
                onPressed: _sendOtp,
                child: const Text('Resend OTP'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KsvlSpace.md,
                ),
                child: Text(
                  'Resend in ${_resendIn}s',
                  style: text.labelMedium?.copyWith(color: k.textMuted),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (!_otpStep && !(_phoneKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final sessionId = await OtpService.instance.sendOtp(_phone);
    if (!mounted) return;
    if (sessionId == null) {
      setState(() {
        _busy = false;
        _error = 'Could not send OTP. Try again.';
      });
      return;
    }
    _sessionId = sessionId;
    _otpController.clear();
    _timer?.cancel();
    setState(() {
      _busy = false;
      _otpStep = true;
      _resendIn = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final entered = _otpController.text.trim();
    final sessionId = _sessionId;
    if (entered.length < 4 || sessionId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await OtpService.instance.verifyOtp(
      sessionId: sessionId,
      otp: entered,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    await showVerificationResult(context, success: ok);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = 'Incorrect OTP. Try again.');
      _otpController.clear();
      return;
    }
    await context.read<UserAccountProvider>().login(phone: _phone);
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}

/// Inline failure note.
///
/// The bare red sentence this replaces read as body copy that happened to be
/// coloured; wrapping it in the shared danger tone makes it look like the rest
/// of the app's error surfaces.
class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = KsvlTone.danger.resolve(context);
    return Container(
      padding: const EdgeInsets.all(KsvlSpace.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: KsvlRadius.allSm,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colors.foreground),
          const SizedBox(width: KsvlSpace.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.foreground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
