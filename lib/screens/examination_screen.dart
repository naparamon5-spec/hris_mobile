import 'package:flutter/material.dart';

import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'company_select_screen.dart';

/// Applicant examination entry, matched to the web "Examination" page:
/// company logo, "Welcome!", "Enter Email to continue to examination.",
/// Email address and Submit.
class ExaminationScreen extends StatefulWidget {
  const ExaminationScreen({super.key, required this.company});

  /// The tenant chosen on the company-select / login screen.
  final Tenant company;

  @override
  State<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends State<ExaminationScreen> {
  final _email = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    if (email.isEmpty) {
      showToast(context, 'Please enter your email address.',
          isSuccess: false, title: 'Required Field');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      showToast(context, 'Please enter a valid email address.',
          isSuccess: false, title: 'Invalid Email');
      return;
    }
    // TODO: hook up to the examination endpoint once the server exposes one.
    showToast(context, 'Online examination is not available yet.',
        isSuccess: false, title: 'Coming Soon');
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.company.color;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter Email to continue to examination.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5),
                ),
                const SizedBox(height: 34),
                const Text(
                  'Email address',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Enter Email address',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Company',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                // Locked to the company chosen at sign-in, shown like the
                // Forgot Password screen.
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
                        TenantLogo(tenant: widget.company, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.company.name,
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
