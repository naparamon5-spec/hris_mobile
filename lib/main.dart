import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'data/app_session.dart';
import 'data/app_version_gate.dart';
import 'data/inbox_badges.dart';
import 'data/security_state.dart';
import 'data/notifications/push_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/app_update_screen.dart';
import 'screens/company_select_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/brand.dart';
import 'widgets/ui.dart';

final GlobalKey<NavigatorState> hrisNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _disablePasswordReveal();
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

  await _initCrashReporting();

  // When the session expires while the app is in use (refresh token rejected),
  // force the user back to the login screen instead of leaving them "signed in".
  AppSession.instance.onSessionExpired = () {
    final ctx = hrisNavigatorKey.currentContext;
    if (ctx == null) return;
    // The request that hit the expiry usually had the loader up; its screen is
    // about to be torn down without hiding it.
    resetLoadingOverlay();
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

/// Show only dots while typing passwords (no brief last-letter reveal). The
/// engine reads this from a platform setting, so ask iOS to send it, echoing
/// the current settings so nothing else changes. Best-effort; no-op elsewhere.
Future<void> _disablePasswordReveal() async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return;
  final d = PlatformDispatcher.instance;
  try {
    await const MethodChannel('hris/password_reveal').invokeMethod('disable', {
      'textScaleFactor': d.textScaleFactor,
      'alwaysUse24HourFormat': d.alwaysUse24HourFormat,
      'platformBrightness':
          d.platformBrightness == Brightness.dark ? 'dark' : 'light',
    });
  } catch (_) {}
}

/// Sends uncaught Flutter and async errors to Firebase Crashlytics. Disabled in
/// debug builds so development errors don't pollute the dashboard. Best-effort
/// — a missing Firebase config never blocks startup.
Future<void> _initCrashReporting() async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {}
}

class HrisApp extends StatefulWidget {
  const HrisApp({super.key});

  @override
  State<HrisApp> createState() => _HrisAppState();
}

class _HrisAppState extends State<HrisApp> with WidgetsBindingObserver {
  // Background sign-out: if the app sits in the background for
  // AppSession.backgroundTimeout (3 min), the user is signed out on return.
  // Just opening the multitask switcher (inactive) doesn't count.
  DateTime? _pausedAt;
  // Privacy cover: while the app isn't in the foreground (incl. the multitask
  // switcher), the splash is painted over the UI so the switcher snapshot
  // never shows payslips or other personal data.
  bool _obscured = false;
  // True while the session is being re-validated on resume. The splash cover
  // stays up (with a loader) so an expired session never flashes the home
  // screen before routing to login.
  bool _checkingSession = false;

  // Away at least this long → re-validate the session before revealing the UI.
  static const _revalidateAfter = Duration(seconds: 30);

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
    final obscure = state != AppLifecycleState.resumed || _checkingSession;
    if (obscure != _obscured) setState(() => _obscured = obscure);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Remember when the app left the foreground (persisted, so it also
      // applies if the app is killed while in the background).
      if (_pausedAt == null) {
        _pausedAt = DateTime.now();
        AppSession.instance.markBackgrounded(_pausedAt);
      }
    } else if (state == AppLifecycleState.resumed) {
      final since = _pausedAt;
      _pausedAt = null;
      AppSession.instance.markBackgrounded(null);
      _recheckVersionOnResume();
      // A push received while signed out can still set the OS badge; never
      // leave it showing on a signed-out app.
      if (!AppSession.instance.isSignedIn) InboxBadges.instance.clear();
      if (since == null) return;
      final away = DateTime.now().difference(since);
      if (!AppSession.instance.isSignedIn || away < _revalidateAfter) return;
      _coverWhile(() async {
        if (away >= AppSession.backgroundTimeout) {
          await _signOutToLogin();
        } else {
          // Expired → onSessionExpired routes to login while still covered.
          await AppSession.instance.revalidate();
        }
      });
    }
  }

  // Keeps the splash cover (with a loader) over the app while [task] runs, so
  // the user sees a loading screen — or lands directly on login — instead of
  // the signed-in UI briefly appearing.
  Future<void> _coverWhile(Future<void> Function() task) async {
    setState(() {
      _checkingSession = true;
      _obscured = true;
    });
    try {
      await task();
    } catch (_) {
    } finally {
      // Let the login route's first frame paint before lifting the cover.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        setState(() {
          _checkingSession = false;
          _obscured = false;
        });
      }
    }
  }

  // Resume re-check: a version released while the app sat in memory must still
  // prompt without the user killing the app from multitask. Throttled to once a
  // minute inside [AppVersionGate.shouldRecheckOnResume]; skipped before the
  // splash's launch check has run.
  Future<void> _recheckVersionOnResume() async {
    final gate = AppVersionGate.instance;
    if (!gate.shouldRecheckOnResume) return;
    final decision = await gate.check(tenantId: AppVersionGate.currentTenantId);
    if (!mounted || gate.forcedWallShown) return;
    final ctx = hrisNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (decision.action == UpdateAction.forced) {
      gate.forcedWallShown = true;
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ForceUpdateScreen(storeUrl: decision.storeUrl),
        ),
        (route) => false,
      );
    } else if (decision.action == UpdateAction.soft &&
        !gate.softShownThisLaunch) {
      gate.softShownThisLaunch = true;
      final overlayCtx = hrisNavigatorKey.currentState?.overlay?.context;
      if (overlayCtx != null) {
        showSoftUpdateDialog(overlayCtx, storeUrl: decision.storeUrl);
      }
    }
  }

  // Full sign-out (clears the session, push token and app-icon badge; keeps
  // biometric enrollment) and route back to the login screen.
  Future<void> _signOutToLogin() async {
    await AppSession.instance.logout();
    final ctx = hrisNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    resetLoadingOverlay();
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
          builder: (context, child) => Stack(
            children: [
              LoadingOverlay(
                key: loadingOverlayKey,
                child: child ?? const SizedBox.shrink(),
              ),
              if (_obscured)
                Positioned.fill(
                  child: _PrivacyCover(loading: _checkingSession),
                ),
            ],
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// Splash-style cover shown over the app while it is not in the foreground, so
/// the multitask switcher shows the brand screen instead of the user's data.
class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AniHrisIcon(size: 88),
            SizedBox(height: 20),
            Text(
              'ANI HRIS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Human Resource Information System',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
            if (loading) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 120,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    backgroundColor: const Color(0xFFF3D3D9),
                    valueColor: AlwaysStoppedAnimation(AppColors.brandRed),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
