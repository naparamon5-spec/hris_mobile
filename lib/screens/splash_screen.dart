import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/app_version_gate.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import 'app_update_screen.dart';
import 'company_select_screen.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Branded launch screen. Draws the shield-and-check mark on, then hands off
/// to the login screen. In production this is also where you'd check for an
/// existing session / stored biometric token before routing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  // Restore a persisted session in parallel with the intro animation.
  final Future<bool> _restore = AppSession.instance.restore();

  @override
  void initState() {
    super.initState();
    _c
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) _advance();
      })
      ..forward();
  }

  Future<void> _advance() async {
    // Wait for the restore attempt (already running) to finish, then route.
    final restored = await _restore;
    if (!mounted) return;

    // Launch-time version gate. A forced update replaces everything with a
    // blocking wall; a soft update is shown as a dialog after routing. Any
    // failure resolves to "none", so the check never keeps a user out.
    final decision =
        await AppVersionGate.instance.check(tenantId: AppVersionGate.currentTenantId);
    if (!mounted) return;

    if (decision.action == UpdateAction.forced) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ForceUpdateScreen(storeUrl: decision.storeUrl),
        ),
      );
      return;
    }

    final Widget next;
    if (restored) {
      next = const HomeShell();
    } else {
      final tenant = AppSession.instance.tenant;
      next = tenant != null
          ? LoginScreen(company: tenant)
          : const CompanySelectScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    // Soft prompt: after the destination is on screen, offer the update.
    if (decision.action == UpdateAction.soft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = context;
        if (ctx.mounted) {
          showSoftUpdateDialog(ctx, storeUrl: decision.storeUrl);
        }
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AniHrisIcon(size: 88),
              const SizedBox(height: 20),
              const Text(
                'ANI HRIS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Human Resource Information System',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 120,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFF3D3D9),
                    valueColor: AlwaysStoppedAnimation(AppColors.brandRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
