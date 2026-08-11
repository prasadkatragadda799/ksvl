/// Single hub the shop delivers from — customers must be within [radiusKm].
class StoreLocation {
  const StoreLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
    this.address = '',
  });

  final String label;
  final double latitude;
  final double longitude;

  /// Delivery radius in kilometres. Product requirement: 10 km.
  final double radiusKm;
  final String address;

  StoreLocation copyWith({
    String? label,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? address,
  }) {
    return StoreLocation(
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'address': address,
      };

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 10,
      address: json['address'] as String? ?? '',
    );
  }
}
