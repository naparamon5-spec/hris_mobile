import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../widgets/brand.dart';

/// Opens the app's store listing (App Store / Play Store). Best-effort — if the
/// deep link can't be opened it silently does nothing rather than crashing.
Future<void> openStore(String? storeUrl) async {
  if (storeUrl == null || storeUrl.isEmpty) return;
  final uri = Uri.tryParse(storeUrl);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Ignore — the button just won't navigate.
  }
}

/// Dismissible "a new version is available" prompt. Shown once per launch when
/// the backend reports a newer (but non-mandatory) version.
Future<void> showSoftUpdateDialog(
  BuildContext context, {
  String? storeUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update available'),
      content: const Text(
        'A newer version of ANI HRIS is available with improvements and '
        'fixes. Update now for the best experience.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            openStore(storeUrl);
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

/// Full-screen, non-dismissible mandatory-update wall. The app routes here on
/// launch when the running version is below the minimum the backend supports.
/// There is no way past it except updating — no back button, no skip.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.storeUrl});

  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    // Swallow the Android back button so this screen truly blocks.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AniHrisIcon(size: 72),
                  const SizedBox(height: 28),
                  const Text(
                    'Update required',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This version of ANI HRIS is no longer supported. Please '
                    'update to the latest version to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => openStore(storeUrl),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
