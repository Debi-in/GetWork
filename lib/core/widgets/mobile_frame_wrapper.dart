// ============================================================
// MOBILE FRAME WRAPPER — GetWork App
// Centers the app inside a sleek smartphone container on desktop web viewports
// ============================================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MobileFrameWrapper extends StatelessWidget {
  final Widget child;

  const MobileFrameWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If viewing on desktop / landscape screen (> 600px width)
        if (constraints.maxWidth > 600) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F1117), // Dark outer backdrop
            body: Center(
              child: Container(
                width: 414,
                height: constraints.maxHeight * 0.92,
                constraints: const BoxConstraints(
                  maxHeight: 896,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color(0xFF2C303E),
                    width: 8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 32,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: MediaQuery(
                    // Override media query constraints for nested children
                    data: MediaQuery.of(context).copyWith(
                      size: Size(
                        414,
                        constraints.maxHeight * 0.92,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        }

        // On real mobile devices, render 100% full screen natively
        return child;
      },
    );
  }
}
