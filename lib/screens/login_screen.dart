import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(
    text: 'ramon.napa@ardentnetworks.com.ph',
  );
  final _password = TextEditingController(text: '••••••••••');
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeShell(),
        transitionsBuilder: (context, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle brand wash in the top corners — keeps the bg white & clean.
          Positioned(
            top: -90,
            right: -70,
            child: _blob(220, AppColors.brandRed.withValues(alpha: 0.07)),
          ),
          Positioned(
            top: 40,
            left: -90,
            child: _blob(180, AppColors.brandMaroon.withValues(alpha: 0.05)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(flex: 2),
                          // ---- Brand mark ----
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: kBrandShadow,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in to your Ardent HR workspace',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 14.5,
                            ),
                          ),
                          const Spacer(flex: 1),
                          // ---- Form ----
                          _field(
                            label: 'Work email',
                            child: TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'you@company.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Password',
                            child: TextField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (v) =>
                                      setState(() => _remember = v ?? false),
                                  activeColor: AppColors.brandRed,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _signIn,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sign In'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: AppColors.inkFaint,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ssoButton(
                                  Icons.fingerprint_rounded,
                                  'Biometrics',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ssoButton(
                                  Icons.business_rounded,
                                  'Company SSO',
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 2),
                          const Center(
                            child: Text(
                              'Protected by Ardent Networks • v1.0.0',
                              style: TextStyle(
                                color: AppColors.inkFaint,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _ssoButton(IconData icon, String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.brandRed),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
