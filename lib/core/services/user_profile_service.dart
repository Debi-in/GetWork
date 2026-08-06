// ============================================================
// USER PROFILE SERVICE — GetWork App
// Manages User Registration, Profile Data (Name, Age, Gender, Skills),
// and Progressive Application Profiling
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notifications/models/notification_item.dart';
import '../../features/notifications/services/notification_repository.dart';

class UserProfile {
  final String firstName;
  final String lastName;
  final String phone;
  final int? age;
  final String? gender; // 'Male' | 'Female' | 'Other'
  final String? experience;
  final String? primarySkill;
  final String role; // 'worker' | 'business'

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.age,
    this.gender,
    this.experience,
    this.primarySkill,
    this.role = 'worker',
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Whether basic info (First & Last name) is filled
  bool get hasBasicInfo => firstName.isNotEmpty && lastName.isNotEmpty;

  /// Whether full application details (Age, Gender, Skills) are filled
  bool get isFullProfileComplete =>
      hasBasicInfo && (age != null && age! >= 18) && (gender != null && gender!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'age': age,
        'gender': gender,
        'experience': experience,
        'primary_skill': primarySkill,
        'role': role,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender']?.toString(),
      experience: json['experience']?.toString(),
      primarySkill: json['primary_skill']?.toString(),
      role: json['role']?.toString() ?? 'worker',
    );
  }
}

class UserProfileService {
  static const String _profileKey = 'getwork_user_profile_data_v1';

  /// Save basic profile info during user registration
  static Future<void> saveBasicProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final current = await getProfile();
    final updated = UserProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      age: current?.age,
      gender: current?.gender,
      experience: current?.experience,
      primarySkill: current?.primarySkill,
      role: role,
    );

    await prefs.setString(_profileKey, jsonEncode(updated.toJson()));
    await prefs.setBool('user_registered', true);

    // Save to Supabase if auth user exists
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'full_name': updated.fullName,
          'phone': phone,
          'user_type': role,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Supabase Profile Upsert Error: $e');
    }

    // ── Send Welcome Notification automatically on initial registration ──
    await _sendWelcomeNotification(updated.firstName);
  }

  /// Update full profile details (Age, Gender, Skills) for job applications
  static Future<void> updateApplicationProfile({
    required int age,
    required String gender,
    String? experience,
    String? primarySkill,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getProfile();

    final updated = UserProfile(
      firstName: current?.firstName ?? 'User',
      lastName: current?.lastName ?? '',
      phone: current?.phone ?? '',
      age: age,
      gender: gender,
      experience: experience ?? current?.experience,
      primarySkill: primarySkill ?? current?.primarySkill,
      role: current?.role ?? 'worker',
    );

    await prefs.setString(_profileKey, jsonEncode(updated.toJson()));

    // Save to Supabase
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'full_name': updated.fullName,
          'age': age,
          'gender': gender,
          'experience_level': experience,
          'primary_skill': primarySkill,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Supabase Application Profile Update Error: $e');
    }
  }

  /// Read user profile from local storage / state
  static Future<UserProfile?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_profileKey);
      if (str == null || str.isEmpty) return null;
      return UserProfile.fromJson(jsonDecode(str));
    } catch (e) {
      return null;
    }
  }

  /// Whether user has completed initial name & details registration
  static Future<bool> isUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await getProfile();
    return (prefs.getBool('user_registered') ?? false) && (profile?.hasBasicInfo ?? false);
  }

  /// Automatically generate and store the Welcome Notification
  static Future<void> _sendWelcomeNotification(String name) async {
    try {
      final welcomeItem = NotificationItem(
        id: 'welcome_notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Welcome to GetWork!',
        message:
            'Hello ${name.isNotEmpty ? name : 'User'}! Thanks for joining GetWork Xaie. Discover part-time shifts and local jobs near you in Kathmandu, Lalitpur, and Bhaktapur.',
        createdAt: DateTime.now(),
        type: 'system',
        isRead: false,
      );
      await NotificationRepository.addNotification(welcomeItem);
    } catch (e) {
      if (kDebugMode) print('⚠️ Welcome Notification Error: $e');
    }
  }
}
