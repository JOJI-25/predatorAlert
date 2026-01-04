/// Application color constants
/// 
/// Industrial / security-grade design with dark mode first

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Background Colors
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF252525);
  static const Color surfaceElevated = Color(0xFF2D2D2D);

  // Accent Colors
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color secondary = Color(0xFF7C4DFF);

  // Alert Colors
  static const Color danger = Color(0xFFFF3D3D);
  static const Color dangerDark = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFE65100);
  static const Color success = Color(0xFF00E676);
  static const Color successDark = Color(0xFF00C853);

  // Predator Alert Colors
  static const Color predatorAlert = Color(0xFFFF1744);
  static const Color predatorAlertGlow = Color(0x40FF1744);
  static const Color predatorAlertDark = Color(0xFF8B0000);

  // Normal Detection Colors
  static const Color normalDetection = Color(0xFF00E676);
  static const Color normalDetectionGlow = Color(0x4000E676);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF666666);

  // Status Colors
  static const Color online = Color(0xFF00E676);
  static const Color offline = Color(0xFF757575);
  static const Color pending = Color(0xFFFFAB00);

  // Gradient
  static const LinearGradient predatorGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B8D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
