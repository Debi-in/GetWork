// ============================================================
// LOCATION SERVICE — GetWork App
// Handles GPS location and permissions
// ============================================================

import 'package:geolocator/geolocator.dart';

class LocationService {
  // ── Default: Kathmandu city center ───────────────────────────
  static const double defaultLat = 27.7172;
  static const double defaultLng = 85.3240;

  /// Get current user position. Falls back to Kathmandu if denied.
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _defaultPosition();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _defaultPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _defaultPosition();
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Calculate distance in km between two lat/lng points
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  static Position _defaultPosition() {
    return Position(
      latitude: defaultLat,
      longitude: defaultLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
