import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_user_service.dart';
import '../../router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // ── Step 1: Check Firebase Auth ──────────────────────────────
    if (!AuthService.isLoggedIn) {
      // Not logged in → check if they have seen onboarding yet
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      if (!mounted) return;
      if (seenOnboarding) {
        context.go(AppRoutes.login);
      } else {
        context.go(AppRoutes.onboarding);
      }
      return;
    }

    // ── Step 2: Logged in → fetch Firestore role ──────────────────
    final uid = AuthService.uid!;
    final role = await FirestoreUserService.getRole(uid);
    if (!mounted) return;

    if (role != null && role.isNotEmpty) {
      // Role already locked → go straight to the right home
      // Also cache locally for speed on next cold start
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      if (!mounted) return;
      if (role == 'business') {
        context.go(AppRoutes.businessDashboard);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      // Logged in but role not set yet → choose role
      context.go(AppRoutes.chooseRole);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5B8A6F),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'GetWork',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find nearby jobs. Hire trusted workers.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
