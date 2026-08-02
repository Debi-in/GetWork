// ============================================================
// CATEGORY FILTER BAR — GetWork App
// Animated expanding pill category filter selector
// Unselected: Icon-only pill | Selected: Expands with Icon + Label
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
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: JobCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = JobCategory.values[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).setCategory(category);
              ref.read(jobFilterProvider.notifier).setCategory(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.fastOutSlowIn,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.fastOutSlowIn,
                      alignment: Alignment.centerLeft,
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: Text(
                                _getCategoryLabel(category),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                              ),
                            )
                          : const SizedBox(width: 0, height: 0),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
