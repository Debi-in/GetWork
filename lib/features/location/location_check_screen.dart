// ============================================================
// LOCATION CHECK SCREEN — GetWork App
// Verifies user location against Kathmandu, Lalitpur, Bhaktapur
// Developer Credit: Debin Rai
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class LocationCheckScreen extends StatefulWidget {
  const LocationCheckScreen({super.key});

  @override
  State<LocationCheckScreen> createState() => _LocationCheckScreenState();
}

class _LocationCheckScreenState extends State<LocationCheckScreen> {
  bool _isChecking = true;
  bool _isSupported = false;
  String _detectedLocation = 'Checking...';
  String _userRole = 'worker';

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    setState(() => _isChecking = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('user_role') ?? 'worker';

      // 1. Check & Request GPS Location Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Fallback to Kathmandu default if permission denied by user
        _evaluateCoordinates(27.7172, 85.3240, 'Kathmandu (Default)');
        return;
      }

      // 2. Fetch Position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      ).catchError((_) => Position(
            latitude: 27.7172,
            longitude: 85.3240,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          ));

      // 3. Determine place name from coordinates (bounding-box based)
      String placeName = _placeNameFromCoords(position.latitude, position.longitude);

      _evaluateCoordinates(position.latitude, position.longitude, placeName);
    } catch (e) {
      // Fallback
      _evaluateCoordinates(27.7172, 85.3240, 'Kathmandu');
    }
  }

  /// Returns a city name based on coordinates — no geocoding package needed.
  String _placeNameFromCoords(double lat, double lng) {
    // Bhaktapur: ~27.67, 85.43
    if (lat >= 27.64 && lat <= 27.70 && lng >= 85.38 && lng <= 85.48) {
      return 'Bhaktapur';
    }
    // Lalitpur / Patan: ~27.67, 85.32
    if (lat >= 27.64 && lat <= 27.70 && lng >= 85.28 && lng <= 85.36) {
      return 'Lalitpur';
    }
    // Kathmandu: ~27.72, 85.32
    if (lat >= 27.68 && lat <= 27.78 && lng >= 85.28 && lng <= 85.36) {
      return 'Kathmandu';
    }
    // Broader Kathmandu Valley
    if (lat >= 27.50 && lat <= 27.85 && lng >= 85.15 && lng <= 85.60) {
      return 'Kathmandu Valley';
    }
    return 'Unknown Location';
  }

  void _evaluateCoordinates(double lat, double lng, String placeName) {
    // Kathmandu Valley Bounding Box & City Name checks:
    // Lat: 27.50 to 27.85 N, Lng: 85.15 to 85.60 E
    // Supported Cities: Kathmandu, Lalitpur, Bhaktapur
    final isWithinBoundingBox =
        (lat >= 27.50 && lat <= 27.85) && (lng >= 85.15 && lng <= 85.60);

    final lowerName = placeName.toLowerCase();
    final isMatchingCity = lowerName.contains('kathmandu') ||
        lowerName.contains('lalitpur') ||
        lowerName.contains('patan') ||
        lowerName.contains('bhaktapur');

    final supported = isWithinBoundingBox || isMatchingCity;

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isSupported = supported;
        _detectedLocation = placeName;
      });
    }
  }

  void _proceedToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_verified', true);

    if (mounted) {
      if (_userRole == 'business') {
        context.go('/business');
      } else {
        context.go('/home');
      }
    }
  }

  void _quitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isChecking
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text(
                        'Verifying location coverage...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _isSupported
                  ? _buildSupportedView()
                  : _buildUnsupportedView(),
        ),
      ),
    );
  }

  /// Screen displayed when user is in Kathmandu, Lalitpur, or Bhaktapur
  Widget _buildSupportedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Light Green
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 48,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'You are in $_detectedLocation! 📍',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            '✅ GetWork supports your location (Kathmandu, Lalitpur, Bhaktapur)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'You are all set to discover nearby part-time jobs and shifts in your area!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const Spacer(),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _proceedToApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Continue to GetWork',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Screen displayed when user is outside supported locations
  Widget _buildUnsupportedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE), // Light Red
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wrong_location_rounded,
            size: 48,
            color: Color(0xFFC62828),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Location Not Supported 📍',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Thank you for using GetWork!\nGetWork currently operates only in Kathmandu, Lalitpur, and Bhaktapur.\n\nYou are currently in $_detectedLocation where this app is not supported yet.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: const [
              Text(
                'Developer — Debin Rai',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Xaie GetWork Platform',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Quit App Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _quitApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828), // Red
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.exit_to_app_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Quit App',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
