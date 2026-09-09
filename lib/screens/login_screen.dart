import 'package:flutter/material.dart';

import '../data/security_state.dart';
import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import '../widgets/ui.dart';
import 'home_shell.dart';

/// Sign-in screen, matched to the HRIS web login
/// (hris.ardentnetworks.com.ph): Ardent mark, "Welcome Back!", Employee ID,
/// Password, Company, Log In, and Sign in with Authentik.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  /// One shared app used by several companies — the tenant chosen here scopes
  /// the whole session, matching the web app's Company field.
  Tenant _company = kTenants.first;

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickCompany() async {
    final selected = await showModalBottomSheet<Tenant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (_) => _CompanySheet(selected: _company),
    );
    if (selected != null) setState(() => _company = selected);
  }

  void _goToHome() {
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

  void _signIn() {
    if (SecurityState.instance.twoFactorEnabled) {
      _show2FAVerification();
    } else {
      _goToHome();
    }
  }

  void _authenticateWithBiometrics() {
    if (!SecurityState.instance.biometricsEnabled) {
      showToast(context, 'Biometrics is currently disabled in Settings.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BiometricScanDialog(
        onSuccess: () {
          Navigator.pop(ctx);
          if (SecurityState.instance.twoFactorEnabled) {
            _show2FAVerification();
          } else {
            _goToHome();
          }
        },
      ),
    );
  }

  void _show2FAVerification() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TwoFactorLoginSheet(onVerified: () {
        Navigator.pop(ctx);
        _goToHome();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Center(child: AniHrisIcon(size: 72)),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text(
                          'ANI HRIS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Sign in to your employee account',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                          // ---- Employee ID ----
                          _field(
                            label: 'Employee ID',
                            child: TextField(
                              controller: _employeeId,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Enter Employee ID',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // ---- Password ----
                          _field(
                            label: 'Password',
                            child: TextField(
                              controller: _password,
                              obscureText: _obscure,
                              onSubmitted: (_) => _signIn(),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Enter password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'Show' : 'Hide',
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
                          const SizedBox(height: 14),
                          // ---- Company (multi-tenant selector) ----
                          _field(
                            label: 'Company',
                            child: _CompanyField(
                              tenant: _company,
                              onTap: _pickCompany,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ---- Remember me ----
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
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ---- Log In ----
                          ElevatedButton(
                            onPressed: _signIn,
                            child: const Text('Log In'),
                          ),
                          const SizedBox(height: 10),
                          // ---- Sign in with Biometrics ----
                          OutlinedButton(
                            onPressed: _authenticateWithBiometrics,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.line),
                              backgroundColor: AppColors.fieldFill,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.fingerprint_rounded,
                                  size: 22,
                                  color: AppColors.brandRed,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Sign in with Biometrics / Face ID',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ---- Sign in with Authentik (SSO) ----
                          OutlinedButton(
                            onPressed: () => showToast(context, 'Authentik SSO triggered'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 20,
                                  color: AppColors.authentik,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Sign in with Authentik',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // ---- Helper links ----
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _linkButton(
                                icon: Icons.lock_outline_rounded,
                                label: 'Forgot your password?',
                                color: AppColors.inkSoft,
                                onTap: () {},
                              ),
                              _linkButton(
                                icon: Icons.assignment_outlined,
                                label: 'For examination?',
                                color: AppColors.brandRed,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'Protected by ANI SSO • v1.0.0',
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

  Widget _linkButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Company selector styled like the text fields. Shows the current tenant's
/// logo tile + name and opens a branded picker sheet on tap.
class _CompanyField extends StatelessWidget {
  const _CompanyField({required this.tenant, required this.onTap});

  final Tenant tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _TenantLogo(tenant: tenant, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tenant.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Rounded logo tile with the tenant's initial over its brand gradient.
class _TenantLogo extends StatelessWidget {
  const _TenantLogo({required this.tenant, this.size = 40});

  final Tenant tenant;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: tenant.gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        tenant.initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.44,
        ),
      ),
    );
  }
}

/// Bottom-sheet company picker — the multi-tenant chooser, searchable and
/// branded, that the Company field opens.
class _CompanySheet extends StatefulWidget {
  const _CompanySheet({required this.selected});

  final Tenant selected;

  @override
  State<_CompanySheet> createState() => _CompanySheetState();
}

class _CompanySheetState extends State<_CompanySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = kTenants
        .where((t) =>
            t.name.toLowerCase().contains(_query.toLowerCase()) ||
            t.subtitle.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: Row(
                children: const [
                  Text(
                    'Select your company',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 6),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search companies…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final t = results[i];
                  final isSel = t.id == widget.selected.id;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(t),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: _TenantLogo(tenant: t, size: 44),
                    title: Text(
                      t.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      t.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                    trailing: isSel
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.brandRed)
                        : const Icon(Icons.circle_outlined,
                            color: AppColors.inkFaint),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BIOMETRIC SCAN DIALOG
// -----------------------------------------------------------------------------
class _BiometricScanDialog extends StatefulWidget {
  const _BiometricScanDialog({required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  State<_BiometricScanDialog> createState() => _BiometricScanDialogState();
}

class _BiometricScanDialogState extends State<_BiometricScanDialog> {
  bool _success = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() => _success = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onSuccess();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _success
                  ? Container(
                      key: const ValueKey('success'),
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 40),
                    )
                  : Container(
                      key: const ValueKey('scanning'),
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fingerprint_rounded,
                          color: AppColors.brandRed, size: 40),
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              _success ? 'Identity Verified' : 'Scanning Biometrics…',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              _success
                ? 'Welcome back, Ramon'
                : 'Confirm Face ID or Touch sensor to proceed',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        if (!_success)
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Use Password Instead'),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2FA VERIFICATION SHEET ON LOGIN
// -----------------------------------------------------------------------------
class _TwoFactorLoginSheet extends StatefulWidget {
  const _TwoFactorLoginSheet({required this.onVerified});
  final VoidCallback onVerified;

  @override
  State<_TwoFactorLoginSheet> createState() => _TwoFactorLoginSheetState();
}

class _TwoFactorLoginSheetState extends State<_TwoFactorLoginSheet> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verify() {
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.security_rounded,
                  color: AppColors.brandRed, size: 24),
              SizedBox(width: 10),
              Text(
                'Two-Factor Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter the 6-digit verification code from your Authenticator app (e.g. Google Authenticator) or SMS.',
            style: TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
              isDense: true,
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _verify,
            child: const Text('Verify & Continue'),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => showToast(context, 'Backup SMS OTP sent to +63 917 •••• 4567'),
              child: const Text(
                'Send code via SMS instead',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
