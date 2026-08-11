import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:ksvl_shared/ksvl_shared.dart';

const String _kGoogleMapsApiKey = 'AIzaSyDALPvPiay0_oC5ZrGoLMncE3skEqp4g6k';

class PickedStoreLocation {
  const PickedStoreLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

/// Full-screen map so the admin can drop the store hub pin precisely.
Future<PickedStoreLocation?> showStoreLocationMapPicker(
  BuildContext context, {
  required double initialLat,
  required double initialLng,
  required double radiusKm,
}) {
  return Navigator.of(context).push<PickedStoreLocation>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _StoreLocationMapPicker(
        initialLat: initialLat,
        initialLng: initialLng,
        radiusKm: radiusKm,
      ),
    ),
  );
}

class _StoreLocationMapPicker extends StatefulWidget {
  const _StoreLocationMapPicker({
    required this.initialLat,
    required this.initialLng,
    required this.radiusKm,
  });

  final double initialLat;
  final double initialLng;
  final double radiusKm;

  @override
  State<_StoreLocationMapPicker> createState() =>
      _StoreLocationMapPickerState();
}

class _StoreLocationMapPickerState extends State<_StoreLocationMapPicker> {
  GoogleMapController? _mapController;
  late LatLng _center;
  String _label = 'Move the map to set your hub';
  bool _lookingUp = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Fall back to a sane India-wide center rather than 0,0 when unset.
    _center = (widget.initialLat == 0 && widget.initialLng == 0)
        ? const LatLng(20.5937, 78.9629)
        : LatLng(widget.initialLat, widget.initialLng);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lookup(_center));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    setState(() {
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
    setState(() => _lookingUp = true);
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'key': _kGoogleMapsApiKey,
      });
      final res = await http.get(uri);
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? const [];
      final formatted = results.isNotEmpty
          ? ((results.first as Map<String, dynamic>)['formatted_address']
                  as String?)
              ?.trim()
          : null;
      setState(() {
        _lookingUp = false;
        _label = (formatted != null && formatted.isNotEmpty)
            ? formatted
            : 'Pinned at ${point.latitude.toStringAsFixed(5)}, '
                '${point.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _label = 'Pinned at ${point.latitude.toStringAsFixed(5)}, '
            '${point.longitude.toStringAsFixed(5)}';
      });
    }
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedStoreLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        label: _label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pin store hub')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            zoomControlsEnabled: false,
            circles: {
              Circle(
                circleId: const CircleId('radius'),
                center: _center,
                radius: widget.radiusKm * 1000,
                fillColor: k.brand.withValues(alpha: 0.08),
                strokeColor: k.brand.withValues(alpha: 0.45),
                strokeWidth: 2,
              ),
            },
          ),
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 44,
                  color: k.brand,
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
                            Icon(Icons.place_rounded, color: k.brand),
                            const SizedBox(width: KsvlSpace.sm),
                            Text('Hub pin', style: text.titleSmall),
                            const Spacer(),
                            if (_lookingUp)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: KsvlSpace.sm),
                        Text(_label, style: text.bodyMedium),
                        const SizedBox(height: KsvlSpace.lg),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _lookingUp ? null : _confirm,
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
