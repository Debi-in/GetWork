// ============================================================
// PROFILE SCREEN — GetWork App
// Redesigned with grouped section cards, user avatar card, and preferences
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Info Header Card ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Ronald Richards',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ronaldrichards@gmail.com',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Account Section ───────────────────────────────────────
            _buildSectionLabel('Account'),
            const SizedBox(height: 8),
            _buildGroupedCard([
              _ProfileTileData(
                icon: Icons.person_outline_rounded,
                title: 'Manage Profile',
                onTap: () {},
              ),
              _ProfileTileData(
                icon: Icons.lock_outline_rounded,
                title: 'Password & Security',
                onTap: () {},
              ),
              _ProfileTileData(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
              _ProfileTileData(
                icon: Icons.language_rounded,
                title: 'Language',
                trailingText: 'English',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 20),

            // ── Preferences Section ───────────────────────────────────
            _buildSectionLabel('Preferences'),
            const SizedBox(height: 8),
            _buildGroupedCard([
              _ProfileTileData(
                icon: Icons.info_outline_rounded,
                title: 'About Us',
                onTap: () {},
              ),
              _ProfileTileData(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                trailingText: 'Light',
                onTap: () {},
              ),
              _ProfileTileData(
                icon: Icons.assignment_outlined,
                title: 'My Applications',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 20),

            // ── Support Section ───────────────────────────────────────
            _buildSectionLabel('Support'),
            const SizedBox(height: 8),
            _buildGroupedCard([
              _ProfileTileData(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: () {},
              ),
              _ProfileTileData(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                showChevron: false,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildGroupedCard(List<_ProfileTileData> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          final isLast = index == tiles.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(
                  tile.icon,
                  color: tile.iconColor ?? AppColors.textPrimary,
                  size: 22,
                ),
                title: Text(
                  tile.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tile.titleColor ?? AppColors.textPrimary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tile.trailingText != null)
                      Text(
                        tile.trailingText!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (tile.trailingText != null && tile.showChevron)
                      const SizedBox(width: 6),
                    if (tile.showChevron)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                  ],
                ),
                onTap: tile.onTap,
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 52,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileTileData {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  _ProfileTileData({
    required this.icon,
    required this.title,
    this.trailingText,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });
}
