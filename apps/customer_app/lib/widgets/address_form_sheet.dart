import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/user_account_provider.dart';
import 'package:customer_app/widgets/address_map_picker.dart';

Future<void> showAddressFormSheet(
  BuildContext context, {
  SavedAddress? existing,
}) {
  return showKsvlSheet<void>(
    context,
    builder: (_) => AddressFormSheet(existing: existing),
  );
}

/// Create or edit a saved delivery address (map pin + flat / house details).
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({super.key, this.existing});

  final SavedAddress? existing;

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _flatController;
  late final TextEditingController _houseController;
  late final TextEditingController _landmarkController;
  PickedMapAddress? _map;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelController = TextEditingController(text: e?.label ?? 'Home');
    _flatController = TextEditingController(text: e?.flatNo ?? '');
    _houseController = TextEditingController(text: e?.houseName ?? '');
    _landmarkController = TextEditingController(text: e?.landmark ?? '');
    if (e != null) {
      _map = PickedMapAddress(
        latitude: e.latitude,
        longitude: e.longitude,
        label: e.mapLabel,
        area: e.area,
      );
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _flatController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlSheetScaffold(
      title: _isEdit ? 'Edit address' : 'Add address',
      subtitle: 'Pin on map, then fill Flat No. & House name',
      footer: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const KsvlLoader.button()
                : Text(_isEdit ? 'Save changes' : 'Save address'),
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _labelController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Home / Work / Other',
                prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Give this address a label' : null,
            ),
            const SizedBox(height: KsvlSpace.md),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final picked = await showAddressMapPicker(
                    context,
                    store: catalog.storeLocation,
                    initial: _map,
                  );
                  if (picked != null && mounted) {
                    setState(() => _map = picked);
                  }
                },
                borderRadius: KsvlRadius.allSm,
                child: Ink(
                  padding: const EdgeInsets.all(KsvlSpace.md),
                  decoration: BoxDecoration(
                    color: _map != null ? k.brandSoft : k.surfaceSubtle,
                    borderRadius: KsvlRadius.allSm,
                    border: Border.all(
                      color: _map != null ? k.brand : k.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_rounded,
                        color: _map != null ? k.brand : k.textMuted,
                      ),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: Text(
                          _map?.label ?? 'Choose location on map',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: k.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            if (_map == null)
              Padding(
                padding: const EdgeInsets.only(top: KsvlSpace.xs),
                child: Text(
                  'Map pin is required',
                  style: text.bodySmall?.copyWith(color: k.danger),
                ),
              ),
            const SizedBox(height: KsvlSpace.md),
            TextFormField(
              controller: _flatController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Flat No.',
                hintText: 'e.g. 302 / B-14',
                prefixIcon: Icon(Icons.door_front_door_outlined, size: 20),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Enter flat number' : null,
            ),
            const SizedBox(height: KsvlSpace.md),
            TextFormField(
              controller: _houseController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'House / building name',
                hintText: 'e.g. Sai Residency',
                prefixIcon: Icon(Icons.home_work_outlined, size: 20),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Enter house or building name'
                  : null,
            ),
            const SizedBox(height: KsvlSpace.md),
            TextFormField(
              controller: _landmarkController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Landmark (optional)',
                hintText: 'e.g. Opposite SBI ATM',
                prefixIcon: Icon(Icons.flag_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_map == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Pin a location on the map')),
        );
      return;
    }
    setState(() => _saving = true);
    final address = SavedAddress(
      id: widget.existing?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelController.text.trim(),
      flatNo: _flatController.text.trim(),
      houseName: _houseController.text.trim(),
      landmark: _landmarkController.text.trim(),
      mapLabel: _map!.label,
      latitude: _map!.latitude,
      longitude: _map!.longitude,
      area: _map!.area,
    );
    await context.read<UserAccountProvider>().upsertAddress(address);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Address updated' : 'Address saved'),
        ),
      );
  }
}
