import 'dart:math' as math;

import '../models/store_location.dart';

/// Great-circle distance between two WGS84 points, in kilometres.
double haversineKm({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

bool isWithinDeliveryRadius({
  required StoreLocation store,
  required double customerLat,
  required double customerLng,
}) {
  final km = haversineKm(
    lat1: store.latitude,
    lon1: store.longitude,
    lat2: customerLat,
    lon2: customerLng,
  );
  return km <= store.radiusKm;
}

double _toRad(double deg) => deg * math.pi / 180.0;
