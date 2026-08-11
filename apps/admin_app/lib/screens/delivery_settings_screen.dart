import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/store_provider.dart';

/// Super-admin control over the delivery-fee slab and the delivery scheduling
/// window customers pick slots from.
class DeliverySettingsScreen extends StatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _feeController;
  late final TextEditingController _freeController;
  late int _leadHours;
  late int _openHour;
  late int _closeHour;
  late int _advanceDays;
  late int _slotHours;

  @override
  void initState() {
    super.initState();
    final s = context.read<StoreProvider>().deliverySettings;
    _feeController =
        TextEditingController(text: s.deliveryFee.toStringAsFixed(0));
    _freeController =
        TextEditingController(text: s.freeDeliveryThreshold.toStringAsFixed(0));
    _leadHours = s.slotLeadHours;
    _openHour = s.slotOpenHour;
    _closeHour = s.slotCloseHour;
    _advanceDays = s.advanceDays;
    _slotHours = s.slotDurationHours;
  }

  @override
  void dispose() {
    _feeController.dispose();
    _freeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final preview = _previewSettings();
    final slots = buildDeliverySlots(preview);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery settings')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KsvlSpace.lg),
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Save delivery settings'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(KsvlSpace.lg),
          children: [
            const KsvlSectionHeader(
              title: 'Delivery fee slab',
              caption: 'Flat fee, waived above the free-delivery threshold',
            ),
            const SizedBox(height: KsvlSpace.md),
            KsvlCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Delivery fee',
                      prefixText: '₹ ',
                    ),
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  TextFormField(
                    controller: _freeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Free delivery above',
                      prefixText: '₹ ',
                      helperText: 'Orders at or above this are delivered free',
                    ),
                    validator: _validateAmount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.xxl),
            const KsvlSectionHeader(
              title: 'Scheduling window',
              caption: 'Controls the slots customers can book',
            ),
            const SizedBox(height: KsvlSpace.md),
            KsvlCard(
              child: Column(
                children: [
                  _StepperRow(
                    label: 'Earliest slot (lead time)',
                    value: '$_leadHours h from now',
                    onMinus: _leadHours > 0
                        ? () => setState(() => _leadHours--)
                        : null,
                    onPlus: _leadHours < 12
                        ? () => setState(() => _leadHours++)
                        : null,
                  ),
                  const Divider(height: KsvlSpace.xl),
                  _StepperRow(
                    label: 'Opens at',
                    value: _hourLabel(_openHour),
                    onMinus: _openHour > 0
                        ? () => setState(() => _openHour--)
                        : null,
                    onPlus: _openHour < _closeHour - 1
                        ? () => setState(() => _openHour++)
                        : null,
                  ),
                  const Divider(height: KsvlSpace.xl),
                  _StepperRow(
                    label: 'Closes at',
                    value: _hourLabel(_closeHour),
                    onMinus: _closeHour > _openHour + 1
                        ? () => setState(() => _closeHour--)
                        : null,
                    onPlus: _closeHour < 24
                        ? () => setState(() => _closeHour++)
                        : null,
                  ),
                  const Divider(height: KsvlSpace.xl),
                  _StepperRow(
                    label: 'Slot length',
                    value: '$_slotHours h',
                    onMinus: _slotHours > 1
                        ? () => setState(() => _slotHours--)
                        : null,
                    onPlus: _slotHours < 4
                        ? () => setState(() => _slotHours++)
                        : null,
                  ),
                  const Divider(height: KsvlSpace.xl),
                  _StepperRow(
                    label: 'Days ahead bookable',
                    value: '$_advanceDays '
                        '${_advanceDays == 1 ? 'day' : 'days'}',
                    onMinus: _advanceDays > 1
                        ? () => setState(() => _advanceDays--)
                        : null,
                    onPlus: _advanceDays < 7
                        ? () => setState(() => _advanceDays++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.lg),
            Container(
              padding: const EdgeInsets.all(KsvlSpace.md),
              decoration: BoxDecoration(
                color: k.infoSoft,
                borderRadius: KsvlRadius.allSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: k.info, size: 18),
                  const SizedBox(width: KsvlSpace.sm),
                  Expanded(
                    child: Text(
                      slots.isEmpty
                          ? 'These settings produce no bookable slots today.'
                          : '${slots.length} slots bookable now · '
                              'first is ${slots.first.fullLabel(DateTime.now())}',
                      style: text.bodySmall?.copyWith(color: k.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DeliverySettings _previewSettings() {
    return DeliverySettings(
      deliveryFee: double.tryParse(_feeController.text.trim()) ?? 0,
      freeDeliveryThreshold: double.tryParse(_freeController.text.trim()) ?? 0,
      slotLeadHours: _leadHours,
      slotOpenHour: _openHour,
      slotCloseHour: _closeHour,
      advanceDays: _advanceDays,
      slotDurationHours: _slotHours,
    );
  }

  String? _validateAmount(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null || n < 0) return 'Enter a valid amount';
    return null;
  }

  static String _hourLabel(int h24) {
    final period = h24 >= 12 ? 'PM' : 'AM';
    var h = h24 % 12;
    if (h == 0) h = 12;
    return '$h:00 $period';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<StoreProvider>().setDeliverySettings(_previewSettings());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Delivery settings saved')),
      );
    Navigator.pop(context);
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final k = KsvlColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.titleSmall),
              Text(value, style: text.bodySmall?.copyWith(color: k.brand)),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_rounded, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: KsvlSpace.sm),
        IconButton.outlined(
          onPressed: onPlus,
          icon: const Icon(Icons.add_rounded, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
