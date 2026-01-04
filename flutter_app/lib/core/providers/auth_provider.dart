/// Authentication State Provider
/// 
/// Riverpod provider for managing authentication state across the app.
/// Tracks user authentication status, loading states, and user info.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? errorMessage;
  final AuthType? authType;
  
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.user,
    this.errorMessage,
    this.authType,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? errorMessage,
    AuthType? authType,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
      authType: authType ?? this.authType,
    );
  }
  
  /// Initial loading state
  factory AuthState.loading() => const AuthState(isLoading: true);
  
  /// Authenticated state
  factory AuthState.authenticated(User user, AuthType type) => AuthState(
    isAuthenticated: true,
    isLoading: false,
    user: user,
    authType: type,
  );
  
  /// Unauthenticated state
  factory AuthState.unauthenticated() => const AuthState(
    isAuthenticated: false,
    isLoading: false,
  );
  
  /// Error state
  factory AuthState.error(String message) => AuthState(
    isAuthenticated: false,
    isLoading: false,
    errorMessage: message,
  );
}

/// Auth state notifier for handling authentication logic
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  /// Constructor sets initial state synchronously for instant startup
  AuthNotifier(this._authService) : super(_getInitialState(AuthService())) {
    // No async init needed - state is set synchronously in super()
  }
  
  /// Get initial auth state synchronously from Firebase's cached user
  static AuthState _getInitialState(AuthService authService) {
    // Firebase caches currentUser - this is synchronous
    final user = authService.currentUser;
    if (user != null) {
      return AuthState.authenticated(user, AuthType.email);
    }
    return AuthState.unauthenticated();
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!, AuthType.email);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }
  
  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!, AuthType.email);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authService.signInWithGoogle();
    
    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!, AuthType.google);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = AuthState.unauthenticated();
  }
  
  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    final result = await _authService.sendPasswordResetEmail(email);
    if (!result.success) {
      state = state.copyWith(errorMessage: result.errorMessage);
    }
    return result.success;
  }
}

/// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});

/// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});
