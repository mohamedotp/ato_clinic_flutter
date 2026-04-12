import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF2C3E50);
  static const Color primaryLight = Color(0xFF34495E);
  static const Color accent = Color(0xFF1ABC9C);
  
  // Backgrounds
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  
  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF1C40F);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textOnPrimary = Colors.white;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
