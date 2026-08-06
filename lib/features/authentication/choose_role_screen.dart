// ============================================================
// CHOOSE ROLE SCREEN — GetWork App
// "One App, Two Roles" — Worker vs Business onboarding
// Based on: docs/UI-Images/choose_account_type
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_user_service.dart';

// ── User Role Provider (Riverpod 3 compatible) ──────────────────────
enum UserRole { worker, business }

class UserRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;

  void setRole(UserRole? role) => state = role;
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole?>(
  UserRoleNotifier.new,
);

// ── Choose Role Screen ─────────────────────────────────────────
class ChooseRoleScreen extends ConsumerWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ───────────────────────────────────────
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'How will you use GetWork?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Select your account type. Roles are permanently locked after setup.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // ── Worker Role Card ──────────────────────────────
              _RoleCard(
                icon: Icons.handyman_rounded,
                iconBg: AppColors.primary,
                title: 'I am a Worker',
                subtitle: 'Find nearby jobs & earn daily pay',
                bullets: const [
                  'Discover jobs on a live map',
                  'Apply with one tap',
                  'Get paid daily or weekly',
                  'See estimated commute time',
                ],
                isSelected: selectedRole == UserRole.worker,
                onTap: () => ref.read(userRoleProvider.notifier).setRole(UserRole.worker),
              ),
              const SizedBox(height: 16),

              // ── Business Role Card ────────────────────────────
              _RoleCard(
                icon: Icons.storefront_rounded,
                iconBg: AppColors.accent,
                title: 'I am a Business',
                subtitle: 'Post jobs & hire nearby workers fast',
                bullets: const [
                  'Post jobs in under 2 minutes',
                  'Reach workers within 1–5 km',
                  'Manage applications in one place',
                  '1-click job templates',
                ],
                isSelected: selectedRole == UserRole.business,
                onTap: () => ref.read(userRoleProvider.notifier).setRole(UserRole.business),
              ),

              const SizedBox(height: 28),

              // ── Continue Button (Role Lock On Write) ──────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedRole == null
                      ? null
                      : () async {
                          final prefs = await SharedPreferences.getInstance();

                          // Guard: check if role is already locked locally
                          final existingRole = prefs.getString('user_role');
                          if (existingRole != null && existingRole.isNotEmpty) {
                            if (context.mounted) {
                              context.go(existingRole == 'worker' ? '/home' : '/business');
                            }
                            return;
                          }

                          final chosenRoleStr =
                              selectedRole == UserRole.worker ? 'worker' : 'business';

                          // Write role to Firestore (source of truth)
                          final uid = AuthService.uid;
                          if (uid != null) {
                            await FirestoreUserService.saveUser(
                              uid: uid,
                              phone: AuthService.phone ?? '',
                              role: chosenRoleStr,
                            );
                          }

                          // Cache locally for offline fast-path
                          await prefs.setBool('seen_onboarding', true);
                          await prefs.setString('user_role', chosenRoleStr);
                          await prefs.setString(
                            'role_locked_at',
                            DateTime.now().toIso8601String(),
                          );

                          if (context.mounted) {
                            if (selectedRole == UserRole.worker) {
                              context.go('/home');
                            } else {
                              context.go('/business');
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: selectedRole == null ? 0 : 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedRole == null
                            ? 'Select a role to continue'
                            : selectedRole == UserRole.worker
                                ? 'Find Jobs Nearby'
                                : 'Start Hiring Workers',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (selectedRole != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role Selection Card Component ──────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.shadowLight,
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ...bullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primary : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
