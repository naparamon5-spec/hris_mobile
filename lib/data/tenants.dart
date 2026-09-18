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
    this.logo,
  });

  final String id;
  final String name;

  /// Nature of business shown under the company name (not the location).
  final String subtitle;
  final Color color;

  /// Optional company logo image URL. When null the UI shows a monogram tile.
  final String? logo;

  factory Tenant.fromJson(Map<String, dynamic> j) {
    final logo = (j['logo'] as String?)?.trim();
    return Tenant(
      id: (j['id'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      subtitle: (j['subtitle'] ?? '') as String,
      color: _parseHex(j['color'] as String?),
      logo: (logo == null || logo.isEmpty) ? null : logo,
    );
  }

  static Color _parseHex(String? hex) {
    if (hex == null) return AppColors.defaultBrand;
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value == null ? AppColors.defaultBrand : Color(value);
  }

  String get initial => name.characters.first.toUpperCase();

  Color get colorDark => Color.lerp(color, Colors.black, 0.28)!;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, colorDark],
      );
}

// Fallback list used only if the backend `/public/tenants` is unreachable on
// the pre-login screen. The live list (with real company names read from each
// company's database) comes from the backend.
const List<Tenant> kTenants = [
  Tenant(
    id: 'ardent',
    name: 'Ardent Networks Inc.',
    subtitle: 'Premier ICT Distributor',
    color: Color(0xFFE43834),
  ),
  Tenant(
    id: 'versatech',
    name: 'Versatech International',
    subtitle: 'AV and ICT Distribution',
    color: Color(0xFF6DCFF6),
  ),
  Tenant(
    id: 'lamco',
    name: 'Lamco International',
    subtitle: 'Real Estate Investment',
    color: Color(0xFFFB0000),
  ),
  Tenant(
    id: 'match',
    name: 'Match',
    subtitle: 'Corporate Group',
    color: Color(0xFF787878),
  ),
  Tenant(
    id: 'fastronics',
    name: 'Fastronics',
    subtitle: 'Electronics Manufacturing',
    color: Color(0xFFED0A15),
  ),
  Tenant(
    id: 'diamond_concept',
    name: 'Diamond Concept',
    subtitle: 'Retail Concepts',
    color: Color(0xFFF26722),
  ),
  Tenant(
    id: 'diamond_office',
    name: 'Diamond Office',
    subtitle: 'Office Solutions',
    color: Color(0xFFF26722),
  ),
  Tenant(
    id: 'overland',
    name: 'Overland',
    subtitle: 'Logistics',
    color: Color(0xFF10600D),
  ),
  Tenant(
    id: 'ez_touch',
    name: 'EZ Touch',
    subtitle: 'Touch Solutions',
    color: Color(0xFFFE0002),
  ),
  Tenant(
    id: 'rmd',
    name: 'Real Modern Design',
    subtitle: 'Design Studio',
    color: Color(0xFF787878),
  ),
];
