import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/user_account_provider.dart';
import 'package:customer_app/widgets/address_form_sheet.dart';
import 'package:customer_app/widgets/address_map_picker.dart';
import 'package:customer_app/widgets/delivery_slot_picker.dart';
import 'package:customer_app/widgets/order_success_sheet.dart';
import 'package:customer_app/widgets/verification_animation.dart';
import 'package:customer_app/services/otp_service.dart';

Future<void> showCheckoutSheet(BuildContext context) {
  return showKsvlSheet<void>(context, builder: (_) => const CheckoutSheet());
}

enum _Step { phone, otp, details }

/// Guided checkout: verify mobile via OTP, then collect name, delivery slot,
/// address and payment.
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _phoneKey = GlobalKey<FormState>();
  final _detailsKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.phone;
  bool _sending = false;
  bool _verifying = false;
  bool _submitting = false;
  int _resendIn = 0;
  Timer? _resendTimer;
  String? _otpSessionId;
  DeliverySlot? _slot;
  PickedMapAddress? _mapAddress;
  String? _selectedAddressId;
  bool _saveAddress = true;
  bool _bootstrapped = false;
  Uint8List? _receiptBytes;
  bool _uploadingReceipt = false;

  /// Set once "Place order" has been pressed.
  ///
  /// Until then the map and slot requirements are stated as instructions, not
  /// as failures. Opening a checkout that is already shouting two red errors at
  /// someone who has not typed anything yet teaches them to ignore red.
  bool _triedSubmit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    final account = context.read<UserAccountProvider>();
    if (account.isLoggedIn) {
      _phoneController.text = account.phone ?? '';
      if (account.name.isNotEmpty) {
        _nameController.text = account.name;
      }
      _step = _Step.details;
      if (account.addresses.isNotEmpty) {
        _applySavedAddress(account.addresses.first);
      }
    }
  }

  void _applySavedAddress(SavedAddress a) {
    _selectedAddressId = a.id;
    _flatController.text = a.flatNo;
    _houseController.text = a.houseName;
    _landmarkController.text = a.landmark;
    _mapAddress = PickedMapAddress(
      latitude: a.latitude,
      longitude: a.longitude,
      label: a.mapLabel,
      area: a.area,
    );
    _saveAddress = false;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _composedAddress {
    final flat = _flatController.text.trim();
    final house = _houseController.text.trim();
    final landmark = _landmarkController.text.trim();
    final map = _mapAddress?.label ?? '';
    final parts = <String>[
      if (flat.isNotEmpty) 'Flat $flat',
      if (house.isNotEmpty) house,
      if (map.isNotEmpty) map,
      if (landmark.isNotEmpty) 'Landmark: $landmark',
    ];
    return parts.join(', ');
  }

  String get _phone => _phoneController.text.trim();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();

    return KsvlSheetScaffold(
      title: _title,
      subtitle: _subtitle(cart, catalog),
      footer: _footer(cart, catalog),
      child: AnimatedSize(
        duration: KsvlMotion.normal,
        curve: KsvlMotion.standard,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: KsvlMotion.normal,
          switchInCurve: KsvlMotion.standard,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: switch (_step) {
            _Step.phone => _phoneStep(context),
            _Step.otp => _otpStep(context),
            _Step.details => _detailsStep(context, cart, catalog),
          },
        ),
      ),
    );
  }

  // ----- Titles ------------------------------------------------------------

  String get _title => switch (_step) {
        _Step.phone => 'Verify your number',
        _Step.otp => 'Enter OTP',
        _Step.details => 'Delivery details',
      };

  String _subtitle(CartProvider cart, CatalogProvider catalog) {
    final items = '${cart.totalQuantity} '
        '${cart.totalQuantity == 1 ? 'item' : 'items'}';
    return switch (_step) {
      _Step.phone => 'We’ll send a one-time code to confirm it’s you',
      _Step.otp => 'Sent to +91 $_phone',
      _Step.details => '$items · delivering near ${catalog.areaLabel}',
    };
  }

  // ----- Step 1: phone -----------------------------------------------------

  Widget _phoneStep(BuildContext context) {
    final k = KsvlColors.of(context);
    return Form(
      key: _phoneKey,
      child: Column(
        key: const ValueKey('phone'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepDots(active: 0),
          const SizedBox(height: KsvlSpace.xl),
          const KsvlOverline('Mobile number'),
          const SizedBox(height: KsvlSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CountryCodeBox(),
              const SizedBox(width: KsvlSpace.sm),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.telephoneNumberNational,
                  ],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    counterText: '',
                  ),
                  onFieldSubmitted: (_) => _sendOtp(),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length != 10) return 'Enter a 10-digit number';
                    if (!RegExp(r'^[6-9]').hasMatch(value)) {
                      return 'Enter a valid Indian mobile number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: KsvlSpace.md),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 15, color: k.textMuted),
              const SizedBox(width: KsvlSpace.xs),
              Expanded(
                child: Text(
                  'Used only to confirm and update you about this order.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----- Step 2: OTP -------------------------------------------------------

  Widget _otpStep(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepDots(active: 1),
        const SizedBox(height: KsvlSpace.xl),
        _OtpField(
          controller: _otpController,
          onCompleted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: KsvlSpace.lg),
        Center(
          child: Text(
            'Enter the code sent by SMS to +91 $_phone',
            style: text.bodySmall?.copyWith(color: k.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: KsvlSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                _resendTimer?.cancel();
                _otpController.clear();
                setState(() => _step = _Step.phone);
              },
              child: const Text('Change number'),
            ),
            Container(width: 1, height: 16, color: k.border),
            TextButton(
              onPressed: _resendIn == 0 ? _sendOtp : null,
              child: Text(
                _resendIn == 0 ? 'Resend OTP' : 'Resend in ${_resendIn}s',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----- Step 3: details ---------------------------------------------------

  Widget _detailsStep(
    BuildContext context,
    CartProvider cart,
    CatalogProvider catalog,
  ) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final account = context.watch<UserAccountProvider>();
    final saved = account.addresses;

    return Form(
      key: _detailsKey,
      child: Column(
        key: const ValueKey('details'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(KsvlSpace.md),
            decoration: BoxDecoration(
              color: k.successSoft,
              borderRadius: KsvlRadius.allSm,
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 18, color: k.success),
                const SizedBox(width: KsvlSpace.sm),
                Expanded(
                  child: Text(
                    '+91 $_phone verified',
                    style: text.bodyMedium?.copyWith(
                      color: k.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KsvlSpace.xl),
          const KsvlOverline('Contact'),
          const SizedBox(height: KsvlSpace.md),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            validator: (v) {
              if ((v?.trim().length ?? 0) < 2) return 'Enter your name';
              return null;
            },
          ),
          const SizedBox(height: KsvlSpace.xl),
          Row(
            children: [
              const Expanded(child: KsvlOverline('Delivery address')),
              TextButton(
                onPressed: () => showAddressFormSheet(context),
                child: const Text('Add new'),
              ),
            ],
          ),
          if (saved.isNotEmpty) ...[
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: saved.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: KsvlSpace.sm),
                itemBuilder: (context, i) {
                  final a = saved[i];
                  final selected = a.id == _selectedAddressId;
                  return _SavedAddressChip(
                    address: a,
                    selected: selected,
                    onTap: () => setState(() => _applySavedAddress(a)),
                  );
                },
              ),
            ),
            const SizedBox(height: KsvlSpace.md),
          ],
          _MapAddressCard(
            picked: _mapAddress,
            onPick: () => _pickOnMap(catalog),
          ),
          if (_mapAddress == null)
            _FieldHint(
              'Pin your building on the map so the rider can find you',
              isError: _triedSubmit,
            ),
          const SizedBox(height: KsvlSpace.md),
          TextFormField(
            controller: _flatController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Flat No.',
              hintText: 'e.g. 302 / B-14',
              prefixIcon: Icon(Icons.door_front_door_outlined, size: 20),
            ),
            validator: (v) {
              if ((v?.trim().isEmpty ?? true)) return 'Enter your flat number';
              return null;
            },
          ),
          const SizedBox(height: KsvlSpace.md),
          TextFormField(
            controller: _houseController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'House / building name',
              hintText: 'e.g. Sai Residency',
              prefixIcon: Icon(Icons.home_work_outlined, size: 20),
            ),
            validator: (v) {
              if ((v?.trim().isEmpty ?? true)) {
                return 'Enter house or building name';
              }
              return null;
            },
          ),
          const SizedBox(height: KsvlSpace.md),
          TextFormField(
            controller: _landmarkController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Landmark (optional)',
              hintText: 'e.g. Opposite SBI ATM',
              prefixIcon: Icon(Icons.flag_outlined, size: 20),
            ),
          ),
          if (_selectedAddressId == null) ...[
            const SizedBox(height: KsvlSpace.sm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _saveAddress,
              onChanged: (v) => setState(() => _saveAddress = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Save this address to my account',
                style: text.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: KsvlSpace.xl),
          Row(
            children: [
              const Expanded(child: KsvlOverline('Delivery slot')),
              Text(
                '${catalog.deliverySettings.slotOpenHour}:00–'
                '${catalog.deliverySettings.slotCloseHour}:00',
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: KsvlSpace.md),
          DeliverySlotPicker(
            settings: catalog.deliverySettings,
            selected: _slot,
            onSelected: (s) => setState(() => _slot = s),
          ),
          if (_slot == null)
            _FieldHint(
              'Choose when you would like it delivered',
              isError: _triedSubmit,
            ),
          const SizedBox(height: KsvlSpace.xl),
          const KsvlOverline('Payment method'),
          const SizedBox(height: KsvlSpace.md),
          Row(
            children: [
              Expanded(
                child: _PaymentTile(
                  label: 'Cash on delivery',
                  caption: 'Pay when it arrives',
                  icon: Icons.payments_outlined,
                  selected: cart.paymentMethod == PaymentMethod.cod,
                  onTap: () => cart.setPaymentMethod(PaymentMethod.cod),
                ),
              ),
              const SizedBox(width: KsvlSpace.md),
              Expanded(
                child: _PaymentTile(
                  label: 'UPI',
                  caption: 'GPay, PhonePe, Paytm',
                  icon: Icons.qr_code_2_rounded,
                  selected: cart.paymentMethod == PaymentMethod.upi,
                  onTap: catalog.upiId.isEmpty
                      ? null
                      : () => cart.setPaymentMethod(PaymentMethod.upi),
                ),
              ),
            ],
          ),
          if (cart.paymentMethod == PaymentMethod.upi)
            _upiPaymentPanel(catalog, cart),
        ],
      ),
    );
  }

  Widget _upiPaymentPanel(CatalogProvider catalog, CartProvider cart) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final total = cart.total(serviceable: catalog.serviceable);
    final upiId = catalog.upiId;

    if (upiId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: KsvlSpace.md),
        child: Text(
          'Online payment isn’t set up yet — please choose cash on delivery.',
          style: text.bodySmall?.copyWith(color: k.danger),
        ),
      );
    }

    final upiLink = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(catalog.storeName)}'
        '&am=${total.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('KSVL order')}';

    return Container(
      margin: const EdgeInsets.only(top: KsvlSpace.lg),
      padding: const EdgeInsets.all(KsvlSpace.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: KsvlRadius.allSm,
        border: Border.all(color: k.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(KsvlSpace.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: KsvlRadius.allSm,
              ),
              child: QrImageView(data: upiLink, size: 172),
            ),
          ),
          const SizedBox(height: KsvlSpace.sm),
          Text(
            'Scan with any UPI app · pay ${formatRupee(total)} to $upiId',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          const SizedBox(height: KsvlSpace.lg),
          const KsvlOverline('Upload payment screenshot'),
          const SizedBox(height: KsvlSpace.sm),
          if (_receiptBytes != null)
            ClipRRect(
              borderRadius: KsvlRadius.allSm,
              child: Image.memory(_receiptBytes!, height: 140, fit: BoxFit.cover),
            ),
          if (_receiptBytes != null) const SizedBox(height: KsvlSpace.sm),
          OutlinedButton.icon(
            onPressed: _uploadingReceipt ? null : _pickReceipt,
            icon: _uploadingReceipt
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file_rounded, size: 18),
            label: Text(_receiptBytes == null ? 'Choose file' : 'Change file'),
          ),
          if (_receiptBytes == null && _triedSubmit)
            _FieldHint('Upload your payment receipt to continue', isError: true),
        ],
      ),
    );
  }

  Future<void> _pickReceipt() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _receiptBytes = bytes);
    } catch (_) {
      _showSnack('Could not open the file picker. Try again.');
    }
  }

  // ----- Footer ------------------------------------------------------------

  Widget _footer(CartProvider cart, CatalogProvider catalog) {
    switch (_step) {
      case _Step.phone:
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _sending ? null : _sendOtp,
              child: _sending
                  ? const _BtnSpinner()
                  : const Text('Send OTP'),
            ),
          ),
        );
      case _Step.otp:
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _verifying ? null : _verifyOtp,
              child: _verifying
                  ? const _BtnSpinner()
                  : const Text('Verify & continue'),
            ),
          ),
        );
      case _Step.details:
        final total = cart.total(serviceable: catalog.serviceable);
        final text = Theme.of(context).textTheme;
        return SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total to pay', style: text.bodySmall),
                    KsvlAmount(total, fontSize: 20),
                  ],
                ),
              ),
              const SizedBox(width: KsvlSpace.lg),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _placeOrder,
                    child: _submitting
                        ? const _BtnSpinner()
                        : const Text('Place order'),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  // ----- Actions -----------------------------------------------------------

  Future<void> _sendOtp() async {
    if (!(_phoneKey.currentState?.validate() ?? _phone.length == 10)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final sessionId = await OtpService.instance.sendOtp(_phone);
    if (!mounted) return;
    if (sessionId == null) {
      setState(() => _sending = false);
      _showSnack('Could not send OTP. Try again.');
      return;
    }

    _otpSessionId = sessionId;
    _otpController.clear();
    _startResendTimer();
    setState(() {
      _sending = false;
      _step = _Step.otp;
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendIn = _resendIn - 1);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verifyOtp() async {
    final entered = _otpController.text.trim();
    final sessionId = _otpSessionId;
    if (entered.length < 4 || sessionId == null) {
      _showSnack('Enter the code sent by SMS');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    final ok = await OtpService.instance.verifyOtp(
      sessionId: sessionId,
      otp: entered,
    );
    if (!mounted) return;
    setState(() => _verifying = false);

    await showVerificationResult(context, success: ok);
    if (!mounted) return;

    if (ok) {
      _resendTimer?.cancel();
      final account = context.read<UserAccountProvider>();
      await account.login(phone: _phone);
      if (!mounted) return;
      if (account.name.isNotEmpty && _nameController.text.trim().isEmpty) {
        _nameController.text = account.name;
      }
      if (_mapAddress == null && account.addresses.isNotEmpty) {
        _applySavedAddress(account.addresses.first);
      }
      setState(() => _step = _Step.details);
    } else {
      _otpController.clear();
    }
  }

  Future<void> _pickOnMap(CatalogProvider catalog) async {
    final picked = await showAddressMapPicker(
      context,
      store: catalog.storeLocation,
      initial: _mapAddress,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _mapAddress = picked;
      _selectedAddressId = null;
      _saveAddress = true;
    });
    // Keep zone check in sync with the pin the customer confirmed.
    catalog.setCustomerLocation(
      latitude: picked.latitude,
      longitude: picked.longitude,
      label: picked.area.isNotEmpty ? picked.area : 'Pinned address',
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _triedSubmit = true);
    if (!(_detailsKey.currentState?.validate() ?? false)) return;
    if (_mapAddress == null) {
      _showSnack('Pin your delivery location on the map');
      return;
    }
    if (_slot == null) {
      _showSnack('Pick a delivery slot');
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      _showSnack('Your cart is empty');
      return;
    }

    final catalog = context.read<CatalogProvider>();
    final payment = cart.paymentMethod;
    if (payment == PaymentMethod.upi) {
      if (catalog.upiId.isEmpty) {
        _showSnack('Online payment isn’t set up — choose cash on delivery');
        return;
      }
      if (_receiptBytes == null) {
        _showSnack('Upload your payment receipt to continue');
        return;
      }
    }

    setState(() => _submitting = true);

    String receiptUrl = '';
    if (payment == PaymentMethod.upi && _receiptBytes != null) {
      setState(() => _uploadingReceipt = true);
      try {
        receiptUrl = await CloudinaryService.instance.uploadImage(
          _receiptBytes!,
          folder: 'receipts',
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _uploadingReceipt = false;
        });
        _showSnack('Receipt upload failed. Try again.');
        return;
      }
      if (!mounted) return;
      setState(() => _uploadingReceipt = false);
    }

    final account = context.read<UserAccountProvider>();
    final name = _nameController.text.trim();
    final address = _composedAddress;
    final total = cart.total(serviceable: catalog.serviceable);
    final slotLabel = _slot!.fullLabel(DateTime.now());
    final orderItems = [
      for (final line in cart.items)
        OrderItem(
          productName: line.product.name,
          variantTitle: line.variant.title,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
        ),
    ];
    final orderId = cart.placeOrder();

    // Persist session + history for the account area.
    if (!account.isLoggedIn) {
      await account.login(phone: _phone, name: name);
    } else {
      await account.updateProfile(name: name);
    }
    await OrderRepository.instance.create(
      Order(
        id: orderId,
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        customerName: name,
        phone: '+91 $_phone',
        address: address,
        pincode: _mapAddress!.shortCoords,
        locationTag: _mapAddress!.area.isNotEmpty
            ? _mapAddress!.area
            : catalog.areaLabel,
        items: orderItems,
        paymentType: payment == PaymentMethod.cod
            ? PaymentType.cod
            : PaymentType.online,
        deliverySlot: slotLabel,
        uid: AuthService.instance.uid ?? '',
        receiptUrl: receiptUrl,
      ),
    );
    if (_saveAddress && _selectedAddressId == null && _mapAddress != null) {
      await account.upsertAddress(
        SavedAddress(
          id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
          label: 'Home',
          flatNo: _flatController.text.trim(),
          houseName: _houseController.text.trim(),
          landmark: _landmarkController.text.trim(),
          mapLabel: _mapAddress!.label,
          latitude: _mapAddress!.latitude,
          longitude: _mapAddress!.longitude,
          area: _mapAddress!.area,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    await showOrderSuccessSheet(
      context,
      orderId: orderId,
      customerName: name,
      phone: _phone,
      address: address,
      pincode: _mapAddress!.shortCoords,
      payment: payment,
      total: total,
      deliverySlot: slotLabel,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// A requirement stated under a field.
///
/// Reads as muted guidance until the customer has actually tried to submit
/// without it, at which point the same sentence turns into an error.
class _FieldHint extends StatelessWidget {
  const _FieldHint(this.message, {required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final color = isError ? k.danger : k.textMuted;

    return Padding(
      padding: const EdgeInsets.only(top: KsvlSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: KsvlSpace.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: isError ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner();

  @override
  Widget build(BuildContext context) {
    return const KsvlLoader.button();
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.active});

  /// 0 = phone/verify, 1 = otp, 2 = details.
  final int active;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    // Phone + OTP collapse into a single "Verify" stage visually.
    final verifyDone = active >= 2;
    final stages = <(String, bool, bool)>[
      ('Verify', active <= 1, verifyDone),
      ('Details', active == 2, false),
    ];
    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          _dot(context, index: i + 1, stage: stages[i]),
          if (i < stages.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: KsvlSpace.sm),
                color: stages[i].$3 ? k.brand : k.border,
              ),
            ),
        ],
      ],
    );
  }

  Widget _dot(
    BuildContext context, {
    required int index,
    required (String, bool, bool) stage,
  }) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final current = stage.$2;
    final done = stage.$3;
    final active = current || done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? k.brand : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: active ? k.brand : k.borderStrong),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '$index',
                  style: text.labelSmall?.copyWith(
                    color: active ? Colors.white : k.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: KsvlSpace.sm),
        Text(
          stage.$1,
          style: text.labelMedium?.copyWith(
            color: active ? k.textPrimary : k.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CountryCodeBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: KsvlSpace.md),
      decoration: BoxDecoration(
        color: k.surfaceSubtle,
        borderRadius: KsvlRadius.allSm,
        border: Border.all(color: k.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'IN',
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: k.brand,
            ),
          ),
          const SizedBox(width: KsvlSpace.sm),
          Text(
            '+91',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: KsvlType.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Six-box OTP entry backed by a single hidden field.
class _OtpField extends StatefulWidget {
  const _OtpField({required this.controller, required this.onCompleted});

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length = 6;

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final value = widget.controller.text;

    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                _box(context, i, value, k, text),
                if (i < widget.length - 1) const SizedBox(width: KsvlSpace.sm),
              ],
            ],
          ),
          // Invisible but focusable input capturing the digits.
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 260,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                showCursor: false,
                style: const TextStyle(height: 0.01, color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(
    BuildContext context,
    int i,
    String value,
    KsvlColors k,
    TextTheme text,
  ) {
    final filled = i < value.length;
    final isNext = i == value.length && _focus.hasFocus;
    return AnimatedContainer(
      duration: KsvlMotion.fast,
      width: 44,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? k.brandSoft : Colors.transparent,
        borderRadius: KsvlRadius.allSm,
        border: Border.all(
          color: filled || isNext ? k.brand : k.border,
          width: filled || isNext ? 1.8 : 1,
        ),
      ),
      child: Text(
        filled ? value[i] : '',
        style: text.headlineSmall?.copyWith(
          color: k.onBrandSoft,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final disabled = onTap == null;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allSm,
          child: AnimatedContainer(
            duration: KsvlMotion.fast,
            padding: const EdgeInsets.all(KsvlSpace.md),
            decoration: BoxDecoration(
              color: selected ? k.brandSoft : Colors.transparent,
              borderRadius: KsvlRadius.allSm,
              border: Border.all(
                color: selected ? k.brand : k.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: disabled
                          ? k.textDisabled
                          : selected
                              ? k.brand
                              : k.textSecondary,
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 17,
                      color: disabled
                          ? k.textDisabled
                          : selected
                              ? k.brand
                              : k.borderStrong,
                    ),
                  ],
                ),
                const SizedBox(height: KsvlSpace.sm),
                Text(
                  label,
                  style: text.titleSmall?.copyWith(
                    color: disabled
                        ? k.textDisabled
                        : selected
                            ? k.onBrandSoft
                            : k.textPrimary,
                  ),
                ),
                Text(
                  disabled ? 'Not set up by the store yet' : caption,
                  style: text.bodySmall?.copyWith(
                    color: disabled ? k.textDisabled : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedAddressChip extends StatelessWidget {
  const _SavedAddressChip({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final SavedAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KsvlRadius.allSm,
        child: Ink(
          width: 168,
          padding: const EdgeInsets.all(KsvlSpace.md),
          decoration: BoxDecoration(
            color: selected ? k.brandSoft : Colors.transparent,
            borderRadius: KsvlRadius.allSm,
            border: Border.all(
              color: selected ? k.brand : k.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  color: selected ? k.onBrandSoft : k.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Flat ${address.flatNo}, ${address.houseName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapAddressCard extends StatelessWidget {
  const _MapAddressCard({
    required this.picked,
    required this.onPick,
  });

  final PickedMapAddress? picked;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final hasPin = picked != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: KsvlRadius.allSm,
        child: Ink(
          padding: const EdgeInsets.all(KsvlSpace.md),
          decoration: BoxDecoration(
            color: hasPin ? k.brandSoft : k.surfaceSubtle,
            borderRadius: KsvlRadius.allSm,
            border: Border.all(
              color: hasPin ? k.brand : k.border,
              width: hasPin ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasPin
                      ? k.brand.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: KsvlRadius.allSm,
                ),
                child: Icon(
                  hasPin ? Icons.map_rounded : Icons.add_location_alt_outlined,
                  color: hasPin ? k.brand : k.textMuted,
                ),
              ),
              const SizedBox(width: KsvlSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPin ? 'Pinned on map' : 'Choose on map',
                      style: text.titleSmall?.copyWith(
                        color: hasPin ? k.onBrandSoft : k.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPin
                          ? picked!.label
                          : 'Open the map and drop a pin on your building',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KsvlSpace.sm),
              Icon(
                hasPin ? Icons.edit_location_alt_outlined : Icons.chevron_right,
                color: k.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
