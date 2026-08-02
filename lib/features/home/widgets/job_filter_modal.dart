// ============================================================
// JOB FILTER MODAL — GetWork App
// Comprehensive Filter Bottom Sheet for Categories, Salary, Distance & Urgency
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';
import '../../jobs/jobs_provider.dart';

class JobFilterModal extends ConsumerStatefulWidget {
  const JobFilterModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JobFilterModal(),
    );
  }

  @override
  ConsumerState<JobFilterModal> createState() => _JobFilterModalState();
}

class _JobFilterModalState extends ConsumerState<JobFilterModal> {
  late JobFilterState _localFilter;

  @override
  void initState() {
    super.initState();
    _localFilter = ref.read(jobFilterProvider);
  }

  String _categoryName(JobCategory category) {
    switch (category) {
      case JobCategory.all: return 'All';
      case JobCategory.delivery: return 'Delivery';
      case JobCategory.retail: return 'Retail';
      case JobCategory.food: return 'Food & Dining';
      case JobCategory.construction: return 'Construction';
      case JobCategory.cleaning: return 'Cleaning';
      case JobCategory.tech: return 'Tech';
      case JobCategory.events: return 'Events';
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchingJobs = ref.watch(filteredJobsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ───────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header Row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Jobs',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _localFilter = const JobFilterState();
                    });
                    ref.read(jobFilterProvider.notifier).reset();
                    ref.read(selectedCategoryProvider.notifier).setCategory(JobCategory.all);
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Filter Body ────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Job Category
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: JobCategory.values.map((cat) {
                      final isSelected = _localFilter.category == cat;
                      return ChoiceChip(
                        label: Text(_categoryName(cat)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _localFilter = _localFilter.copyWith(category: cat);
                            });
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 2. Salary Type
                  _buildSectionTitle('Salary Type'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSalaryTypeTile(null, 'Any'),
                      const SizedBox(width: 8),
                      _buildSalaryTypeTile(SalaryType.daily, 'Daily'),
                      const SizedBox(width: 8),
                      _buildSalaryTypeTile(SalaryType.hourly, 'Hourly'),
                      const SizedBox(width: 8),
                      _buildSalaryTypeTile(SalaryType.fixed, 'Fixed'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Salary Range Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Salary Range'),
                      Text(
                        'Rs. ${_localFilter.minSalary.round()} – Rs. ${_localFilter.maxSalary.round()}+',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_localFilter.minSalary, _localFilter.maxSalary),
                    min: 0,
                    max: 5000,
                    divisions: 50,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceVariant,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          minSalary: values.start,
                          maxSalary: values.end,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Max Distance Radius
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Max Distance'),
                      Text(
                        'Within ${_localFilter.maxDistanceKm.round()} km',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _localFilter.maxDistanceKm,
                    min: 1,
                    max: 25,
                    divisions: 24,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(maxDistanceKm: val);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 5. Special Toggles
                  _buildToggleRow(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.accent,
                    title: 'Urgent Jobs Only',
                    subtitle: 'Show high-priority hiring shifts',
                    value: _localFilter.isUrgentOnly,
                    onChanged: (val) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(isUrgentOnly: val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildToggleRow(
                    icon: Icons.today_rounded,
                    iconColor: AppColors.primary,
                    title: 'Shifts Today Only',
                    subtitle: 'Jobs starting within 24 hours',
                    value: _localFilter.isTodayOnly,
                    onChanged: (val) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(isTodayOnly: val);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Apply Button Bar ─────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(jobFilterProvider.notifier).updateFilter(_localFilter);
                  ref.read(selectedCategoryProvider.notifier).setCategory(_localFilter.category);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filters (${matchingJobs.length} Jobs)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSalaryTypeTile(SalaryType? type, String label) {
    final isSelected = _localFilter.salaryType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _localFilter = _localFilter.copyWith(
              salaryType: type,
              clearSalaryType: type == null,
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
