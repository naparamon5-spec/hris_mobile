import 'package:flutter/material.dart';

import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import '../widgets/ui.dart';
import 'company_select_screen.dart';

/// Password recovery, matched to the HRIS web "Forgot Password" page:
/// title, "We'll send you instructions in email.", Employee ID / Email,
/// Company selector, "Send Link", and an "Access your account?" link back to
/// sign-in. Sending shows a confirmation state.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.company});

  /// The tenant chosen on the company-select / login screen.
  final Tenant company;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  bool _sent = false;

  // Fixed to the company chosen on the company-select screen — it cannot be
  // changed here.
  late final Tenant _company = widget.company;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  void _sendLink() {
    if (_identifier.text.trim().isEmpty) {
      showToast(context, 'Please enter your Employee ID or email address.',
          isSuccess: false, title: 'Required Field');
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _company.color;
    final base = Theme.of(context);
    final themed = base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: accent),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.25),
        selectionHandleColor: accent,
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
        backgroundColor: AppColors.card,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          foregroundColor: AppColors.ink,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: _sent ? _buildSent() : _buildForm(),
          ),
        ),
      ),
    );
  }

  // ---- Request form (mirrors the website) ----
  Widget _buildForm() {
    final accent = _company.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "We'll send you instructions in email.",
          style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5),
        ),
        const SizedBox(height: 34),
        _label('Employee ID / Email'),
        const SizedBox(height: 8),
        TextField(
          controller: _identifier,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendLink(),
          decoration: const InputDecoration(isDense: true),
        ),
        const SizedBox(height: 18),
        _label('Company'),
        const SizedBox(height: 8),
        // Locked to the company selected on the company-select screen — shown
        // the same way as there (real logo tile), and not changeable here.
        Opacity(
          opacity: 0.85,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                TenantLogo(tenant: _company, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _company.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline_rounded,
                    size: 18, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: _sendLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          child: const Text('Send Link'),
        ),
        const SizedBox(height: 16),
        _accessLink(),
      ],
    );
  }

  // ---- Sent confirmation ----
  Widget _buildSent() {
    final accent = _company.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),
        const Center(child: ShieldMark(size: 92)),
        const SizedBox(height: 24),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'If an account matches ${_identifier.text.trim()} at ${_company.name}, '
          "we've sent password reset instructions to the registered email.",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.inkSoft, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => setState(() => _sent = false),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: AppColors.line),
            foregroundColor: AppColors.ink,
          ),
          child: const Text('Use a different account',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.ink,
          ),
        ),
      );

  Widget _accessLink() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.lock_outline_rounded, size: 16),
        label: const Text('Access your account?'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
