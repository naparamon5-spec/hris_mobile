import 'package:flutter/material.dart';

/// Brand palette derived from the Ardent Networks color sheet.
/// Red is the dominant brand color, supported by neutrals on white.
class AppColors {
  AppColors._();

  // ----- Brand -----
  static const Color brandRed = Color(0xFFEB1E23); // RGB 165,20,25 / primary
  static const Color brandRedBright = Color(0xFFEA0509); // vivid accent
  static const Color brandRedSoft = Color(0xFFF53D42); // lighter tint
  static const Color brandMaroon = Color(0xFF760F12); // deep red
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9C9C9C);

  // ----- Neutrals -----
  static const Color ink = Color(0xFF17171C); // primary text
  static const Color inkSoft = Color(0xFF6C6C77); // secondary text
  static const Color inkFaint = Color(0xFF9A9AA5); // tertiary text / hints
  static const Color line = Color(0xFFECEDF1); // hairline borders
  static const Color bg = Color(0xFFF5F6F8); // scaffold background
  static const Color card = Color(0xFFFFFFFF);
  static const Color fieldFill = Color(0xFFF3F4F6);

  // ----- Semantic -----
  static const Color success = Color(0xFF1FA971);
  static const Color successSoft = Color(0xFFE6F6EF);
  static const Color warning = Color(0xFFE9A123);
  static const Color warningSoft = Color(0xFFFBF1DC);
  static const Color info = Color(0xFF3A6FF0);
  static const Color infoSoft = Color(0xFFE7EEFE);
  static const Color dangerSoft = Color(0xFFFCE7E8);

  // ----- Gradients -----
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEB1E23), Color(0xFF9A1217)],
  );

  static const LinearGradient maroonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E1418), Color(0xFF4E090B)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A30), Color(0xFF0E0E12)],
  );
}
