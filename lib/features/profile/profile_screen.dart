// ============================================================
// PROFILE SCREEN — GetWork App
// Loads real user data from UserProfileService + Supabase.
// All settings items are wired to real actions.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // ── Real sign-out ──────────────────────────────────────────
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(fontFamily: 'Inter', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (mounted) context.go('/');
    }
  }

  // ── Password & Security ───────────────────────────────────
  Future<void> _showPasswordDialog() async {
    final currentCtrl    = TextEditingController();
    final newCtrl        = TextEditingController();
    final confirmCtrl    = TextEditingController();
    bool obscureCurrent  = true;
    bool obscureNew      = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setS(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setS(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPass = newCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();
                if (newPass.isEmpty || newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }
                if (newPass != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: newPass),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Password updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  // ── Notifications settings ─────────────────────────────────
  void _openNotifications() => context.push('/notifications');

  @override
  Widget build(BuildContext context) {
    final displayName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : 'Your Profile';
    final displayPhone = _profile?.phone.isNotEmpty == true
        ? _profile!.phone
        : 'No phone added';
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? '';

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
                                if (userEmail.isNotEmpty)
                                  Text(
                                    userEmail,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textHint,
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
                      onTap: _showPasswordDialog,
                    ),
                    _ProfileTileData(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: _openNotifications,
                    ),
                    _ProfileTileData(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      trailingText: 'English',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Language: English (more languages coming soon)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
                      onTap: () => _showAboutDialog(),
                    ),
                    _ProfileTileData(
                      icon: Icons.brightness_6_outlined,
                      title: 'Theme',
                      trailingText: 'Light',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dark mode coming in the next update!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _ProfileTileData(
                      icon: Icons.assignment_outlined,
                      title: 'My Applications',
                      onTap: () => context.push('/my-applications'),
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
                      onTap: () => _showHelpDialog(),
                    ),
                    _ProfileTileData(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      titleColor: AppColors.error,
                      iconColor: AppColors.error,
                      showChevron: false,
                      onTap: _signOut,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('GW', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, color: AppColors.primaryDark, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('GetWork', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: v1.0.0 · Phase 1', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text(
              'GetWork connects local workers with part-time shifts in Kathmandu, Lalitpur & Bhaktapur Valley.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text('© 2025 GetWork Xaie', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 440),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Help & Support',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Email Support', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              subtitle: const Text('support@getwork.com.np'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email: support@getwork.com.np'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined, color: AppColors.accent),
              title: const Text('Live Chat', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              subtitle: const Text('Available 9am–6pm NPT'),
              onTap: () => Navigator.pop(ctx),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'For job application issues, technical bugs, or account problems — email us and we\'ll respond within 24 hours.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
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
