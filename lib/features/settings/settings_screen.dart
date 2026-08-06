// ============================================================
// SETTINGS SCREEN — GetWork App
// Clean, modern settings interface tailored for password-free
// Google Sign-In & Phone OTP authentication.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/user_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  // Settings State Variables
  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English';
  bool _pushNotifications = true;
  bool _jobAlerts = true;
  bool _applicationUpdates = true;

  @override
  void initState() {
    super.initState();
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

  // ── Log Out Handler ──────────────────────────────────────────
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out of GetWork?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w700)),
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

  // ── Language Selector Modal ──────────────────────────────────
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select App Language',
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('English', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              trailing: _selectedLanguage == 'English' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedLanguage = 'English');
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('नेपाली (Nepali)', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              trailing: _selectedLanguage == 'Nepali' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedLanguage = 'Nepali');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('नेपाली भाषा चाँडै उपलब्ध हुनेछ (Nepali translation coming soon)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Theme Selector Modal ─────────────────────────────────────
  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Appearance Theme',
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded, color: AppColors.primary),
              title: const Text('Light Mode (Default)', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              trailing: _selectedTheme == 'Light' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedTheme = 'Light');
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: AppColors.textSecondary),
              title: const Text('Dark Mode', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              trailing: _selectedTheme == 'Dark' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedTheme = 'Dark');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dark theme will be enabled in the upcoming release!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'user@getwork.app';
    final userPhone = _profile?.phone.isNotEmpty == true ? _profile!.phone : 'Phone verified via OTP';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Settings',
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
                  // ── Account & Authentication Status ─────────────────────────────
                  _buildSectionLabel('Connected Account'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.g_mobiledata_rounded, color: AppColors.primaryDark, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?.fullName.isNotEmpty == true ? _profile!.fullName : 'GetWork User',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$userEmail • $userPhone',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2E7D32)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Direct Google & Phone OTP Login',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── App Preferences ─────────────────────────────────────────
                  _buildSectionLabel('Preferences'),
                  const SizedBox(height: 8),
                  _buildGroupedCard([
                    _SettingTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      trailingText: _selectedLanguage,
                      onTap: _showLanguageSelector,
                    ),
                    _SettingTile(
                      icon: Icons.brightness_6_outlined,
                      title: 'Theme & Appearance',
                      trailingText: _selectedTheme,
                      onTap: _showThemeSelector,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── Notifications ───────────────────────────────────────────
                  _buildSectionLabel('Notification Settings'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          title: const Text('Push Notifications', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Receive alerts for jobs & updates', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
                          value: _pushNotifications,
                          onChanged: (val) => setState(() => _pushNotifications = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          title: const Text('Nearby Job Alerts', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Get notified when new jobs open near you', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
                          value: _jobAlerts,
                          onChanged: (val) => setState(() => _jobAlerts = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          title: const Text('Application Status Updates', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Notifications when businesses review your application', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
                          value: _applicationUpdates,
                          onChanged: (val) => setState(() => _applicationUpdates = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Support & Legal ────────────────────────────────────────
                  _buildSectionLabel('About & Support'),
                  const SizedBox(height: 8),
                  _buildGroupedCard([
                    _SettingTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About GetWork',
                      trailingText: 'v1.0.0',
                      onTap: () => _showAboutModal(),
                    ),
                    _SettingTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Contact Support',
                      onTap: () => _showHelpModal(),
                    ),
                    _SettingTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy & Terms',
                      onTap: () => _showPrivacyModal(),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Sign Out Button ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: InkWell(
                      onTap: _signOut,
                      borderRadius: BorderRadius.circular(16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildGroupedCard(List<_SettingTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final tile = tiles[i];
          final isLast = i == tiles.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(tile.icon, color: AppColors.textPrimary, size: 22),
                title: Text(
                  tile.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tile.trailingText != null)
                      Text(
                        tile.trailingText!,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
                      ),
                    const SizedBox(width: 4),
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

  void _showAboutModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About GetWork', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0 (MVP)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text(
              'GetWork is Nepal\'s map-first hiring platform connecting nearby workers with local businesses in Kathmandu, Lalitpur, and Bhaktapur.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help & Support', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.email_outlined, color: AppColors.primary),
              title: Text('Email Us', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              subtitle: Text('support@getwork.com.np'),
            ),
            const ListTile(
              leading: Icon(Icons.phone_outlined, color: AppColors.primary),
              title: Text('Hotline', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              subtitle: Text('+977 1-4200000'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: const SingleChildScrollView(
          child: Text(
            'GetWork values your privacy. Location data is used strictly to display nearby job opportunities and optimize job matching in Kathmandu. User phone numbers and profiles are shared only with authorized businesses when you explicitly apply for a job.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _SettingTile {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  _SettingTile({
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });
}
