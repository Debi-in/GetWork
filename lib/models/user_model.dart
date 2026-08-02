// ============================================================
// USER MODEL — GetWork App
// ============================================================

import 'package:equatable/equatable.dart';

enum UserType { worker, business }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final UserType userType;
  final double rating;
  final int completedJobs;
  final List<String> skills;
  final bool isAvailable;
  final String? bio;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.userType,
    this.rating = 0.0,
    this.completedJobs = 0,
    this.skills = const [],
    this.isAvailable = true,
    this.bio,
    required this.createdAt,
  });

  // ── Dummy Worker for Phase 1 ─────────────────────────────────
  static UserModel dummyWorker() => UserModel(
        id: 'dummy-worker-001',
        name: 'Ramesh Thapa',
        email: 'ramesh@example.com',
        phone: '+977-9800000000',
        userType: UserType.worker,
        rating: 4.8,
        completedJobs: 12,
        skills: ['Delivery', 'Customer Service', 'Data Entry'],
        isAvailable: true,
        bio: 'Hardworking and reliable worker based in Kathmandu.',
        createdAt: DateTime(2025, 1, 1),
      );

  // ── Dummy Business for Phase 1 ───────────────────────────────
  static UserModel dummyBusiness() => UserModel(
        id: 'dummy-business-001',
        name: 'Himalayan Mart',
        email: 'hr@himalayanmart.com',
        phone: '+977-9811111111',
        userType: UserType.business,
        rating: 4.5,
        completedJobs: 0,
        isAvailable: true,
        bio: 'Leading supermarket chain in Kathmandu.',
        createdAt: DateTime(2025, 1, 1),
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserType? userType,
    double? rating,
    int? completedJobs,
    List<String>? skills,
    bool? isAvailable,
    String? bio,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userType: userType ?? this.userType,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      skills: skills ?? this.skills,
      isAvailable: isAvailable ?? this.isAvailable,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, avatarUrl, userType,
        rating, completedJobs, skills, isAvailable, bio, createdAt,
      ];
}
