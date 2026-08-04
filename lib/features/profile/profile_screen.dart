// ============================================================
// PROFILE SCREEN — GetWork App
// Loads real user data from UserProfileService, links to ManageProfileScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning from ManageProfileScreen
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  String _getInitials() {
    final first = _profile?.firstName ?? '';
    final last  = _profile?.lastName ?? '';
    if (first.isEmpty && last.isEmpty) return '?';
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : 'Your Profile';
    final displayPhone = _profile?.phone.isNotEmpty == true
        ? _profile!.phone
        : 'No phone added';

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── User Info Header Card ──────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      await context.push('/manage-profile');
                      // Refresh after returning
                      _loadProfile();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadowLight, blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar with initials
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withValues(alpha: 0.85), AppColors.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, size: 13, color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayPhone,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_profile?.gender != null || _profile?.age != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      [
                                        if (_profile?.gender != null) _profile!.gender!,
                                        if (_profile?.age != null) 'Age ${_profile!.age}',
                                      ].join(' · '),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_rounded, color: AppColors.textHint, size: 18),
                        ],
                      ),
                    ),
                  ),

                  // Role badge
                  if (_profile?.role != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _profile!.role == 'business' ? AppColors.accentContainer : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _profile!.role == 'business' ? '🏢 Business Account' : '💼 Worker Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _profile!.role == 'business' ? AppColors.accentDark : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Account Section ───────────────────────────────────────
                  _buildSectionLabel('Account'),
                  const SizedBox(height: 8),
                  _buildGroupedCard(context, [
                    _ProfileTileData(
                      icon: Icons.person_outline_rounded,
                      title: 'Manage Profile',
                      onTap: () async {
                        await context.push('/manage-profile');
                        _loadProfile();
                      },
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
                  _buildGroupedCard(context, [
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
                  _buildGroupedCard(context, [
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

  Widget _buildGroupedCard(BuildContext context, List<_ProfileTileData> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          final isLast = index == tiles.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(tile.icon, color: tile.iconColor ?? AppColors.textPrimary, size: 22),
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
                      Text(tile.trailingText!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    if (tile.trailingText != null && tile.showChevron) const SizedBox(width: 6),
                    if (tile.showChevron)
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                  ],
                ),
                onTap: tile.onTap,
              ),
              if (!isLast)
                const Divider(height: 1, thickness: 0.8, indent: 52, endIndent: 16, color: AppColors.divider),
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

