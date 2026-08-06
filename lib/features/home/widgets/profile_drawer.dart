// ============================================================
// PROFILE DRAWER — GetWork App
// Dedicated side drawer for user profile, role mode switching,
// and navigation options
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../authentication/choose_role_screen.dart';
import '../../jobs/jobs_provider.dart';

class ProfileDrawer extends ConsumerWidget {
  final void Function(int index) onSelectNavIndex;
  final VoidCallback onShowHelp;

  const ProfileDrawer({
    super.key,
    required this.onSelectNavIndex,
    required this.onShowHelp,
  });



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final isWorker = role != UserRole.business;
    final appliedCount = ref.watch(appliedJobsProvider).length;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with Rich 3-Stop Gradient ────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F5132),
                    Color(0xFF0D9488),
                    Color(0xFF14B8A6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dedicated Back Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close Menu',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Avatar circle with app logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => const Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'GetWork User',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'user@getwork.app',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role badge gradient pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isWorker
                            ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                            : [const Color(0xFFF97316), const Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWorker
                              ? Icons.handyman_rounded
                              : Icons.storefront_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isWorker ? 'Worker Mode' : 'Business Mode',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _statBadge(
                        Icons.work_history_rounded,
                        '$appliedCount',
                        'Applied',
                      ),
                      const SizedBox(width: 10),
                      _statBadge(Icons.star_rounded, '4.8', 'Rating'),
                      const SizedBox(width: 10),
                      _statBadge(
                        Icons.verified_user_rounded,
                        '0',
                        'Hired',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Menu Items
            _drawerItem(
              Icons.person_outline_rounded,
              'My Profile',
              () {
                Navigator.of(context).pop();
                context.push('/profile');
              },
            ),
            _drawerItem(
              Icons.assignment_outlined,
              'My Applications',
              () {
                Navigator.of(context).pop();
                onSelectNavIndex(3);
              },
            ),

            _drawerItem(
              Icons.settings_outlined,
              'Settings',
              () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
            _drawerItem(
              Icons.help_outline_rounded,
              'Help & Support',
              () {
                Navigator.of(context).pop();
                onShowHelp();
              },
            ),

            const Spacer(),

            const Divider(height: 1, color: AppColors.border),
            _drawerItem(
              Icons.logout_rounded,
              'Sign Out',
              () async {
                Navigator.of(context).pop();
                // Clear local role cache
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_role');
                await prefs.remove('role_locked_at');
                // Firebase sign out
                await AuthService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              color: Colors.red,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: (color ?? AppColors.primary).withValues(alpha: 0.08),
        highlightColor: (color ?? AppColors.primary).withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (color ?? AppColors.primary).withValues(alpha: 0.12),
                      (color ?? AppColors.primary).withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: (color ?? AppColors.textHint).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
