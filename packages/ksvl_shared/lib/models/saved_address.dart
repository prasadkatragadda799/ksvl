/// A customer's bookmarked delivery address (flat + building + map pin).
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.flatNo,
    required this.houseName,
    required this.mapLabel,
    required this.latitude,
    required this.longitude,
    this.landmark = '',
    this.area = '',
  });

  final String id;

  /// Short tag shown in the list — Home, Work, Other, etc.
  final String label;
  final String flatNo;
  final String houseName;
  final String landmark;

  /// Street / locality line from the map reverse-geocode.
  final String mapLabel;
  final double latitude;
  final double longitude;
  final String area;

  String get composedLine {
    final parts = <String>[
      if (flatNo.trim().isNotEmpty) 'Flat ${flatNo.trim()}',
      if (houseName.trim().isNotEmpty) houseName.trim(),
      if (mapLabel.trim().isNotEmpty) mapLabel.trim(),
      if (landmark.trim().isNotEmpty) 'Landmark: ${landmark.trim()}',
    ];
    return parts.join(', ');
  }

  String get shortCoords =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  SavedAddress copyWith({
    String? id,
    String? label,
    String? flatNo,
    String? houseName,
    String? landmark,
    String? mapLabel,
    double? latitude,
    double? longitude,
    String? area,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      flatNo: flatNo ?? this.flatNo,
      houseName: houseName ?? this.houseName,
      landmark: landmark ?? this.landmark,
      mapLabel: mapLabel ?? this.mapLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      area: area ?? this.area,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'flatNo': flatNo,
        'houseName': houseName,
        'landmark': landmark,
        'mapLabel': mapLabel,
        'latitude': latitude,
        'longitude': longitude,
        'area': area,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Home',
      flatNo: json['flatNo'] as String? ?? '',
      houseName: json['houseName'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      mapLabel: json['mapLabel'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      area: json['area'] as String? ?? '',
    );
  }
}
