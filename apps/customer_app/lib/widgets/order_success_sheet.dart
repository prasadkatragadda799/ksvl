import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:customer_app/providers/cart_provider.dart';

Future<void> showOrderSuccessSheet(
  BuildContext context, {
  required String orderId,
  required String customerName,
  required String phone,
  required String address,
  required String pincode,
  required PaymentMethod payment,
  required double total,
  required String deliverySlot,
}) {
  return showKsvlSheet<void>(
    context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => OrderSuccessSheet(
      orderId: orderId,
      customerName: customerName,
      phone: phone,
      address: address,
      pincode: pincode,
      payment: payment,
      total: total,
      deliverySlot: deliverySlot,
    ),
  );
}

/// Order confirmation with a receipt block and a WhatsApp share.
class OrderSuccessSheet extends StatelessWidget {
  const OrderSuccessSheet({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.pincode,
    required this.payment,
    required this.total,
    required this.deliverySlot,
  });

  final String orderId;
  final String customerName;
  final String phone;
  final String address;
  final String pincode;
  final PaymentMethod payment;
  final double total;
  final String deliverySlot;

  String get _paymentLabel =>
      payment == PaymentMethod.cod ? 'Cash on delivery' : 'UPI';

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlSheetScaffold(
      title: 'Order confirmed',
      subtitle: 'Arriving $deliverySlot · +91 $phone',
      showClose: false,
      showGrabber: false,
      leading: _SuccessMark(color: k.success, background: k.successSoft),
      footer: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareOnWhatsApp(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Send order on WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KsvlPalette.whatsapp,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: KsvlSpace.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue shopping'),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(KsvlSpace.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: KsvlRadius.allMd,
              border: Border.all(color: k.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const KsvlOverline('Order id'),
                          const SizedBox(height: KsvlSpace.xxs),
                          Text(
                            '#$orderId',
                            style: text.titleMedium?.copyWith(
                              fontFeatures: KsvlType.tabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: orderId),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('Order ID copied')),
                          );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      tooltip: 'Copy order ID',
                      color: k.textMuted,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KsvlSpace.md),
                  child: Divider(height: 1, color: k.border),
                ),
                _ReceiptRow(label: 'Name', value: customerName),
                _ReceiptRow(label: 'Phone', value: '+91 $phone'),
                _ReceiptRow(label: 'Address', value: address),
                _ReceiptRow(label: 'Map pin', value: pincode),
                _ReceiptRow(label: 'Slot', value: deliverySlot),
                _ReceiptRow(label: 'Payment', value: _paymentLabel),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KsvlSpace.md),
                  child: Divider(height: 1, color: k.border),
                ),
                Row(
                  children: [
                    Text('Total', style: text.titleSmall),
                    const Spacer(),
                    KsvlAmount(total, fontSize: 18, color: k.brand),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: KsvlSpace.lg),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 17, color: k.textMuted),
              const SizedBox(width: KsvlSpace.sm),
              Expanded(
                child: Text(
                  'We’ll deliver in your $deliverySlot window and call '
                  '+91 $phone if we’re nearby.',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final message = '''
Hi! I placed an order on KSVL Naturals.

Order ID: #$orderId
Name: $customerName
Phone: +91 $phone
Address: $address
Map pin: $pincode
Delivery slot: $deliverySlot
Payment: $_paymentLabel
Total: ${formatRupee(total)}
'''
        .trim();

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (launched || !context.mounted) return;

    // Falling back to the clipboard keeps the order recoverable on devices
    // with no WhatsApp handler instead of failing silently.
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Order details copied — paste them in WhatsApp'),
        ),
      );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: KsvlSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: k.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(
                color: k.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Check mark that scales in once, marking the moment the order landed.
class _SuccessMark extends StatefulWidget {
  const _SuccessMark({required this.color, required this.background});

  final Color color;
  final Color background;

  @override
  State<_SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<_SuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: KsvlMotion.slow,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: widget.background,
          shape: BoxShape.circle,
          border: Border.all(color: widget.color.withValues(alpha: 0.25)),
        ),
        child: Icon(Icons.check_rounded, color: widget.color, size: 26),
      ),
    );
  }
}
