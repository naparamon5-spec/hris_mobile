import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_session.dart';
import '../data/hris_api.dart';
import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import '../widgets/ui.dart';
import 'company_select_screen.dart';
import 'login_screen.dart';

/// Sets a new password from a forgot-password email link. Opened by the deep
/// link handler in main.dart.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    this.tenantId,
    this.company,
  });

  final String token;

  /// Which company database holds [token]; comes from the link.
  final String? tenantId;

  /// The company for [tenantId] when it is known on this device.
  final Tenant? company;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  bool _done = false;

  Color get _accent => widget.company?.color ?? AppColors.defaultBrand;

  @override
  void dispose() {
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final next = _next.text;
    final confirm = _confirm.text;
    if (next.isEmpty || confirm.isEmpty) {
      showToast(context, 'Please fill in both password fields.',
          isSuccess: false, title: 'Missing Fields');
      return;
    }
    if (next != confirm) {
      showToast(context, 'New password and confirmation do not match.',
          isSuccess: false, title: 'Mismatch');
      return;
    }
    if (next.length < 6) {
      showToast(context, 'New password must be at least 6 characters long.',
          isSuccess: false, title: 'Too Short');
      return;
    }
    setState(() => _saving = true);
    showLoadingOverlay(context);
    try {
      await HrisApi.instance.resetPassword(
        token: widget.token,
        tenant: widget.tenantId,
        next: next,
        confirm: confirm,
      );
      // Whoever was signed in on this phone has to use the new password too.
      if (AppSession.instance.isSignedIn) await AppSession.instance.logout();
      if (!mounted) return;
      hideLoadingOverlay(context);
      setState(() => _done = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      hideLoadingOverlay(context);
      showToast(context, e.message, isSuccess: false, title: 'Error');
    } catch (_) {
      if (!mounted) return;
      hideLoadingOverlay(context);
      showToast(context, 'Something went wrong. Please try again.',
          isSuccess: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goToSignIn() {
    final company = widget.company;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => company != null
            ? LoginScreen(company: company)
            : const CompanySelectScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: _done
          ? null
          : AppBar(
              backgroundColor: AppColors.card,
              elevation: 0,
              foregroundColor: AppColors.ink,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: _done ? _buildDone() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _accent,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter a new password for your account.',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5),
        ),
        const SizedBox(height: 34),
        _passwordField(
          label: 'New Password',
          controller: _next,
          obscure: _obscureNext,
          onToggle: () => setState(() => _obscureNext = !_obscureNext),
          action: TextInputAction.next,
        ),
        const SizedBox(height: 18),
        _passwordField(
          label: 'Confirm Password',
          controller: _confirm,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          action: TextInputAction.done,
        ),
        const SizedBox(height: 26),
        _primaryButton('Reset Password', _save),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        const Center(child: ShieldMark(size: 92)),
        const SizedBox(height: 24),
        const Text(
          'Password updated',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 28),
        _primaryButton('Back to Sign In', _goToSignIn),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required TextInputAction action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: action,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: Text(text),
    );
  }
}
