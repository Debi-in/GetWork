// ============================================================
// LOCATION PICKER SHEET — GetWork App
// Lets user tap on a map to pin a location or use current GPS.
// Uses Nominatim reverse geocoding to retrieve readable place names
// (e.g. "Balaju, Kathmandu") instead of raw coordinates.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

class LocationPickerSheet extends StatefulWidget {
  /// Pre-selected location (optional)
  final LatLng? initialLocation;
  final String? initialLabel;

  const LocationPickerSheet({
    super.key,
    this.initialLocation,
    this.initialLabel,
  });

  /// Show and return the picked [LocationPickResult], or null if cancelled.
  static Future<LocationPickResult?> show(
    BuildContext context, {
    LatLng? initial,
    String? initialLabel,
  }) {
    return showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(
        initialLocation: initial,
        initialLabel: initialLabel,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class LocationPickResult {
  final LatLng latLng;
  final String label;
  const LocationPickResult({required this.latLng, required this.label});
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  // Default: Kathmandu Center
  static const LatLng _defaultCenter = LatLng(27.7172, 85.3240);

  late final MapController _mapController;
  LatLng? _pickedLocation;
  String _locationLabel = '';
  bool _isGeocoding = false;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _pickedLocation = widget.initialLocation;
      _locationLabel = widget.initialLabel ?? 'Selected Location';
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Reverse geocodes coordinates to a human-readable address string using OpenStreetMap Nominatim
  Future<String> _reverseGeocode(LatLng ll) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${ll.latitude}&lon=${ll.longitude}&accept-language=en',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'GetWorkApp/1.0 (contact@getwork.app)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final suburb = address['suburb'] ??
              address['neighbourhood'] ??
              address['residential'] ??
              address['quarter'] ??
              address['village'] ??
              address['road'] ??
              address['commercial'] ??
              '';
          final city = address['city'] ??
              address['town'] ??
              address['county'] ??
              address['state_district'] ??
              'Kathmandu';
          
          if (suburb.toString().isNotEmpty) {
            return '$suburb, $city';
          } else if (data['name'] != null && data['name'].toString().isNotEmpty) {
            return '${data['name']}, $city';
          } else {
            return '$city';
          }
        }
      }
    } catch (_) {
      // Fallback on error/timeout
    }
    return '${ll.latitude.toStringAsFixed(4)}, ${ll.longitude.toStringAsFixed(4)}';
  }

  Future<void> _updateLocation(LatLng ll) async {
    setState(() {
      _pickedLocation = ll;
      _isGeocoding = true;
      _locationLabel = 'Finding place name...';
    });

    final name = await _reverseGeocode(ll);
    if (!mounted) return;

    setState(() {
      _locationLabel = name;
      _isGeocoding = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on device.')),
          );
        }
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final ll = LatLng(pos.latitude, pos.longitude);
      _mapController.move(ll, 15);
      await _updateLocation(ll);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get GPS position: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle Bar ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Job Location',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tap on the map to pin a location or use GPS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),

          // ── Current Location Button ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingGps ? null : _useCurrentLocation,
                icon: _isLoadingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(_isLoadingGps
                    ? 'Locating via GPS...'
                    : 'Use Current Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Interactive Map ────────────────────────────────
          Expanded(
            child: ClipRRect(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialLocation ?? _defaultCenter,
                  initialZoom: 13.5,
                  onTap: (_, ll) => _updateLocation(ll),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.getwork.app',
                  ),
                  if (_pickedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pickedLocation!,
                          width: 48,
                          height: 58,
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 10,
                                color: const Color(0xFFE53935),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Pinned Place Name + Confirm Bar ────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pickedLocation != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _isGeocoding
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(
                                Icons.place_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pinned Location Name',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _locationLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'No location pinned — tap on the map to pin a place',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: (_pickedLocation != null && !_isGeocoding)
                          ? const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            )
                          : LinearGradient(
                              colors: [Colors.grey.shade300, Colors.grey.shade300],
                            ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: (_pickedLocation == null || _isGeocoding)
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                LocationPickResult(
                                  latLng: _pickedLocation!,
                                  label: _locationLabel,
                                ),
                              );
                            },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.textSecondary,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
