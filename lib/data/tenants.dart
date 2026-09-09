import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A company (tenant) sharing the HRIS app. Chosen from the Company selector on
/// the login screen — exactly like the web app's Company dropdown — and it
/// scopes the session. In production this list comes from the backend.
class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.color,
  });

  final String id;
  final String name;
  final String subtitle;
  final Color color;

  String get initial => name.characters.first.toUpperCase();

  Color get colorDark => Color.lerp(color, Colors.black, 0.28)!;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, colorDark],
      );
}

const List<Tenant> kTenants = [
  Tenant(
    id: 'ardent',
    name: 'Ardent Networks Inc.',
    subtitle: 'Metro Manila',
    color: AppColors.brandRed,
  ),
  Tenant(
    id: 'versatech',
    name: 'Versatech',
    subtitle: 'IT Solutions',
    color: Color(0xFF1F6FEB),
  ),
  Tenant(
    id: 'lamco',
    name: 'Lamco',
    subtitle: 'Manufacturing',
    color: Color(0xFF0FA36B),
  ),
  Tenant(
    id: 'napa',
    name: 'Napa Group',
    subtitle: 'Logistics',
    color: Color(0xFFE8890C),
  ),
];
