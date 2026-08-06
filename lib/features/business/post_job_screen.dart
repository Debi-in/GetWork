// ============================================================
// POST JOB SCREEN — GetWork App
// Business users post new shift jobs directly to Supabase
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_jobs_service.dart';
import '../jobs/jobs_provider.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ── Form Controllers ────────────────────────────────────────
  final _titleController = TextEditingController();
  final _businessNameController = TextEditingController(text: 'Himalayan Mart');
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _workersNeededController = TextEditingController(text: '1');

  // ── Form State ──────────────────────────────────────────────
  String _selectedCategory = 'retail';
  String _selectedSalaryType = 'daily';
  String _selectedLocation = 'Patan Dhoka, Lalitpur';
  DateTime _selectedDate = DateTime.now();
  String _shiftStart = '09:00 AM';
  String _shiftEnd = '05:00 PM';
  bool _isUrgent = false;

  final Map<String, String> _categoryLabels = {
    'delivery': 'Delivery',
    'retail': 'Retail',
    'food': 'Food & Beverage',
    'construction': 'Construction',
    'cleaning': 'Cleaning',
    'tech': 'Tech',
    'events': 'Events',
  };

  final Map<String, (double, double)> _locationCoords = {
    'Thamel, Kathmandu': (27.7152, 85.3123),
    'Naxal, Kathmandu': (27.7192, 85.3229),
    'New Baneshwor, Kathmandu': (27.6858, 85.3431),
    'Patan Dhoka, Lalitpur': (27.6766, 85.3184),
    'Pulchowk, Lalitpur': (27.6780, 85.3188),
    'Durbar Square, Bhaktapur': (27.6710, 85.4298),
    'Suryabinayak, Bhaktapur': (27.6700, 85.4510),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _businessNameController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _workersNeededController.dispose();
    super.dispose();
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

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final coords = _locationCoords[_selectedLocation] ??
        (27.7172, 85.3240); // Default Kathmandu
    final salary = double.tryParse(_salaryController.text.trim()) ?? 700.0;
    final workersNeeded = int.tryParse(_workersNeededController.text.trim()) ?? 1;

    final requirements = _requirementsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final success = await SupabaseJobsService.postJob(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      salary: salary,
      salaryType: _selectedSalaryType,
      address: _selectedLocation,
      latitude: coords.$1,
      longitude: coords.$2,
      jobStartDate: _selectedDate,
      shiftStartTime: _shiftStart,
      shiftEndTime: _shiftEnd,
      workersNeeded: workersNeeded,
      businessName: _businessNameController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: requirements,
      isUrgent: _isUrgent,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Refresh the jobs list
      ref.read(allJobsProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job posted successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to post job. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Post'),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Urgent Banner Toggle ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isUrgent
                      ? AppColors.accentContainer
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
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
                          Text(
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

              // ── Job Title ──────────────────────────────────────────
              _SectionLabel(label: 'Job Title'),
              _StyledField(
                controller: _titleController,
                hint: 'e.g. Supermarket Cashier',
                validator: (v) => v!.trim().isEmpty ? 'Enter a job title' : null,
                icon: Icons.work_rounded,
              ),
              const SizedBox(height: 16),

              // ── Business Name ──────────────────────────────────────
              _SectionLabel(label: 'Business Name'),
              _StyledField(
                controller: _businessNameController,
                hint: 'Your business name',
                validator: (v) => v!.trim().isEmpty ? 'Enter business name' : null,
                icon: Icons.business_rounded,
              ),
              const SizedBox(height: 16),

              // ── Category ──────────────────────────────────────────
              _SectionLabel(label: 'Category'),
              _StyledDropdown<String>(
                value: _selectedCategory,
                items: _categoryLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                icon: Icons.category_rounded,
              ),
              const SizedBox(height: 16),

              // ── Pay Rate ───────────────────────────────────────────
              _SectionLabel(label: 'Pay Rate (Rs.)'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _StyledField(
                      controller: _salaryController,
                      hint: 'e.g. 700',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Enter pay rate' : null,
                      icon: Icons.attach_money_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StyledDropdown<String>(
                      value: _selectedSalaryType,
                      items: const [
                        DropdownMenuItem(value: 'hourly', child: Text('/hour')),
                        DropdownMenuItem(value: 'daily', child: Text('/day')),
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedSalaryType = v!),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Location ───────────────────────────────────────────
              _SectionLabel(label: 'Location'),
              _StyledDropdown<String>(
                value: _selectedLocation,
                items: _locationCoords.keys
                    .map((loc) =>
                        DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLocation = v!),
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 16),

              // ── Shift Date & Times ─────────────────────────────────
              _SectionLabel(label: 'Shift Date & Time'),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    child: _TimeSelector(
                      label: 'Start Time',
                      value: _shiftStart,
                      times: const [
                        '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM',
                        '10:00 AM', '11:00 AM', '12:00 PM',
                      ],
                      onChanged: (v) => setState(() => _shiftStart = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeSelector(
                      label: 'End Time',
                      value: _shiftEnd,
                      times: const [
                        '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
                        '04:00 PM', '05:00 PM', '06:00 PM', '08:00 PM',
                      ],
                      onChanged: (v) => setState(() => _shiftEnd = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Workers Needed ─────────────────────────────────────
              _SectionLabel(label: 'Workers Needed'),
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

              // ── Description ────────────────────────────────────────
              _SectionLabel(label: 'Job Description'),
              _StyledField(
                controller: _descriptionController,
                hint: 'Describe the job role and what workers will do...',
                maxLines: 3,
                icon: Icons.description_rounded,
              ),
              const SizedBox(height: 16),

              // ── Requirements ───────────────────────────────────────
              _SectionLabel(label: 'Requirements (one per line)'),
              _StyledField(
                controller: _requirementsController,
                hint: 'e.g.\nOwn motorcycle\nValid driving license',
                maxLines: 3,
                icon: Icons.checklist_rounded,
              ),
              const SizedBox(height: 32),

              // ── Submit Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitJob,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label:
                      Text(_isLoading ? 'Posting...' : 'Post Job Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
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
                  fontWeight: FontWeight.w500,
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

// ── Time Selector ─────────────────────────────────────────────
class _TimeSelector extends StatelessWidget {
  final String label;
  final String value;
  final List<String> times;
  final void Function(String) onChanged;

  const _TimeSelector({
    required this.label,
    required this.value,
    required this.times,
    required this.onChanged,
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
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: times.contains(value) ? value : times.first,
              items: times
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
