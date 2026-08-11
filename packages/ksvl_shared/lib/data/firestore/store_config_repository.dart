import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/delivery_settings.dart';
import '../../models/store_location.dart';

class StoreConfig {
  const StoreConfig({
    required this.storeName,
    required this.isStoreOpen,
    required this.location,
    required this.deliverySettings,
    this.upiId = '',
  });

  final String storeName;
  final bool isStoreOpen;
  final StoreLocation location;
  final DeliverySettings deliverySettings;

  /// UPI ID (VPA) the store collects online payments on, e.g. `shop@upi`.
  /// Empty means UPI checkout isn't set up yet.
  final String upiId;

  static const StoreConfig fallback = StoreConfig(
    storeName: 'KSVL Naturals',
    isStoreOpen: true,
    location: StoreLocation(
      label: 'Store hub',
      latitude: 0,
      longitude: 0,
      radiusKm: 10,
    ),
    deliverySettings: DeliverySettings(),
  );

  StoreConfig copyWith({
    String? storeName,
    bool? isStoreOpen,
    StoreLocation? location,
    DeliverySettings? deliverySettings,
    String? upiId,
  }) {
    return StoreConfig(
      storeName: storeName ?? this.storeName,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      location: location ?? this.location,
      deliverySettings: deliverySettings ?? this.deliverySettings,
      upiId: upiId ?? this.upiId,
    );
  }

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'isStoreOpen': isStoreOpen,
        'location': location.toJson(),
        'deliverySettings': deliverySettings.toJson(),
        'upiId': upiId,
      };

  factory StoreConfig.fromJson(Map<String, dynamic> json) {
    return StoreConfig(
      storeName: json['storeName'] as String? ?? fallback.storeName,
      isStoreOpen: json['isStoreOpen'] as bool? ?? true,
      location: json['location'] == null
          ? fallback.location
          : StoreLocation.fromJson(
              Map<String, dynamic>.from(json['location'] as Map)),
      deliverySettings: json['deliverySettings'] == null
          ? fallback.deliverySettings
          : DeliverySettings.fromJson(
              Map<String, dynamic>.from(json['deliverySettings'] as Map)),
      upiId: json['upiId'] as String? ?? '',
    );
  }
}

/// Single-document store settings (name, open/closed, hub location, delivery
/// rules) shared by both apps.
class StoreConfigRepository {
  StoreConfigRepository._();
  static final StoreConfigRepository instance = StoreConfigRepository._();

  final DocumentReference<Map<String, dynamic>> _doc =
      FirebaseFirestore.instance.collection('store').doc('config');

  Stream<StoreConfig> watch() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return StoreConfig.fallback;
      return StoreConfig.fromJson(snap.data()!);
    });
  }

  Future<void> save(StoreConfig config) {
    return _doc.set(config.toJson(), SetOptions(merge: true));
  }

  /// Seeds the config doc if it doesn't exist yet (first admin run).
  Future<void> ensureSeeded(StoreConfig initial) async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(initial.toJson());
    }
  }
}
