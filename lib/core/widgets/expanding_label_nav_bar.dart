// ============================================================
// EXPANDING LABEL NAV BAR — GetWork App
// Inspired by Modern Sliding Pill Navigation Bar UI
// Features sliding purple active highlight + sleek corner radius
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class ExpandingLabelNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemData> items;

  const ExpandingLabelNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: bottomPadding > 0 ? bottomPadding + 4 : 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / items.length;

          return SizedBox(
            height: 46,
            child: Stack(
              children: [
                // ── Sliding Purple Active Highlight Pill ─────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastOutSlowIn,
                  left: currentIndex * itemWidth + 4,
                  width: itemWidth - 8,
                  top: 2,
                  bottom: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.navPurple,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navPurple.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Nav Items Row ────────────────────────────────────────────
                Row(
                  children: List.generate(items.length, (index) {
                    final isSelected = index == currentIndex;
                    final item = items[index];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedTheme(
                                data: ThemeData(
                                  iconTheme: IconThemeData(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                child: Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 21,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                              ClipRect(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.centerLeft,
                                  child: isSelected
                                      ? Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Text(
                                            item.label,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      : const SizedBox(width: 0, height: 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
