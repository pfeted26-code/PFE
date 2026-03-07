import 'package:flutter/widgets.dart';

class TColors {
  TColors._();

  // App Basic Colors
  static const Color primary   = Color(0xFF7C3AED); // purple-600
  static const Color secondary = Color(0xFF0891B2); // cyan-600
  static const Color darkGrey  = Color(0xFF1E293B); // slate-800
  static const Color grey      = Color(0xFF64748B); // slate-500
  static const Color white     = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary   = Color(0xFFC084FC); // purple-400
  static const Color textSecondary = Color(0xFF60A5FA); // blue-400
  static const Color textDarkGrey  = Color(0xFF94A3B8); // slate-400
  static const Color textgrey      = Color(0xFF64748B); // slate-500
  static const Color textwhite     = Color(0xFFE2E8F0); // slate-200

  // Background Colors
  static const Color light = Color(0xFF1E293B); // slate-800
  static const Color dark  = Color(0xFF020617); // slate-950

  // Background Container Colors
  static const Color lightContainer = Color(0xFF0F172A); // slate-900
  static const Color darkContainer  = Color(0xFF020617); // slate-950

  // Button Colors
  static const Color buttonPrimary   = Color(0xFF7C3AED); // purple-600
  static const Color buttonSecondary = Color(0xFF2563EB); // blue-600
  static const Color buttonDisabled  = Color(0xFF334155); // slate-700

  // Border Colors
  static const Color lightBorder = Color(0xFF1E293B); // slate-800
  static const Color darkBorder  = Color(0xFF0F172A); // slate-900

  // Gradient Colors (extra — used for shimmer/buttons/icons)
  static const Color gradientStart  = Color(0xFF7C3AED); // purple-600
  static const Color gradientMiddle = Color(0xFF2563EB); // blue-600
  static const Color gradientEnd    = Color(0xFF0891B2); // cyan-600

  // Error and Validation Colors
  static const Color error   = Color(0xFFEF4444); // red-500
  static const Color success = Color(0xFF22C55E); // green-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color info    = Color(0xFF3B82F6); // blue-500
}