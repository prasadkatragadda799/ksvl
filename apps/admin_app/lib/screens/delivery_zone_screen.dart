import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/store_provider.dart';
import '../widgets/store_location_map_picker.dart';

/// Admin sets the single store hub — customers must be within 10 km.
class DeliveryZoneScreen extends StatefulWidget {
  const DeliveryZoneScreen({super.key});

  @override
  State<DeliveryZoneScreen> createState() => _DeliveryZoneScreenState();
}

class _DeliveryZoneScreenState extends State<DeliveryZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  static const _presets = <({String name, double lat, double lng, String address})>[
    (
      name: 'Visakhapatnam — MVP Colony',
      lat: 17.7340,
      lng: 83.3085,
      address: 'Near MVP Colony, Visakhapatnam, AP 530017',
    ),
    (
      name: 'Visakhapatnam — Dwaraka Nagar',
      lat: 17.7261,
      lng: 83.3035,
      address: 'Dwaraka Nagar, Visakhapatnam, AP 530016',
    ),
    (
      name: 'Visakhapatnam — Gajuwaka',
      lat: 17.6790,
      lng: 83.2100,
      address: 'Gajuwaka, Visakhapatnam, AP 530026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final loc = context.read<StoreProvider>().storeLocation;
    _labelController = TextEditingController(text: loc.label);
    _addressController = TextEditingController(text: loc.address);
    _latController =
        TextEditingController(text: loc.latitude.toStringAsFixed(5));
    _lngController =
        TextEditingController(text: loc.longitude.toStringAsFixed(5));
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final current = context.watch<StoreProvider>().storeLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery zone')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KsvlSpace.lg),
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Save 10 km delivery hub'),
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
                    child: Icon(Icons.radar_rounded, color: k.success),
                  ),
                  const SizedBox(width: KsvlSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service radius', style: text.titleSmall),
                        Text(
                          'Fixed at ${current.radiusKm.toStringAsFixed(0)} km '
                          'from your hub. Customers outside cannot order.',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.xxl),
            const KsvlSectionHeader(
              title: 'Hub location',
              caption: 'Pin it on the map, pick a preset, or enter coordinates',
            ),
            const SizedBox(height: KsvlSpace.md),
            KsvlCard(
              onTap: _pickOnMap,
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: k.brand),
                  const SizedBox(width: KsvlSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick on map', style: text.titleSmall),
                        Text(
                          'Drop a pin at the exact hub location',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: k.textMuted),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.sm),
            for (final preset in _presets)
              Padding(
                padding: const EdgeInsets.only(bottom: KsvlSpace.sm),
                child: KsvlCard(
                  onTap: () => _applyPreset(preset),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, color: k.brand),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(preset.name, style: text.titleSmall),
                            Text(preset.address, style: text.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: k.textMuted),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: KsvlSpace.xl),
            KsvlCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Hub name',
                      hintText: 'e.g. KSVL Hub — Visakhapatnam',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 3) ? 'Required' : null,
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address / landmark',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.\-]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                          ),
                          validator: _validateCoord,
                        ),
                      ),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.\-]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                          ),
                          validator: _validateCoord,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickOnMap() async {
    final lat = double.tryParse(_latController.text.trim()) ?? 0;
    final lng = double.tryParse(_lngController.text.trim()) ?? 0;
    final picked = await showStoreLocationMapPicker(
      context,
      initialLat: lat,
      initialLng: lng,
      radiusKm: 10,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _latController.text = picked.latitude.toStringAsFixed(5);
      _lngController.text = picked.longitude.toStringAsFixed(5);
      _addressController.text = picked.label;
    });
  }

  void _applyPreset(
    ({String name, double lat, double lng, String address}) preset,
  ) {
    setState(() {
      _labelController.text = 'KSVL Hub — ${preset.name.split('—').last.trim()}';
      _addressController.text = preset.address;
      _latController.text = preset.lat.toStringAsFixed(5);
      _lngController.text = preset.lng.toStringAsFixed(5);
    });
  }

  String? _validateCoord(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null) return 'Invalid';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final location = StoreLocation(
      label: _labelController.text.trim(),
      address: _addressController.text.trim(),
      latitude: double.parse(_latController.text.trim()),
      longitude: double.parse(_lngController.text.trim()),
      radiusKm: 10,
    );
    context.read<StoreProvider>().setStoreLocation(location);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Hub saved · delivery within ${location.radiusKm.toStringAsFixed(0)} km',
          ),
        ),
      );
    Navigator.pop(context);
  }
}
