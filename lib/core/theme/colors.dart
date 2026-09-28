import 'package:flutter/material.dart';

/// Brand palette, mirrored from the web app's `tailwind.config.js`.
abstract final class AppColors {
  // primary scale
  static const primary50 = Color(0xFFEEF3FF);
  static const primary100 = Color(0xFFDFE8FF);
  static const primary200 = Color(0xFFC0D1FF);
  static const primary300 = Color(0xFF91ADFF);
  static const primary400 = Color(0xFF5C81FD);
  static const primary500 = Color(0xFF2F5CFB);
  static const primary600 = Color(0xFF1642F2);
  static const primary700 = Color(0xFF1030C2);
  static const primary800 = Color(0xFF132A97);
  static const primary900 = Color(0xFF142776);

  static const purple600 = Color(0xFF9333EA);
  static const navy = Color(0xFF0B1130);

  // Tailwind grays
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);

  // semantic accents
  static const changed = Color(0xFFEA580C); // orange-600
  static const changedSoft = Color(0xFFFFF7ED); // orange-50
  static const active = Color(0xFF16A34A); // green-600
  static const activeSoft = Color(0xFFF0FDF4); // green-50
  static const aiInsight = Color(0xFF7C3AED); // violet-600
  static const aiInsightSoft = Color(0xFFF5F3FF); // violet-50
  static const danger = Color(0xFFDC2626); // red-600
  static const dangerSoft = Color(0xFFFEF2F2); // red-50

  /// primary-600 → purple-600, the brand gradient used on CTAs and headings.
  static const brandGradient = LinearGradient(
    colors: [primary600, purple600],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
