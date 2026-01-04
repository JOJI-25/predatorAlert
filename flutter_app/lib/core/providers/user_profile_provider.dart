/// User Profile Provider
/// 
/// Riverpod provider for managing user profile state.
/// Handles profile creation, fetching, and updates.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/models/user_profile.dart';

/// State for user profile
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final bool hasProfile;
  final String? errorMessage;
  final bool isUploading;
  
  const UserProfileState({
    this.profile,
    this.isLoading = true,
    this.hasProfile = false,
    this.errorMessage,
    this.isUploading = false,
  });
  
  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    bool? hasProfile,
    String? errorMessage,
    bool? isUploading,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      hasProfile: hasProfile ?? this.hasProfile,
      errorMessage: errorMessage,
      isUploading: isUploading ?? this.isUploading,
    );
  }
  
  factory UserProfileState.loading() => const UserProfileState(isLoading: true);
  factory UserProfileState.noProfile() => const UserProfileState(isLoading: false, hasProfile: false);
  factory UserProfileState.loaded(UserProfile profile) => UserProfileState(
    profile: profile,
    isLoading: false,
    hasProfile: true,
  );
  factory UserProfileState.error(String message) => UserProfileState(
    isLoading: false,
    errorMessage: message,
  );
}

/// User profile notifier
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  UserProfileNotifier() : super(UserProfileState.loading());
  
  /// Check if current user has a profile
  Future<bool> checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = UserProfileState.noProfile();
      return false;
    }
    
    try {
      state = UserProfileState.loading();
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromFirestore(doc);
        state = UserProfileState.loaded(profile);
        
        // Subscribe to FCM topic based on role
        await _subscribeToRoleTopic(profile.role);
        
        return true;
      } else {
        state = UserProfileState.noProfile();
        return false;
      }
    } catch (e) {
      state = UserProfileState.error('Failed to load profile: $e');
      return false;
    }
  }
  
  /// Create a new user profile
  Future<bool> createProfile({
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Get FCM token
      final fcmToken = await _messaging.getToken();
      
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
      );
      
      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(profile.toFirestore());
      
      // Subscribe to FCM topic based on role
      await _subscribeToRoleTopic(role);
      
      state = UserProfileState.loaded(profile);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to create profile: $e');
      return false;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    if (state.profile == null) return false;
    
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      
      await _firestore.collection('users').doc(state.profile!.uid).update(updates);
      
      final updatedProfile = state.profile!.copyWith(name: name, phone: phone);
      state = UserProfileState.loaded(updatedProfile);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update profile: $e');
      return false;
    }
  }
  
  /// Upload profile photo
  Future<bool> uploadProfilePhoto(File imageFile) async {
    if (state.profile == null) return false;
    
    try {
      state = state.copyWith(isUploading: true, errorMessage: null);
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child('profile_photos/${state.profile!.uid}.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Get download URL
      final photoUrl = await uploadTask.ref.getDownloadURL();
      
      // Update Firestore
      await _firestore.collection('users').doc(state.profile!.uid).update({
        'photo_url': photoUrl,
      });
      
      // Update local state
      final updatedProfile = state.profile!.copyWith(photoUrl: photoUrl);
      state = UserProfileState.loaded(updatedProfile);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: 'Failed to upload photo: $e');
      return false;
    }
  }
  
  /// Subscribe to FCM topic based on role
  Future<void> _subscribeToRoleTopic(UserRole role) async {
    try {
      // Unsubscribe from both topics first
      await _messaging.unsubscribeFromTopic('predator_alert_owners');
      await _messaging.unsubscribeFromTopic('predator_alert_authorities');
      
      // Subscribe to the appropriate topic
      if (role == UserRole.owner) {
        await _messaging.subscribeToTopic('predator_alert_owners');
      } else if (role == UserRole.authority) {
        await _messaging.subscribeToTopic('predator_alert_authorities');
      }
    } catch (e) {
      // Silently ignore FCM errors
    }
  }
  
  /// Clear profile state (on logout)
  void clearProfile() {
    state = UserProfileState.noProfile();
  }
}

/// Main user profile provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier();
});

/// Convenience providers
final hasProfileProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).hasProfile;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(userProfileProvider).profile?.role;
});

final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).profile?.isOwner ?? false;
});

final isAuthorityProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).profile?.isAuthority ?? false;
});
