/// Application widget and MaterialApp configuration

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';
import '../core/services/notification_service.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/home_screen.dart';

class PredatorAlertApp extends StatefulWidget {
  const PredatorAlertApp({super.key});

  @override
  State<PredatorAlertApp> createState() => _PredatorAlertAppState();
}

class _PredatorAlertAppState extends State<PredatorAlertApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize notification service in background (don't block UI)
    NotificationService.instance.initialize();
    
    // Set system UI overlay style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0D0D0D),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Determine initial screen based on auth state (synchronous check)
  Widget _getInitialScreen() {
    // Firebase caches currentUser - this is a synchronous check
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // User is already authenticated - go directly to HomeScreen
      // Profile check will happen in HomeScreen
      return const HomeScreen();
    } else {
      // New user or logged out - show splash/login flow
      return const SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Predator Alert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _getInitialScreen(),
    );
  }
}

