import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_session.dart';
import 'data/notifications/push_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Initialize push notifications (FCM). Best-effort — a missing Firebase
  // config never blocks app startup.
  await PushService.instance.initialize();
  runApp(const HrisApp());
}

class HrisApp extends StatelessWidget {
  const HrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the app theme whenever the signed-in company changes, so the
    // accent color follows the tenant (e.g. blue for Versatech, red for Ardent).
    return AnimatedBuilder(
      animation: AppSession.instance,
      builder: (context, _) {
        final accent = AppSession.instance.tenant?.color ?? AppColors.defaultBrand;
        // Re-color the dynamic brand palette so widgets that reference
        // AppColors.brandRed directly (not just the theme) follow the tenant.
        AppColors.applyAccent(accent);
        return MaterialApp(
          title: 'ANI HRIS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(accent: accent),
          // Mount the loading overlay above the Navigator so showLoadingOverlay()
          // blurs and covers ANY screen in the app, not just the home shell.
          builder: (context, child) => LoadingOverlay(
            key: loadingOverlayKey,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
