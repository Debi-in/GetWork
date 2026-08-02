import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../router.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Business Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push(AppRoutes.postJob),
          child: const Text('Post a Job'),
        ),
      ),
    );
  }
}
