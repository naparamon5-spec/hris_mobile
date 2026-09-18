import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// A clearly-visible field border (the theme hairline is too faint on the
/// form background).
const Color _kFieldBorder = Color(0xFFC3C9D4);

/// Full-page Change Password form (current / new / confirm), posting to
/// /auth/profile/change-password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _current.text;
    final next = _next.text;
    final confirm = _confirm.text;
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      showToast(context, 'Please fill in all password fields.', isSuccess: false, title: 'Missing Fields');
      return;
    }
    if (next != confirm) {
      showToast(context, 'New password and confirmation do not match. Please try again.', isSuccess: false, title: 'Mismatch');
      return;
    }
    if (next.length < 6) {
      showToast(context, 'New password must be at least 6 characters long.', isSuccess: false, title: 'Too Short');
      return;
    }
    setState(() => _saving = true);
    showLoadingOverlay(context);
    try {
      await HrisApi.instance
          .changePassword(current: current, next: next, confirm: confirm);
      if (!mounted) return;
      hideLoadingOverlay(context);
      showToast(context, 'Your password has been successfully updated.',
          isSuccess: true,
          title: 'Password Updated',
          illustration:
              SecurityIllustration(
                  size: 150, accent: AppColors.brandRedSoft));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.key_rounded,
                  color: AppColors.brandRed, size: 32),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Update your password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Choose a strong password you don’t use elsewhere.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            ),
            const SizedBox(height: 24),
            _label('Current Password'),
            const SizedBox(height: 7),
            _field(_current, _obscureCurrent, 'Enter current password',
                () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 16),
            _label('New Password'),
            const SizedBox(height: 7),
            _field(_next, _obscureNext, 'At least 6 characters',
                () => setState(() => _obscureNext = !_obscureNext)),
            const SizedBox(height: 16),
            _label('Confirm New Password'),
            const SizedBox(height: 7),
            _field(_confirm, _obscureConfirm, 'Re-enter new password',
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
      );

  Widget _field(TextEditingController c, bool obscure, String hint,
      VoidCallback? onToggle) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.fieldFill,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                icon: EyeToggleIcon(obscured: obscure),
                onPressed: onToggle,
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kFieldBorder, width: 1.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kFieldBorder, width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.brandRed, width: 1.8),
        ),
      ),
    );
  }
}
