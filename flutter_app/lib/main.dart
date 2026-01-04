/// Predator Alert System - Flutter Application
/// 
/// Real-time wildlife threat detection and notification app.
/// Receives alerts from edge devices via Firebase and notifies users
/// with visual alerts and siren audio.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Auth is now handled by AuthService via login flow
    // No automatic anonymous sign-in
    
    runApp(
      const ProviderScope(
        child: PredatorAlertApp(),
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, size: 60, color: Colors.red),
                   const SizedBox(height: 16),
                   const Text(
                    'Configuration Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                   const SizedBox(height: 8),
                  Text(
                    'Firebase is not configured for this platform.\nError: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


