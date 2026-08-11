import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/store_provider.dart';

/// Admin sets the UPI ID customers pay online to. The customer app turns
/// this into a scannable QR code at checkout.
class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    _upiController =
        TextEditingController(text: context.read<StoreProvider>().upiId);
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment settings')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KsvlSpace.lg),
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Save UPI ID'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(KsvlSpace.lg),
          children: [
            KsvlCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: k.successSoft,
                      borderRadius: KsvlRadius.allSm,
                    ),
                    child: Icon(Icons.qr_code_2_rounded, color: k.success),
                  ),
                  const SizedBox(width: KsvlSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Online payments (UPI)', style: text.titleSmall),
                        Text(
                          'Customers scan a QR built from this ID and upload '
                          'their payment screenshot at checkout.',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.xl),
            KsvlCard(
              child: TextFormField(
                controller: _upiController,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (VPA)',
                  hintText: 'e.g. ksvlnaturals@okaxis',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return null; // empty = UPI disabled
                  if (!RegExp(r'^[\w.\-]{2,}@[\w.\-]{2,}$').hasMatch(value)) {
                    return 'Enter a valid UPI ID, e.g. name@bank';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: KsvlSpace.md),
            Text(
              'Leave blank to hide the UPI option and only accept cash on '
              'delivery.',
              style: text.bodySmall?.copyWith(color: k.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<StoreProvider>().setUpiId(_upiController.text.trim());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Payment settings saved')));
    Navigator.pop(context);
  }
}
