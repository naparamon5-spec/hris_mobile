import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/brand.dart';
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
    duration: const Duration(milliseconds: 2200),
  );

  late final Animation<double> _check = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) _advance();
      })
      ..forward();
  }

  void _advance() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.1,
            colors: [Colors.white, Color(0xFFFDF3F4), Color(0xFFFCEBEE)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _sparkle(
                      const Alignment(-0.55, -0.85),
                      Icons.check_rounded,
                      15,
                      AppColors.success,
                    ),
                    _sparkle(
                      const Alignment(0.7, -0.4),
                      Icons.star_rounded,
                      13,
                      AppColors.info,
                    ),
                    _sparkle(
                      const Alignment(-0.85, 0.35),
                      Icons.circle,
                      9,
                      const Color(0xFFF98D7B),
                    ),
                    _sparkle(
                      const Alignment(0.85, 0.5),
                      Icons.add_rounded,
                      13,
                      AppColors.info,
                    ),
                    AnimatedBuilder(
                      animation: _check,
                      builder: (_, _) => ShieldMark(
                        size: 168,
                        progress: _check.value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const ArdentLogo(height: 46),
              const SizedBox(height: 18),
              Text(
                'Human Resource Information System'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 130,
                height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
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

  Widget _sparkle(Alignment a, IconData icon, double size, Color color) {
    return Align(
      alignment: a,
      child: FadeTransition(
        opacity: _fade,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
