import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_session.dart';
import '../data/biometric_service.dart';
import '../data/security_state.dart';
import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import '../widgets/ui.dart';
import 'company_select_screen.dart';
import 'forgot_password_screen.dart';
import 'home_shell.dart';

/// Sign-in screen, matched to the HRIS web login
/// (hris.ardentnetworks.com.ph): Ardent mark, "Welcome Back!", Employee ID,
/// Password, Company, Log In, and Sign in with Authentik.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.company});

  /// The tenant chosen on the company-select screen; scopes the session.
  final Tenant company;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  bool _bioLoading = false;

  /// When biometrics is on, the credential form is hidden; this reveals it if
  /// the user taps "Use Employee ID & Password".
  bool _showPasswordFallback = false;

  /// What this device actually supports — null while still probing.
  BiometricCapabilities? _caps;
  bool _capsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Remember the company so logout can return here (not the company picker).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppSession.instance.tenant = widget.company;
      }
    });
    _probeBiometrics();
  }

  Future<void> _probeBiometrics() async {
    final caps = await BiometricService.instance.capabilities();
    if (!mounted) return;
    setState(() {
      _caps = caps;
      _capsLoaded = true;
    });
  }

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  // Return to the company picker. Login can be the root route (splash goes
  // straight here when a company was remembered), so popping would leave an
  // empty stack (black screen) — replace the stack with the picker instead.
  void _switchCompany() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CompanySelectScreen()),
      (route) => false,
    );
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

  /// Signs in against the HRIS backend. Validates the fields, calls the API,
  /// stores the session, then continues to 2FA (if enabled) or the home shell.
  Future<void> _signIn() async {
    if (_loading) return;

    final userId = _employeeId.text.trim();
    final password = _password.text;
    if (userId.isEmpty || password.isEmpty) {
      showToast(context, 'Please enter your Employee ID and password.', isSuccess: false, title: 'Missing Fields');
      return;
    }

    setState(() => _loading = true);
    showLoadingOverlay(context);
    try {
      await AppSession.instance.login(
        userId: userId,
        password: password,
        remember: _remember,
      );

      if (!mounted) return;
      hideLoadingOverlay(context);
      _goToHome();
    } on TwoFactorRequiredException {
      if (!mounted) return;
      hideLoadingOverlay(context);
      _show2FAVerification();
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      _password.clear();
      if (mounted) showToast(context, e.message, isSuccess: false);
    } catch (_) {
      if (mounted) hideLoadingOverlay(context);
      _password.clear();
      if (mounted) showToast(context, 'Something went wrong. Please try again.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Runs the real OS biometric prompt (fingerprint / face / iris — whatever
  /// the device offers), then authenticates against the backend.
  Future<void> _authenticateWithBiometrics({String reason = 'Sign in'}) async {
    if (!SecurityState.instance.biometricsEnabled) {
      showToast(context, 'Biometrics is currently disabled. Please enable it in Settings.', isSuccess: false, title: 'Disabled');
      return;
    }
    if (_bioLoading) return;
    setState(() => _bioLoading = true);
    final ok = await BiometricService.instance
        .authenticate(reason: 'Verify to $reason', biometricOnly: true);
    if (!mounted) return;
    setState(() => _bioLoading = false);
    if (ok) {
      _completeBiometric();
    } else {
      showToast(context, 'Authentication was not recognized. Please try again.', isSuccess: false, title: 'Failed');
    }
  }

  /// Device PIN / pattern / passcode unlock via the OS credential prompt.
  Future<void> _signInWithPin() async {
    if (_bioLoading) return;
    setState(() => _bioLoading = true);
    final ok = await BiometricService.instance
        .authenticate(reason: 'Enter your device PIN to sign in', biometricOnly: false);
    if (!mounted) return;
    setState(() => _bioLoading = false);
    if (ok) {
      _completeBiometric();
    } else {
      showToast(context, 'Could not verify your PIN. Please try again.', isSuccess: false, title: 'Failed');
    }
  }

  /// Performs the actual backend sign-in after a biometric / PIN unlock.
  Future<void> _completeBiometric() async {
    if (_bioLoading) return;
    setState(() => _bioLoading = true);
    showLoadingOverlay(context);
    try {
      await AppSession.instance.biometricLogin();
      if (!mounted) return;
      hideLoadingOverlay(context);
      _goToHome();
    } on TwoFactorRequiredException {
      if (!mounted) return;
      hideLoadingOverlay(context);
      _show2FAVerification();
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false);
    } catch (_) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, 'Something went wrong. Please try again.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _bioLoading = false);
    }
  }

  void _show2FAVerification() {
    showPremiumBottomSheet(
      context,
      isScrollControlled: true,
      builder: (ctx) => _TwoFactorLoginSheet(onVerified: () {
        Navigator.pop(ctx);
        _goToHome();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tint the whole login screen with the selected company's brand color so
    // the field focus borders, Log In button and link buttons match it.
    final base = Theme.of(context);
    final accent = widget.company.color;
    final themed = base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: accent),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.25),
        selectionHandleColor: accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: (base.elevatedButtonTheme.style ?? const ButtonStyle())
            .copyWith(backgroundColor: WidgetStatePropertyAll(accent)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (base.textButtonTheme.style ?? const ButtonStyle())
            .copyWith(foregroundColor: WidgetStatePropertyAll(accent)),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: (base.inputDecorationTheme.focusedBorder
                as OutlineInputBorder?)
            ?.copyWith(borderSide: BorderSide(color: accent, width: 1.6)),
      ),
    );
    return Theme(
      data: themed,
      child: Scaffold(
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
                      const SizedBox(height: 20),
                      // ---- Selected company logo ----
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: TenantWordmark(
                              tenant: widget.company,
                              height: 34,
                              maxWidth: 190),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListenableBuilder(
                        listenable: SecurityState.instance,
                        builder: (context, _) {
                          final bioOn =
                              SecurityState.instance.biometricsEnabled;
                          // Biometric-first only when there are credentials to
                          // reuse; otherwise the password form must come first.
                          final canBiometric =
                              bioOn && AppSession.instance.hasSavedCredentials;
                          if (canBiometric && !_showPasswordFallback) {
                            return _biometricPanel();
                          }
                          return _credentialForm(bioOn: bioOn);
                        },
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
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen(
                                      company: widget.company,
                                    ),
                                  ),
                                ),
                              ),
                              _linkButton(
                                icon: Icons.assignment_outlined,
                                label: 'For examination?',
                                color: widget.company.color,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ---- Switch company ----
                          Center(
                            child: TextButton.icon(
                              onPressed: _switchCompany,
                              icon: const Icon(Icons.swap_horiz_rounded,
                                  size: 18),
                              label: const Text('Switch company'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.ink,
                                textStyle: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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
        ),
    );
  }

  /// Biometric-first sign-in panel. Shows only what this device actually
  /// exposes (fingerprint / face / iris) plus a device-PIN fallback.
  Widget _biometricPanel() {
    // Still probing the device.
    if (!_capsLoaded) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.brandRed)),
      );
    }

    final caps = _caps!;
    // The primary (largest) affordance reflects the device's main modality.
    final IconData primaryIcon;
    final String primaryLabel;
    if (caps.hasFace) {
      primaryIcon = Icons.face_rounded;
      primaryLabel = 'Face';
    } else if (caps.hasIris) {
      primaryIcon = Icons.remove_red_eye_rounded;
      primaryLabel = 'Iris';
    } else {
      primaryIcon = Icons.fingerprint_rounded;
      primaryLabel = 'Fingerprint';
    }

    final hasAnyBiometric =
        caps.hasFingerprint || caps.hasFace || caps.hasIris;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasAnyBiometric)
          GestureDetector(
            onTap: _bioLoading
                ? null
                : () => _authenticateWithBiometrics(reason: 'sign in'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.brandRed.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  _bioLoading
                      ? SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(
                              color: AppColors.brandRed),
                        )
                      : Icon(primaryIcon, size: 48, color: AppColors.brandRed),
                  const SizedBox(height: 10),
                  Text(
                    _bioLoading
                        ? 'Signing in…'
                        : 'Tap to sign in with $primaryLabel',
                    style: TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.inkSoft),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No biometrics enrolled on this device. Use your device PIN or password.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        // Only the modalities the device reports, plus the PIN fallback.
        Row(
          children: [
            if (caps.hasFingerprint) ...[
              Expanded(
                child: _bioOption(
                  icon: Icons.fingerprint_rounded,
                  label: 'Fingerprint',
                  onTap: _bioLoading
                      ? null
                      : () => _authenticateWithBiometrics(reason: 'sign in'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (caps.hasFace) ...[
              Expanded(
                child: _bioOption(
                  icon: Icons.face_rounded,
                  label: 'Face',
                  onTap: _bioLoading
                      ? null
                      : () => _authenticateWithBiometrics(reason: 'sign in'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (caps.hasIris) ...[
              Expanded(
                child: _bioOption(
                  icon: Icons.remove_red_eye_rounded,
                  label: 'Iris',
                  onTap: _bioLoading
                      ? null
                      : () => _authenticateWithBiometrics(reason: 'sign in'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _bioOption(
                icon: Icons.pin_rounded,
                label: 'PIN code',
                onTap:
                    (_bioLoading || !caps.deviceSupported) ? null : _signInWithPin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton.icon(
            onPressed: _bioLoading
                ? null
                : () => setState(() => _showPasswordFallback = true),
            icon: const Icon(Icons.password_rounded, size: 16),
            label: const Text('Use Employee ID & Password'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.inkSoft,
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bioOption(
      {required IconData icon,
      required String label,
      required VoidCallback? onTap}) {
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: AppColors.ink),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  /// The Employee ID + Password form (shown when biometrics is off, or after
  /// the user opts to use a password).
  Widget _credentialForm({required bool bioOn}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _field(
          label: 'Password',
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            onSubmitted: (_) => _signIn(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show' : 'Hide',
                icon: EyeToggleIcon(obscured: _obscure),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                activeColor: widget.company.color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Remember me',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _signIn,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : const Text('Log In'),
        ),
        if (bioOn && AppSession.instance.hasSavedCredentials)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showPasswordFallback = false),
              icon: const Icon(Icons.fingerprint_rounded, size: 16),
              label: const Text('Use biometrics instead'),
              style: TextButton.styleFrom(
                foregroundColor: widget.company.color,
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
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
  bool _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      showToast(context, 'Enter the 6-digit code from your authenticator app.', isSuccess: false, title: 'Required Field');
      return;
    }
    setState(() => _verifying = true);
    showLoadingOverlay(context);
    try {
      await AppSession.instance.completeTwoFactor(code);
      if (!mounted) return;
      hideLoadingOverlay(context);
      widget.onVerified();
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false);
    } catch (_) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, 'Could not verify the code. Try again.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
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
          SizedBox(height: 16),
          Row(
            children: [
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
            'Enter the 6-digit verification code from your Authenticator app (e.g. Google Authenticator or Microsoft Authenticator).',
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
            onPressed: _verifying ? null : _verify,
            child: _verifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Verify & Continue'),
          ),
        ],
      ),
    );
  }
}
