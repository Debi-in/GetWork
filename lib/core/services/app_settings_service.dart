// ============================================================
// APP SETTINGS SERVICE — GetWork App
// Real, persistent settings: toggles in SharedPreferences,
// business profile synced with Supabase profiles table
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSettingsState {
  final bool pushNotifications;
  final bool applicantAlerts;
  final bool messageNotifications;
  final bool soundEffects;
  final String businessName;
  final String businessLocation;
  final String businessPhone;

  const AppSettingsState({
    required this.pushNotifications,
    required this.applicantAlerts,
    required this.messageNotifications,
    required this.soundEffects,
    required this.businessName,
    required this.businessLocation,
    required this.businessPhone,
  });

  AppSettingsState copyWith({
    bool? pushNotifications,
    bool? applicantAlerts,
    bool? messageNotifications,
    bool? soundEffects,
    String? businessName,
    String? businessLocation,
    String? businessPhone,
  }) {
    return AppSettingsState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      applicantAlerts: applicantAlerts ?? this.applicantAlerts,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      soundEffects: soundEffects ?? this.soundEffects,
      businessName: businessName ?? this.businessName,
      businessLocation: businessLocation ?? this.businessLocation,
      businessPhone: businessPhone ?? this.businessPhone,
    );
  }
}

// ── SharedPreferences keys ───────────────────────────────────
const _keyPush = 'settings_push_notifications';
const _keyApplicant = 'settings_applicant_alerts';
const _keyMessage = 'settings_message_notifications';
const _keySound = 'settings_sound_effects';
const _keyBizName = 'settings_business_name';
const _keyBizLocation = 'settings_business_location';
const _keyBizPhone = 'settings_business_phone';

// ── Default state ─────────────────────────────────────────────
const _defaultSettings = AppSettingsState(
  pushNotifications: true,
  applicantAlerts: true,
  messageNotifications: true,
  soundEffects: true,
  businessName: 'My Business',
  businessLocation: '',
  businessPhone: '',
);

// ── Notifier (Riverpod 3.x) ───────────────────────────────────
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    // Hydrate from SharedPrefs + Supabase asynchronously
    Future.microtask(_loadSettings);
    return _defaultSettings;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load stored prefs first (instant)
      AppSettingsState s = AppSettingsState(
        pushNotifications: prefs.getBool(_keyPush) ?? true,
        applicantAlerts: prefs.getBool(_keyApplicant) ?? true,
        messageNotifications: prefs.getBool(_keyMessage) ?? true,
        soundEffects: prefs.getBool(_keySound) ?? true,
        businessName: prefs.getString(_keyBizName) ?? '',
        businessLocation: prefs.getString(_keyBizLocation) ?? '',
        businessPhone: prefs.getString(_keyBizPhone) ?? '',
      );

      // Fetch real business profile from Supabase
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final row = await Supabase.instance.client
              .from('profiles')
              .select('full_name, phone, address')
              .eq('id', user.id)
              .maybeSingle();

          if (row != null) {
            final dbName = (row['full_name'] as String?)?.trim() ?? '';
            final dbPhone = (row['phone'] as String?)?.trim() ?? '';
            final dbAddress = (row['address'] as String?)?.trim() ?? '';
            if (dbName.isNotEmpty) {
              s = s.copyWith(businessName: dbName);
              // Cache it so it's available offline
              await prefs.setString(_keyBizName, dbName);
            }
            if (dbPhone.isNotEmpty && s.businessPhone.isEmpty) {
              s = s.copyWith(businessPhone: dbPhone);
              await prefs.setString(_keyBizPhone, dbPhone);
            }
            if (dbAddress.isNotEmpty && s.businessLocation.isEmpty) {
              s = s.copyWith(businessLocation: dbAddress);
              await prefs.setString(_keyBizLocation, dbAddress);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ AppSettings: Supabase load error: $e');
      }

      state = s;
    } catch (e) {
      if (kDebugMode) print('⚠️ AppSettings: load error: $e');
    }
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPush, value);
  }

  Future<void> setApplicantAlerts(bool value) async {
    state = state.copyWith(applicantAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyApplicant, value);
  }

  Future<void> setMessageNotifications(bool value) async {
    state = state.copyWith(messageNotifications: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMessage, value);
  }

  Future<void> setSoundEffects(bool value) async {
    state = state.copyWith(soundEffects: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, value);
  }

  /// Updates business profile locally in SharedPrefs AND in Supabase profiles table
  Future<void> updateBusinessProfile({
    required String name,
    required String location,
    required String phone,
  }) async {
    state = state.copyWith(
      businessName: name,
      businessLocation: location,
      businessPhone: phone,
    );

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBizName, name);
    await prefs.setString(_keyBizLocation, location);
    await prefs.setString(_keyBizPhone, phone);

    // Sync to Supabase
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
          'phone': phone,
          'address': location,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ AppSettings: Supabase update error: $e');
    }
  }
}

// ── Provider ──────────────────────────────────────────────────
final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);
