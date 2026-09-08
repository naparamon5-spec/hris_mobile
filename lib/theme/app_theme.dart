import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Central Material 3 theme. Keeps every screen visually consistent:
/// soft shadows, 20px rounded corners, brand-red primary, clean typography.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandRed,
        onPrimary: Colors.white,
        secondary: AppColors.brandMaroon,
        onSecondary: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        error: AppColors.brandRedBright,
      ),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.line, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandRed,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 15),
        prefixIconColor: AppColors.inkSoft,
        suffixIconColor: AppColors.inkSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandRed, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.fieldFill,
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide.none,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          bodyLarge: base.bodyLarge?.copyWith(color: AppColors.ink),
          bodyMedium: base.bodyMedium?.copyWith(color: AppColors.inkSoft),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(displayColor: AppColors.ink, bodyColor: AppColors.ink);
  }
}

/// Reusable soft shadow for cards and floating surfaces.
const List<BoxShadow> kSoftShadow = [
  BoxShadow(
    color: Color(0x0F101828),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x08101828),
    blurRadius: 4,
    offset: Offset(0, 1),
  ),
];

const List<BoxShadow> kBrandShadow = [
  BoxShadow(
    color: Color(0x33EB1E23),
    blurRadius: 24,
    offset: Offset(0, 12),
  ),
];
