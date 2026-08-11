import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/catalog_provider.dart';

Future<void> showLocationSheet(BuildContext context) {
  return showKsvlSheet<void>(context, builder: (_) => const LocationSheet());
}

/// Confirms the customer is within the admin-configured 10 km hub radius.
class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key});

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  bool _busy = false;
  String? _message;
  bool? _ok;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final store = catalog.storeLocation;
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlSheetScaffold(
      title: 'Delivery location',
      subtitle: 'We only deliver within ${store.radiusKm.toStringAsFixed(0)} km '
          'of ${store.label}',
      footer: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _useGps,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: KsvlLoader.inline(),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_busy ? 'Checking…' : 'Use my current location'),
              ),
            ),
            const SizedBox(height: KsvlSpace.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _useHub,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('I am at / near the store'),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KsvlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Store hub', style: text.titleSmall),
                const SizedBox(height: KsvlSpace.xs),
                Text(store.label, style: text.bodyMedium),
                if (store.address.isNotEmpty)
                  Text(store.address, style: text.bodySmall),
                const SizedBox(height: KsvlSpace.sm),
                KsvlBadge(
                  label: '${store.radiusKm.toStringAsFixed(0)} km radius',
                  tone: KsvlTone.success,
                  icon: Icons.radar_rounded,
                  dense: true,
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: KsvlSpace.md),
            Container(
              padding: const EdgeInsets.all(KsvlSpace.md),
              decoration: BoxDecoration(
                color: (_ok ?? false) ? k.successSoft : k.danger.withValues(alpha: 0.08),
                borderRadius: KsvlRadius.allSm,
                border: Border.all(
                  color: (_ok ?? false)
                      ? k.success.withValues(alpha: 0.3)
                      : k.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _message!,
                style: text.labelMedium?.copyWith(
                  color: (_ok ?? false) ? k.success : k.danger,
                ),
              ),
            ),
          ],
          if (catalog.hasLocation && catalog.distanceKm != null) ...[
            const SizedBox(height: KsvlSpace.md),
            Text(
              'Last check: ${catalog.distanceKm!.toStringAsFixed(1)} km from hub'
              '${catalog.serviceable ? ' · deliverable' : ' · outside zone'}',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _useHub() async {
    final ok = context.read<CatalogProvider>().useStoreHubLocation();
    setState(() {
      _ok = ok;
      _message = ok
          ? 'You are inside the delivery zone. Happy ordering!'
          : 'Still outside the delivery zone.';
    });
    if (ok && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _useGps() async {
    setState(() {
      _busy = true;
      _message = null;
      _ok = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _busy = false;
          _ok = false;
          _message =
              'Location services are off. Turn them on, or tap “near the store”.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _busy = false;
          _ok = false;
          _message =
              'Location permission denied. Allow location, or use “near the store”.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      final ok = context.read<CatalogProvider>().setCustomerLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            label: 'My location',
          );
      final km = context.read<CatalogProvider>().distanceKm;
      setState(() {
        _busy = false;
        _ok = ok;
        _message = ok
            ? 'You are ${km!.toStringAsFixed(1)} km from the hub — we deliver here.'
            : 'You are ${km!.toStringAsFixed(1)} km away. We only deliver within '
                '${context.read<CatalogProvider>().storeLocation.radiusKm.toStringAsFixed(0)} km.';
      });
      if (ok && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ok = false;
        _message =
            'Could not read GPS. Try again or use “I am at / near the store”.';
      });
    }
  }
}
