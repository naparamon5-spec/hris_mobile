import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'data/app_session.dart';
import 'data/security_state.dart';
import 'data/notifications/push_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/company_select_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/ui.dart';

final GlobalKey<NavigatorState> hrisNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the frontend .env (API base URL) before anything makes a request.
  // Best-effort — a missing/omitted file just falls back to the dart-define
  // or the local dev host (see ApiConfig).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  // Restore the persisted biometric preference before the login screen builds.
  await SecurityState.instance.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Initialize push notifications (FCM). Best-effort — a missing Firebase
  // config never blocks app startup.
  PushService.setNavigatorKey(hrisNavigatorKey);
  await PushService.instance.initialize();

  // When the session expires while the app is in use (refresh token rejected),
  // force the user back to the login screen instead of leaving them "signed in".
  AppSession.instance.onSessionExpired = () {
    final ctx = hrisNavigatorKey.currentContext;
    if (ctx == null) return;
    final t = AppSession.instance.tenant;
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            t != null ? LoginScreen(company: t) : const CompanySelectScreen(),
      ),
      (route) => false,
    );
    showToast(ctx, 'Your session has expired. Please sign in again.',
        isSuccess: false, title: 'Signed out');
  };

  runApp(const HrisApp());
}

class HrisApp extends StatefulWidget {
  const HrisApp({super.key});

  @override
  State<HrisApp> createState() => _HrisAppState();
}

class _HrisAppState extends State<HrisApp> with WidgetsBindingObserver {
  // Auto-lock: how long the app may sit in the background before we require the
  // user to re-authenticate when they come back. Sits inside the 3–5 min range.
  static const Duration _bgLockAfter = Duration(minutes: 3);
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Remember when the app left the foreground.
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _pausedAt;
      _pausedAt = null;
      if (since == null) return;
      final away = DateTime.now().difference(since);
      if (away >= _bgLockAfter && AppSession.instance.isSignedIn) {
        _lockToLogin();
      }
    }
  }

  // Drop the in-memory session and route back to the login (biometric) screen.
  void _lockToLogin() {
    AppSession.instance.lock();
    final ctx = hrisNavigatorKey.currentContext;
    if (ctx == null) return;
    final t = AppSession.instance.tenant;
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            t != null ? LoginScreen(company: t) : const CompanySelectScreen(),
      ),
      (route) => false,
    );
  }

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
          navigatorKey: hrisNavigatorKey,
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
