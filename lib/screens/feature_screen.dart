import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// Generic detail scaffold for HRIS modules that exist on the web app but
/// don't have a dedicated mobile screen yet. Keeps navigation honest: every
/// menu item leads somewhere real instead of a dead tap.
class FeatureScreen extends StatelessWidget {
  const FeatureScreen({
    super.key,
    required this.title,
    required this.icon,
    this.color = AppColors.defaultBrand,
    this.blurb,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? blurb;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconBadge(icon: icon, color: color, size: 88, iconSize: 40),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  blurb ??
                      'This module is available on the HRIS web app and is '
                          'coming to mobile soon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => showToast(context, 'Opening the web app…'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open in web app'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(220, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
