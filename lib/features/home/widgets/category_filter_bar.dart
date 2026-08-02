// ============================================================
// CATEGORY FILTER BAR — GetWork App
// Material 3 horizontal scrolling category selector
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/job_model.dart';
import 'package:getwork/features/jobs/jobs_provider.dart';

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  IconData _getCategoryIcon(JobCategory category) {
    switch (category) {
      case JobCategory.all:
        return Icons.grid_view_rounded;
      case JobCategory.delivery:
        return Icons.two_wheeler_rounded;
      case JobCategory.retail:
        return Icons.shopping_bag_outlined;
      case JobCategory.food:
        return Icons.restaurant_rounded;
      case JobCategory.construction:
        return Icons.construction_rounded;
      case JobCategory.cleaning:
        return Icons.cleaning_services_rounded;
      case JobCategory.tech:
        return Icons.computer_rounded;
      case JobCategory.events:
        return Icons.event_rounded;
    }
  }

  String _getCategoryLabel(JobCategory category) {
    switch (category) {
      case JobCategory.all:
        return 'All Jobs';
      case JobCategory.delivery:
        return 'Delivery';
      case JobCategory.retail:
        return 'Retail';
      case JobCategory.food:
        return 'Food';
      case JobCategory.construction:
        return 'Construction';
      case JobCategory.cleaning:
        return 'Cleaning';
      case JobCategory.tech:
        return 'Tech';
      case JobCategory.events:
        return 'Events';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: JobCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = JobCategory.values[index];
          final isSelected = selectedCategory == category;

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              _getCategoryIcon(category),
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            label: Text(
              _getCategoryLabel(category),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            elevation: isSelected ? 2 : 0,
            shadowColor: AppColors.shadowLight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            onSelected: (bool selected) {
              ref.read(selectedCategoryProvider.notifier).setCategory(category);
            },
          );
        },
      ),
    );
  }
}
