// ============================================================
// APP ROUTER — GetWork App
// Uses go_router for declarative navigation
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/authentication/choose_role_screen.dart';
import 'features/authentication/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/jobs/job_detail_screen.dart';
import 'features/jobs/apply_screen.dart';
import 'features/jobs/apply_success_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/manage_profile_screen.dart';
import 'features/business/business_dashboard_screen.dart';
import 'features/business/post_job_screen.dart';
import 'features/business/job_type_selector_screen.dart';
import 'features/business/applicants_screen.dart';
import 'features/jobs/instant_accept_success_screen.dart';
import 'models/job_model.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/business/drafts_screen.dart';
import 'features/business/all_applicants_screen.dart';

// ── Route Names ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String chooseRole = '/choose-role';
  static const String home = '/home';
  static const String jobDetail = '/job/:jobId';
  static const String apply = '/job/:jobId/apply';
  static const String applySuccess = '/apply-success';
  static const String acceptSuccess = '/job/:jobId/accept-success';
  static const String profile = '/profile';
  static const String businessDashboard = '/business';
  static const String postJobType = '/business/post-job/type';
  static const String postJob = '/business/post-job';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String manageProfile = '/profile/manage';
  static const String applicants = '/business/job/:jobId/applicants';
  static const String allApplicants = '/business/applicants/all';
  static const String drafts = '/business/drafts';
}

// ── Router Configuration ─────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.chooseRole,
      name: 'chooseRole',
      builder: (context, state) => const ChooseRoleScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.jobDetail,
      name: 'jobDetail',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId'] ?? '';
        return JobDetailScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: AppRoutes.apply,
      name: 'apply',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId'] ?? '';
        return ApplyScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: AppRoutes.applySuccess,
      name: 'applySuccess',
      builder: (context, state) => const ApplySuccessScreen(),
    ),
    GoRoute(
      path: AppRoutes.acceptSuccess,
      name: 'acceptSuccess',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId'] ?? '';
        return InstantAcceptSuccessScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessDashboard,
      name: 'businessDashboard',
      builder: (context, state) => const BusinessDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.postJobType,
      name: 'postJobType',
      builder: (context, state) => const JobTypeSelectorScreen(),
    ),
    GoRoute(
      path: AppRoutes.postJob,
      name: 'postJob',
      builder: (context, state) {
        final typeStr = state.uri.queryParameters['type'] ?? 'scheduled';
        final type = typeStr == 'instant'
            ? JobType.instant
            : typeStr == 'skilled'
                ? JobType.skilled
                : JobType.scheduled;
        return PostJobScreen(type: type);
      },
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.manageProfile,
      name: 'manageProfile',
      builder: (context, state) => const ManageProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.applicants,
      name: 'applicants',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId'] ?? '';
        return ApplicantsScreen(jobId: jobId);
      },
    ),
    GoRoute(
      path: AppRoutes.allApplicants,
      name: 'allApplicants',
      builder: (context, state) => const AllApplicantsScreen(),
    ),
    GoRoute(
      path: AppRoutes.drafts,
      name: 'drafts',
      builder: (context, state) => const DraftsScreen(),
    ),
  ],

  // ── Error Page ───────────────────────────────────────────────
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
