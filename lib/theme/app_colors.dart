import 'package:flutter/material.dart';

/// Brand palette. Red is the default (Ardent) brand color, but the brand family
/// below is **dynamic** — it follows the signed-in company's accent so the whole
/// app (not just the theme-driven widgets) re-colors per tenant. Versatech, for
/// example, turns the app blue. Call [AppColors.applyAccent] whenever the tenant
/// changes (done in `main.dart` before the theme is built).
class AppColors {
  AppColors._();

  // Canonical brand red — the fallback accent for tenants without a color.
  static const Color _redDefault = Color(0xFFEB1E23);
  static const Color _redBrightDefault = Color(0xFFEA0509);
  static const Color _redSoftDefault = Color(0xFFF53D42);
  static const Color _maroonDefault = Color(0xFF760F12);
  static const Color _dangerSoftDefault = Color(0xFFFCE7E8);

  /// The brand red literal — use where a genuinely red accent is required
  /// regardless of tenant (kept stable for error/destructive semantics).
  static const Color defaultBrand = _redDefault;

  // ----- Brand (dynamic — recomputed by applyAccent) -----
  static Color brandRed = _redDefault; // primary / accent
  static Color brandRedBright = _redBrightDefault; // vivid accent
  static Color brandRedSoft = _redSoftDefault; // lighter tint
  static Color brandMaroon = _maroonDefault; // deep shade
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

  /// Soft accent background (selected chips, badges, subtle brand fills).
  /// Follows the tenant accent, so it's a light red for Ardent and a light blue
  /// for Versatech.
  static Color dangerSoft = _dangerSoftDefault;

  // ----- Integrations -----
  static const Color authentik = Color(0xFF5B5BD6); // Authentik SSO accent

  // ----- Gradients (dynamic) -----
  static LinearGradient brandGradient = const LinearGradient(
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

  /// Recompute the whole brand family from [accent]. Passing null (or the brand
  /// red) restores the default red palette. Called on tenant change so every
  /// widget that references `AppColors.brandRed` (and its tints) re-colors.
  static void applyAccent(Color? accent) {
    final a = accent ?? _redDefault;
    if (a.toARGB32() == _redDefault.toARGB32()) {
      brandRed = _redDefault;
      brandRedBright = _redBrightDefault;
      brandRedSoft = _redSoftDefault;
      brandMaroon = _maroonDefault;
      dangerSoft = _dangerSoftDefault;
      brandGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEB1E23), Color(0xFF9A1217)],
      );
      return;
    }
    brandRed = a;
    brandRedBright = Color.lerp(a, Colors.white, 0.06) ?? a;
    brandRedSoft = Color.lerp(a, Colors.white, 0.18) ?? a;
    brandMaroon = Color.lerp(a, Colors.black, 0.38) ?? a;
    dangerSoft = Color.lerp(a, Colors.white, 0.88) ?? a;
    brandGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a, Color.lerp(a, Colors.black, 0.35) ?? a],
    );
  }
}
