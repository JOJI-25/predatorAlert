/// User Profile Model
/// 
/// Represents a user with their role (owner/authority), contact info, and profile details.

import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in the system
enum UserRole {
  owner,
  authority;
  
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Farm Owner';
      case UserRole.authority:
        return 'Authority';
    }
  }
  
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value.toLowerCase(),
      orElse: () => UserRole.owner,
    );
  }
}

/// User profile data model
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final String? fcmToken;
  final String? photoUrl;
  
  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.fcmToken,
    this.photoUrl,
  });
  
  /// Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'owner'),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcm_token'],
      photoUrl: data['photo_url'],
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'created_at': Timestamp.fromDate(createdAt),
      'fcm_token': fcmToken,
      'photo_url': photoUrl,
    };
  }
  
  /// Create a copy with updated fields
  UserProfile copyWith({
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? fcmToken,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
  
  /// Check if user is an owner
  bool get isOwner => role == UserRole.owner;
  
  /// Check if user is an authority
  bool get isAuthority => role == UserRole.authority;
}
