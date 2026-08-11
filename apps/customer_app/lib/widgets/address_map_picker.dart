import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:ksvl_shared/ksvl_shared.dart';

import '../env.dart';

/// Result of the map pin picker — coordinates + a readable street-level label.
class PickedMapAddress {
  const PickedMapAddress({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.area = '',
  });

  final double latitude;
  final double longitude;

  /// Street / locality line from reverse geocoding.
  final String label;

  /// Shorter neighbourhood / suburb hint when available.
  final String area;

  String get shortCoords =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

/// Opens a full-screen map so the customer can drop a pin on the exact spot.
Future<PickedMapAddress?> showAddressMapPicker(
  BuildContext context, {
  required StoreLocation store,
  PickedMapAddress? initial,
}) {
  return Navigator.of(context).push<PickedMapAddress>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddressMapPicker(
        store: store,
        initial: initial,
      ),
    ),
  );
}

class AddressMapPicker extends StatefulWidget {
  const AddressMapPicker({
    super.key,
    required this.store,
    this.initial,
  });

  final StoreLocation store;
  final PickedMapAddress? initial;

  @override
  State<AddressMapPicker> createState() => _AddressMapPickerState();
}

class _AddressMapPickerState extends State<AddressMapPicker> {
  GoogleMapController? _mapController;
  late LatLng _center;
  String _label = 'Move the map to set your pin';
  String _area = '';
  bool _lookingUp = false;
  bool _locating = false;
  String? _zoneError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _center = i != null
        ? LatLng(i.latitude, i.longitude)
        : LatLng(widget.store.latitude, widget.store.longitude);
    if (i != null) {
      _label = i.label;
      _area = i.area;
      _zoneError = _outsideZone(_center) ? _outsideMessage : null;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup(_center));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  bool _outsideZone(LatLng p) {
    final km = haversineKm(
      lat1: widget.store.latitude,
      lon1: widget.store.longitude,
      lat2: p.latitude,
      lon2: p.longitude,
    );
    return km > widget.store.radiusKm;
  }

  String get _outsideMessage =>
      'Outside the ${widget.store.radiusKm.toStringAsFixed(0)} km delivery '
      'zone around ${widget.store.label}';

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    _debounce?.cancel();
    setState(() {
      _zoneError = _outsideZone(_center) ? _outsideMessage : null;
      _lookingUp = true;
      _label = 'Finding address…';
    });
  }

  void _onCameraIdle() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      if (mounted) _lookup(_center);
    });
  }

  Future<void> _lookup(LatLng point) async {
    setState(() {
      _lookingUp = true;
      _zoneError = _outsideZone(point) ? _outsideMessage : null;
    });

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng': '${point.latitude},${point.longitude}',
          'key': Env.googleMapsApiKey,
        },
      );
      final res = await http.get(uri);
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _lookingUp = false;
          _label = 'Pinned at ${point.latitude.toStringAsFixed(5)}, '
              '${point.longitude.toStringAsFixed(5)}';
          _area = '';
        });
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) {
        setState(() {
          _lookingUp = false;
          _label = 'Pinned at ${point.latitude.toStringAsFixed(5)}, '
              '${point.longitude.toStringAsFixed(5)}';
          _area = '';
        });
        return;
      }
      final best = results.first as Map<String, dynamic>;
      final formatted = (best['formatted_address'] as String?)?.trim() ?? '';
      final components =
          (best['address_components'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

      String componentOf(List<String> types) {
        for (final c in components) {
          final cTypes = (c['types'] as List<dynamic>? ?? const [])
              .cast<String>();
          if (types.any(cTypes.contains)) {
            return (c['long_name'] as String?)?.trim() ?? '';
          }
        }
        return '';
      }

      final area = componentOf(['sublocality', 'sublocality_level_1', 'neighborhood']);
      final locality = componentOf(['locality', 'administrative_area_level_2']);

      setState(() {
        _lookingUp = false;
        _label = formatted.isNotEmpty
            ? formatted
            : 'Pinned at ${point.latitude.toStringAsFixed(5)}, '
                '${point.longitude.toStringAsFixed(5)}';
        _area = area.isNotEmpty ? area : locality;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _label = 'Pinned at ${point.latitude.toStringAsFixed(5)}, '
            '${point.longitude.toStringAsFixed(5)}';
        _area = '';
      });
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _toast('Turn on location services to use GPS');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast('Location permission is needed for GPS');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final target = LatLng(pos.latitude, pos.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 17),
      );
      _center = target;
      await _lookup(target);
    } catch (_) {
      _toast('Could not read GPS — move the pin manually');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirm() {
    if (_zoneError != null) {
      _toast(_zoneError!);
      return;
    }
    Navigator.pop(
      context,
      PickedMapAddress(
        latitude: _center.latitude,
        longitude: _center.longitude,
        label: _label,
        area: _area,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final canConfirm = _zoneError == null && !_lookingUp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin delivery location'),
        actions: [
          IconButton(
            onPressed: _locating ? null : _goToMyLocation,
            tooltip: 'Use my GPS',
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: KsvlLoader.inline(),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            minMaxZoomPreference: const MinMaxZoomPreference(11, 19),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            circles: {
              Circle(
                circleId: const CircleId('delivery_zone'),
                center: LatLng(widget.store.latitude, widget.store.longitude),
                radius: widget.store.radiusKm * 1000,
                fillColor: k.brand.withValues(alpha: 0.08),
                strokeColor: k.brand.withValues(alpha: 0.45),
                strokeWidth: 2,
              ),
            },
            markers: {
              Marker(
                markerId: const MarkerId('store'),
                position: LatLng(widget.store.latitude, widget.store.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(title: widget.store.label),
              ),
            },
          ),
          // Fixed center pin — the address is always the map center.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: _zoneError == null ? k.brand : k.danger,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: KsvlSpace.lg,
            right: KsvlSpace.lg,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: KsvlSpace.lg),
                child: Material(
                  elevation: 8,
                  borderRadius: KsvlRadius.allMd,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(KsvlSpace.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _zoneError == null
                                  ? Icons.place_rounded
                                  : Icons.wrong_location_outlined,
                              color: _zoneError == null ? k.brand : k.danger,
                            ),
                            const SizedBox(width: KsvlSpace.sm),
                            Text(
                              _zoneError == null
                                  ? 'Delivery pin'
                                  : 'Outside delivery zone',
                              style: text.titleSmall?.copyWith(
                                color: _zoneError == null
                                    ? k.textPrimary
                                    : k.danger,
                              ),
                            ),
                            const Spacer(),
                            if (_lookingUp)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: KsvlLoader.inline(),
                              ),
                          ],
                        ),
                        const SizedBox(height: KsvlSpace.sm),
                        Text(
                          _zoneError ?? _label,
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: KsvlSpace.md),
                        Text(
                          'Drag the map so the pin sits on your building. '
                          'You’ll fill Flat No. & House Name next.',
                          style: text.bodySmall?.copyWith(color: k.textMuted),
                        ),
                        const SizedBox(height: KsvlSpace.lg),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: canConfirm ? _confirm : null,
                            child: const Text('Use this location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
