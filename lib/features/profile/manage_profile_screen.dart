// ============================================================
// MANAGE PROFILE SCREEN — GetWork App
// Full profile editor: Name, Phone, Gender, Age, Experience, Skills
// Beautiful premium UI with inline editing & animated save states
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/user_profile_service.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _ageController       = TextEditingController();

  String? _selectedGender;
  String? _selectedExperience;
  String? _selectedSkill;
  String? _userRole;

  bool _isLoading  = true;
  bool _isSaving   = false;
  bool _hasChanges = false;

  late AnimationController _saveAnimController;
  late Animation<double> _saveScaleAnim;

  static const List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const List<String> _experiences = [
    'No experience',
    'Less than 1 year',
    '1–2 years',
    '2–5 years',
    '5+ years',
  ];
  static const List<String> _skills = [
    'Delivery & Courier',
    'Retail & Sales',
    'Food & Beverage',
    'Construction & Labor',
    'Cleaning & Housekeeping',
    'Security & Guard',
    'IT & Tech Support',
    'Events & Promotion',
    'Teaching & Tutoring',
    'Healthcare & Nursing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _saveScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _saveAnimController, curve: Curves.easeInOut),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.getProfile();
    if (mounted) {
      setState(() {
        _firstNameController.text = profile?.firstName ?? '';
        _lastNameController.text  = profile?.lastName ?? '';
        _phoneController.text     = profile?.phone ?? '';
        _ageController.text       = profile?.age != null ? profile!.age.toString() : '';
        _selectedGender     = profile?.gender;
        _selectedExperience = profile?.experience;
        _selectedSkill      = profile?.primarySkill;
        _userRole           = profile?.role ?? 'worker';
        _isLoading = false;
      });
      for (final c in [_firstNameController, _lastNameController, _phoneController, _ageController]) {
        c.addListener(() {
          if (!_hasChanges && mounted) setState(() => _hasChanges = true);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _saveAnimController.forward().then((_) => _saveAnimController.reverse());
    setState(() => _isSaving = true);

    try {
      await UserProfileService.saveBasicProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _userRole ?? 'worker',
      );

      final age = int.tryParse(_ageController.text.trim());
      if (age != null || _selectedGender != null) {
        await UserProfileService.updateApplicationProfile(
          age: age ?? 0,
          gender: _selectedGender ?? '',
          experience: _selectedExperience,
          primarySkill: _selectedSkill,
        );
      }

      if (mounted) {
        setState(() { _isSaving = false; _hasChanges = false; });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Profile saved!', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _getInitials() {
    final f = _firstNameController.text.trim();
    final l = _lastNameController.text.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Manage Profile',
          style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        actions: [
          if (_hasChanges && !_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withValues(alpha: 0.85), AppColors.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(),
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '${_firstNameController.text} ${_lastNameController.text}'.trim().isEmpty
                            ? 'Your Name'
                            : '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    if (_userRole != null)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: _userRole == 'business'
                                ? AppColors.businessBadgeGradient
                                : AppColors.workerBadgeGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _userRole == 'business' ? Icons.storefront_rounded : Icons.handyman_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _userRole == 'business' ? 'Business' : 'Worker',
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
                      ),
                    const SizedBox(height: 28),

                    // Personal Info
                    _buildSectionHeader('Personal Information', Icons.person_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildField(label: 'First Name', controller: _firstNameController, hint: 'e.g. Debin', icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null),
                      const SizedBox(height: 16),
                      _buildField(label: 'Last Name', controller: _lastNameController, hint: 'e.g. Rai', icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null),
                      const SizedBox(height: 16),
                      _buildField(label: 'Phone Number', controller: _phoneController, hint: '9841234567', icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => (v == null || v.trim().length < 8) ? 'Enter valid phone number' : null),
                    ]),
                    const SizedBox(height: 22),

                    // Identity
                    _buildSectionHeader('Identity', Icons.badge_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildField(label: 'Age', controller: _ageController, hint: 'e.g. 22', icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final a = int.tryParse(v);
                            if (a == null || a < 16 || a > 80) return 'Enter valid age (16–80)';
                          }
                          return null;
                        }),
                      const SizedBox(height: 16),
                      _buildDropdown(label: 'Gender', icon: Icons.wc_rounded, items: _genders, value: _selectedGender, hint: 'Select gender',
                        onChanged: (v) => setState(() { _selectedGender = v; _hasChanges = true; })),
                    ]),
                    const SizedBox(height: 22),

                    // Work Profile
                    _buildSectionHeader('Work Profile', Icons.work_outline_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildDropdown(label: 'Experience Level', icon: Icons.timeline_rounded, items: _experiences, value: _selectedExperience, hint: 'Select experience',
                        onChanged: (v) => setState(() { _selectedExperience = v; _hasChanges = true; })),
                      const SizedBox(height: 16),
                      _buildDropdown(label: 'Primary Skill / Job Type', icon: Icons.star_outline_rounded, items: _skills, value: _selectedSkill, hint: 'Select your main skill',
                        onChanged: (v) => setState(() { _selectedSkill = v; _hasChanges = true; })),
                    ]),
                    const SizedBox(height: 28),

                    // Save Button
                    ScaleTransition(
                      scale: _saveScaleAnim,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.border,
                            foregroundColor: Colors.white,
                            elevation: _hasChanges ? 4 : 0,
                            shadowColor: AppColors.primary.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save_rounded, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      _hasChanges ? 'Save Changes' : 'Profile Up to Date',
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadowLight, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.textHint, fontSize: 14),
    prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 2)),
  );

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) { if (!_hasChanges && mounted) setState(() => _hasChanges = true); },
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: _inputDec(hint, icon),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          decoration: _inputDec(hint, icon),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          dropdownColor: Colors.white,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
        ),
      ],
    );
  }
}
