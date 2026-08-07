// ============================================================
// POST JOB SCREEN — GetWork App
// Business users post new shift jobs directly to Supabase
// Includes:
// - Required Contact Phone Number & Optional Email
// - Salary dropdown (/hour, /day, /week, /month, Fixed)
// - Rs. currency display
// - Reverse-geocoded location picker (map + place name)
// - Custom slot-machine time picker wheel (AM/PM non-looping)
// - Draft auto-save & explicit dialog on back navigation
// - Bottom bar with Cancel & Confirm Post buttons
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/draft_service.dart';
import '../../core/services/supabase_jobs_service.dart';
import '../../models/job_model.dart';
import '../jobs/jobs_provider.dart';
import 'location_picker_sheet.dart';
import 'time_picker_sheet.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  final JobType type;
  final Map<String, dynamic>? initialDraft;

  const PostJobScreen({
    super.key,
    this.type = JobType.scheduled,
    this.initialDraft,
  });

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSubmitted = false;

  // Draft ID if resuming
  String? _draftId;

  // ── Form Controllers ────────────────────────────────────────
  late final TextEditingController _titleController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _salaryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _requirementsController;
  late final TextEditingController _workersNeededController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  // ── Form State ──────────────────────────────────────────────
  String _selectedCategory = 'retail';
  bool _isCustomCategory = false;
  String _selectedSalaryType = 'daily';
  String _selectedLocation = '';
  double _locationLat = 27.7172;
  double _locationLng = 85.3240;
  DateTime _selectedDate = DateTime.now();
  String _shiftStart = '09:00 AM';
  String _shiftEnd = '05:00 PM';
  bool _isUrgent = false;
  int _selectedDeadlineDays = 3;
  int _postExpiryDays = 7; // 1–15 days, post auto-expires & saves to draft

  @override
  void initState() {
    super.initState();
    final d = widget.initialDraft;
    _draftId = d?['id'] as String?;

    _titleController = TextEditingController(text: d?['title'] as String? ?? '');
    _businessNameController =
        TextEditingController(text: d?['businessName'] as String? ?? '');
    _salaryController =
        TextEditingController(text: d?['salary'] as String? ?? '');
    _descriptionController =
        TextEditingController(text: d?['description'] as String? ?? '');
    _requirementsController =
        TextEditingController(text: d?['requirements'] as String? ?? '');
    _workersNeededController =
        TextEditingController(text: d?['workersNeeded'] as String? ?? '1');
    _customCategoryController =
        TextEditingController(text: d?['customCategory'] as String? ?? '');
    _phoneController =
        TextEditingController(text: d?['phone'] as String? ?? '');
    _emailController =
        TextEditingController(text: d?['email'] as String? ?? '');

    if (d != null) {
      _selectedCategory = d['category'] as String? ?? 'retail';
      _isCustomCategory = _selectedCategory == 'custom';
      _selectedSalaryType = d['salaryType'] as String? ?? 'daily';
      _selectedLocation = d['location'] as String? ?? '';
      _locationLat = (d['lat'] as num?)?.toDouble() ?? 27.7172;
      _locationLng = (d['lng'] as num?)?.toDouble() ?? 85.3240;
      _shiftStart = d['shiftStart'] as String? ?? '09:00 AM';
      _shiftEnd = d['shiftEnd'] as String? ?? '05:00 PM';
      _isUrgent = d['isUrgent'] as bool? ?? false;
      _selectedDeadlineDays = d['deadlineDays'] as int? ?? 3;
      _postExpiryDays = d['postExpiryDays'] as int? ?? 7;
    } else {
      // Auto-fill from business profile settings if available
      final settings = ref.read(appSettingsProvider);
      if (settings.businessName.isNotEmpty && settings.businessName != 'My Business') {
        _businessNameController.text = settings.businessName;
      }
      if (settings.businessPhone.isNotEmpty) {
        _phoneController.text = settings.businessPhone;
      }
      if (settings.businessLocation.isNotEmpty) {
        _selectedLocation = settings.businessLocation;
      }
      if (widget.type == JobType.instant) {
        _isUrgent = true;
      }
    }
  }

  // ── Type display helpers ────────────────────────────────────
  String get _jobTypeName {
    switch (widget.type) {
      case JobType.instant:
        return 'Instant Job';
      case JobType.scheduled:
        return 'Scheduled Job';
      case JobType.skilled:
        return 'Skilled / Project Job';
    }
  }

  String get _jobTypeDescription {
    switch (widget.type) {
      case JobType.instant:
        return 'First qualified worker to accept gets the job immediately';
      case JobType.scheduled:
        return 'Post now — review applicants and confirm one';
      case JobType.skilled:
        return 'Requires qualifications — review and select the best candidate';
    }
  }

  IconData get _jobTypeIcon {
    switch (widget.type) {
      case JobType.instant:
        return Icons.bolt_rounded;
      case JobType.scheduled:
        return Icons.calendar_month_rounded;
      case JobType.skilled:
        return Icons.workspace_premium_rounded;
    }
  }

  List<Color> get _jobTypeGradient {
    switch (widget.type) {
      case JobType.instant:
        return [const Color(0xFFFF6B35), const Color(0xFFE53935)];
      case JobType.scheduled:
        return [const Color(0xFF0D9488), const Color(0xFF0F766E)];
      case JobType.skilled:
        return [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];
    }
  }

  final Map<String, String> _categoryLabels = {
    'delivery': 'Delivery',
    'retail': 'Retail',
    'food': 'Food & Beverage',
    'construction': 'Construction',
    'cleaning': 'Cleaning',
    'tech': 'Tech',
    'events': 'Events',
    'education': 'Education',
    'healthcare': 'Healthcare',
    'security': 'Security',
    'custom': 'Custom (specify below)',
  };

  final Map<String, String> _salaryTypeLabels = {
    'hourly': '/hour (Hourly)',
    'daily': '/day (Daily)',
    'weekly': '/week (Weekly)',
    'monthly': '/month (Monthly)',
    'fixed': 'Fixed Rate',
  };

  @override
  void dispose() {
    _autoSaveDraft();
    _titleController.dispose();
    _businessNameController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _workersNeededController.dispose();
    _customCategoryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDraftMap() {
    return {
      if (_draftId != null) 'id': _draftId,
      'title': _titleController.text.trim(),
      'businessName': _businessNameController.text.trim(),
      'salary': _salaryController.text.trim(),
      'salaryType': _selectedSalaryType,
      'category': _selectedCategory,
      'customCategory': _customCategoryController.text.trim(),
      'location': _selectedLocation,
      'lat': _locationLat,
      'lng': _locationLng,
      'description': _descriptionController.text.trim(),
      'requirements': _requirementsController.text.trim(),
      'workersNeeded': _workersNeededController.text.trim(),
      'shiftStart': _shiftStart,
      'shiftEnd': _shiftEnd,
      'isUrgent': _isUrgent,
      'deadlineDays': _selectedDeadlineDays,
      'type': widget.type.name,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'postExpiryDays': _postExpiryDays,
    };
  }

  bool get _hasAnyData {
    return _titleController.text.trim().isNotEmpty ||
        _salaryController.text.trim().isNotEmpty ||
        _selectedLocation.isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _autoSaveDraft() async {
    if (_isSubmitted || !_hasAnyData) return;
    await DraftService.saveDraft(_buildDraftMap());
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _openLocationPicker() async {
    final result = await LocationPickerSheet.show(
      context,
      initial: _selectedLocation.isEmpty
          ? null
          : LatLng(_locationLat, _locationLng),
      initialLabel: _selectedLocation.isEmpty ? null : _selectedLocation,
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result.label;
        _locationLat = result.latLng.latitude;
        _locationLng = result.latLng.longitude;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final res = await TimePickerSheet.show(context, _shiftStart);
    if (res != null) setState(() => _shiftStart = res);
  }

  Future<void> _pickEndTime() async {
    final res = await TimePickerSheet.show(context, _shiftEnd);
    if (res != null) setState(() => _shiftEnd = res);
  }

  /// Clean, spacious dialog shown when leaving page with unfinished form
  Future<bool> _onWillPop() async {
    if (_isSubmitted || !_hasAnyData) return true;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text(
              'Save Job Draft?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have unsaved changes in this job post. Save as a draft to resume anytime within 4 days.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Column(
            children: [
              // Save Draft Button (Primary)
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop('save'),
                    icon: const Icon(Icons.bookmark_rounded, size: 18),
                    label: const Text('Save Draft'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Discard Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop('discard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cancel / Keep Editing
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop('cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keep Editing'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (action == 'save') {
      await _autoSaveDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job saved to drafts for 4 days!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return true;
    } else if (action == 'discard') {
      if (_draftId != null) {
        await DraftService.deleteDraft(_draftId!);
      }
      return true;
    }
    return false;
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please tap and select a job location on the map'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final categoryToSave = _isCustomCategory
        ? (_customCategoryController.text.trim().toLowerCase().replaceAll(' ', '_'))
        : _selectedCategory;

    final salary = double.tryParse(_salaryController.text.trim()) ?? 700.0;
    final workersNeeded = int.tryParse(_workersNeededController.text.trim()) ?? 1;

    final requirements = _requirementsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    var desc = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (phone.isNotEmpty || email.isNotEmpty) {
      desc += '\n\nContact: Phone: $phone ${email.isNotEmpty ? '| Email: $email' : ''}';
    }

    final success = await SupabaseJobsService.postJob(
      title: _titleController.text.trim(),
      category: categoryToSave,
      salary: salary,
      salaryType: _selectedSalaryType,
      address: _selectedLocation,
      latitude: _locationLat,
      longitude: _locationLng,
      jobStartDate: _selectedDate,
      shiftStartTime: _shiftStart,
      shiftEndTime: _shiftEnd,
      workersNeeded: workersNeeded,
      businessName: _businessNameController.text.trim(),
      description: desc,
      requirements: requirements,
      isUrgent: _isUrgent,
      type: widget.type,
      deadlineDays: _selectedDeadlineDays,
      postExpiryDays: _postExpiryDays,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      _isSubmitted = true;
      if (_draftId != null) {
        await DraftService.deleteDraft(_draftId!);
      }

      ref.read(allJobsProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job posted successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to post job. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            'Post $_jobTypeName',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Job Type Banner ─────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _jobTypeGradient.map((c) => c.withValues(alpha: 0.12)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _jobTypeGradient.first.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _jobTypeGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_jobTypeIcon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _jobTypeName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _jobTypeGradient.first,
                              ),
                            ),
                            Text(
                              _jobTypeDescription,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: _jobTypeGradient.first.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Urgent Banner Toggle ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _isUrgent
                        ? const LinearGradient(
                            colors: [Color(0xFFFFF3ED), Color(0xFFFFE8D6)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade50, Colors.grey.shade100],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isUrgent
                          ? const Color(0xFFFF6B35).withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: _isUrgent ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark as Urgent',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: _isUrgent
                                    ? AppColors.accentDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Urgent jobs appear highlighted and first',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isUrgent,
                        onChanged: (v) => setState(() => _isUrgent = v),
                        activeThumbColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Job Title ──────────────────────────────────────
                const _SectionLabel(label: 'Job Title *'),
                _StyledField(
                  controller: _titleController,
                  hint: 'e.g. Supermarket Cashier',
                  validator: (v) => v!.trim().isEmpty ? 'Enter a job title' : null,
                  icon: Icons.work_rounded,
                ),
                const SizedBox(height: 16),

                // ── Business Name ──────────────────────────────────
                const _SectionLabel(label: 'Business Name *'),
                _StyledField(
                  controller: _businessNameController,
                  hint: 'Your business name',
                  validator: (v) => v!.trim().isEmpty ? 'Enter business name' : null,
                  icon: Icons.business_rounded,
                ),
                const SizedBox(height: 16),

                // ── Category ───────────────────────────────────────
                const _SectionLabel(label: 'Category'),
                _StyledDropdown<String>(
                  value: _selectedCategory,
                  items: _categoryLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedCategory = v!;
                    _isCustomCategory = v == 'custom';
                  }),
                  icon: Icons.category_rounded,
                ),
                if (_isCustomCategory) ...[
                  const SizedBox(height: 10),
                  _StyledField(
                    controller: _customCategoryController,
                    hint: 'e.g. Pet Grooming, Florist, Event Photography...',
                    validator: (v) => _isCustomCategory && v!.trim().isEmpty
                        ? 'Enter your custom category'
                        : null,
                    icon: Icons.edit_rounded,
                  ),
                ],
                const SizedBox(height: 16),

                // ── Pay Rate (Rs.) & Salary Dropdown ─────────────────
                const _SectionLabel(label: 'Pay Rate (Rs.) *'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _StyledField(
                        controller: _salaryController,
                        hint: 'e.g. 700',
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Enter pay rate' : null,
                        icon: Icons.payments_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _StyledDropdown<String>(
                        value: _selectedSalaryType,
                        items: _salaryTypeLabels.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSalaryType = v!),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Job Location Picker ─────────────────────────────
                const _SectionLabel(label: 'Job Location *'),
                GestureDetector(
                  onTap: _openLocationPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedLocation.isEmpty
                            ? AppColors.border
                            : AppColors.primary,
                        width: _selectedLocation.isEmpty ? 1.0 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedLocation.isEmpty
                              ? Icons.add_location_alt_rounded
                              : Icons.location_on_rounded,
                          color: _selectedLocation.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedLocation.isEmpty
                                ? 'Tap to choose location on map'
                                : _selectedLocation,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: _selectedLocation.isEmpty
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                              fontSize: 14,
                              color: _selectedLocation.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.map_rounded,
                          color: _selectedLocation.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Shift Date & Times ─────────────────────────────
                const _SectionLabel(label: 'Shift Date & Time'),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Start Time',
                        time: _shiftStart,
                        onTap: _pickStartTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerButton(
                        label: 'End Time',
                        time: _shiftEnd,
                        onTap: _pickEndTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Workers Needed ─────────────────────────────────
                const _SectionLabel(label: 'Workers Needed *'),
                _StyledField(
                  controller: _workersNeededController,
                  hint: '1',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter number of workers' : null,
                  icon: Icons.people_rounded,
                ),
                const SizedBox(height: 16),

                // ── Contact Info (Phone Required, Email Optional) ───
                const _SectionLabel(label: 'Contact Information'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StyledField(
                        controller: _phoneController,
                        hint: 'Phone No. *',
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Phone number required' : null,
                        icon: Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StyledField(
                        controller: _emailController,
                        hint: 'Email (Optional)',
                        keyboardType: TextInputType.emailAddress,
                        icon: Icons.email_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Deadline Selector (Scheduled & Skilled Only) ───
                if (widget.type != JobType.instant) ...[
                  const _SectionLabel(label: 'Application Deadline'),
                  Row(
                    children: [1, 3, 5, 7].map((days) {
                      final isSelected = _selectedDeadlineDays == days;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDeadlineDays = days),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0D9488),
                                        Color(0xFF0F766E)
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$days ${days == 1 ? 'Day' : 'Days'}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Description ────────────────────────────────────
                const _SectionLabel(label: 'Job Description'),
                _StyledField(
                  controller: _descriptionController,
                  hint: 'Describe the job role and what workers will do...',
                  maxLines: 3,
                  icon: Icons.description_rounded,
                ),
                const SizedBox(height: 16),

                // ── Requirements (Skilled & Scheduled) ────────────
                if (widget.type == JobType.skilled ||
                    widget.type == JobType.scheduled) ...[
                  _SectionLabel(
                    label: widget.type == JobType.skilled
                        ? 'Required Qualifications & Experience (one per line)'
                        : 'Requirements (optional, one per line)',
                  ),
                  _StyledField(
                    controller: _requirementsController,
                    hint: widget.type == JobType.skilled
                        ? 'e.g.\n2+ years barista experience\nFood hygiene certificate\nGood communication'
                        : 'e.g.\nOwn motorcycle\nValid driving license',
                    maxLines: 3,
                    icon: Icons.checklist_rounded,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Post Expiry (ALL job types) ──────────────────────
                _PostExpirySection(
                  expiryDays: _postExpiryDays,
                  onChanged: (v) => setState(() => _postExpiryDays = v),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Bottom Action Bar with Cancel & Confirm Post Buttons ─────
        bottomNavigationBar: Container(
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) {
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Transform.rotate(
                    angle: -0.01,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _jobTypeGradient),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _jobTypeGradient.first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitJob,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isLoading ? 'Posting...' : 'Confirm & Post Job',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
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

// ── Time Picker Button Widget ──────────────────────────────────
class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.unfold_more_rounded,
                    color: AppColors.textSecondary, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Label ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Styled Text Field ─────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? prefixText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.prefixText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

// ── Styled Dropdown ───────────────────────────────────────────
class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final IconData icon;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// POST EXPIRY SECTION WIDGET
// Allows business to set how many days a post stays live (1–15).
// After the deadline: post is auto-removed from listings and
// saved to Drafts so it can be re-posted easily.
// ════════════════════════════════════════════════════════════
class _PostExpirySection extends StatelessWidget {
  const _PostExpirySection({
    required this.expiryDays,
    required this.onChanged,
  });

  final int expiryDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final expiryDate = DateTime.now().add(Duration(days: expiryDays));
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final expiryStr =
        '${expiryDate.day} ${monthNames[expiryDate.month - 1]} ${expiryDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Divider ────────────────────────────────────────────
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0x000D9488),
              Color(0xFF0D9488),
              Color(0x000D9488),
            ]),
          ),
        ),

        // ── Section header ─────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.timer_outlined,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Post Expiry',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$expiryDays ${expiryDays == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Expires on $expiryStr — max 15 days',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // ── Slider ─────────────────────────────────────────────
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF0D9488),
            inactiveTrackColor: const Color(0xFFE0F2F1),
            thumbColor: const Color(0xFF0D9488),
            overlayColor: const Color(0x220D9488),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: expiryDays.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),

        // ── Quick-pick day pills ────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 3, 5, 7, 10, 14, 15].map((d) {
            final selected = expiryDays == d;
            return GestureDetector(
              onTap: () => onChanged(d),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF0D9488)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '$d ${d == 1 ? 'day' : 'days'}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // ── Info card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0D9488), width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF0F766E), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'When this post expires it is automatically removed from listings and saved to your Drafts for 4 days so you can re-post it quickly.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF0F5132),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
