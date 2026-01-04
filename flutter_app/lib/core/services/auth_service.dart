/// Authentication Service
/// 
/// Handles Firebase Auth, Google Sign-In, and secure token storage.
/// Provides a unified API for all authentication operations.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Authentication provider types
enum AuthType { google, email, anonymous }

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;
  
  AuthResult({required this.success, this.errorMessage, this.user});
  
  factory AuthResult.success(User user) => AuthResult(success: true, user: user);
  factory AuthResult.failure(String message) => AuthResult(success: false, errorMessage: message);
}

/// Main authentication service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  // Storage keys
  static const String _keyAuthProvider = 'auth_provider';
  static const String _keyUserId = 'user_id';
  
  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  // ============================================
  // EMAIL/PASSWORD AUTHENTICATION
  // ============================================
  
  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await _saveAuthState(AuthType.email, credential.user!.uid);
        return AuthResult.success(credential.user!);
      }
      return AuthResult.failure('Failed to create account');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('SignUp error: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }
  
  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await _saveAuthState(AuthType.email, credential.user!.uid);
        return AuthResult.success(credential.user!);
      }
      return AuthResult.failure('Failed to sign in');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('SignIn error: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }
  
  // ============================================
  // GOOGLE SIGN-IN
  // ============================================
  
  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in was cancelled');
      }
      
      // Obtain auth details from the Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _saveAuthState(AuthType.google, userCredential.user!.uid);
        return AuthResult.success(userCredential.user!);
      }
      return AuthResult.failure('Failed to sign in with Google');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('Google SignIn error: $e');
      return AuthResult.failure('Google sign-in failed: ${e.toString()}');
    }
  }
  
  // ============================================
  // SESSION MANAGEMENT
  // ============================================
  
  /// Check and restore auth session on app launch
  Future<bool> checkAuthSession() async {
    try {
      // Check if we have a current Firebase user
      if (currentUser != null) {
        debugPrint('Auth session restored for user: ${currentUser!.uid}');
        return true;
      }
      
      // Check secure storage for saved auth state
      final savedProvider = await _secureStorage.read(key: _keyAuthProvider);
      final savedUserId = await _secureStorage.read(key: _keyUserId);
      
      if (savedProvider != null && savedUserId != null) {
        // We have saved state but no current user - session expired
        await _clearAuthState();
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Check auth session error: $e');
      return false;
    }
  }
  
  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if was used
      final savedProvider = await _secureStorage.read(key: _keyAuthProvider);
      if (savedProvider == AuthType.google.name) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Clear secure storage
      await _clearAuthState();
      
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      // Still clear local state even if remote sign out fails
      await _clearAuthState();
    }
  }
  
  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Failed to send reset email');
    }
  }
  
  // ============================================
  // PRIVATE HELPERS
  // ============================================
  
  /// Save auth state to secure storage
  Future<void> _saveAuthState(AuthType provider, String userId) async {
    await _secureStorage.write(key: _keyAuthProvider, value: provider.name);
    await _secureStorage.write(key: _keyUserId, value: userId);
  }
  
  /// Clear auth state from secure storage
  Future<void> _clearAuthState() async {
    await _secureStorage.delete(key: _keyAuthProvider);
    await _secureStorage.delete(key: _keyUserId);
  }
  
  /// Convert Firebase error codes to user-friendly messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
