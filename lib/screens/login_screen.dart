import 'package:flutter/material.dart';

import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
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
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // ---- Brand hero: shield mark + brand sparkles ----
                          const _BrandHero(),
                          const SizedBox(height: 10),
                          const Center(child: ArdentLogo(height: 38)),
                          const SizedBox(height: 22),
                          const Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.brandRed,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Sign in to continue to HRIS.',
                            style: TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 22),
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
                          const SizedBox(height: 12),
                          // ---- Sign in with Authentik (SSO) ----
                          OutlinedButton(
                            onPressed: () {},
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
                                    fontSize: 15,
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
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Protected by Ardent SSO • v1.0.0',
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

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Small branded header: the shield mark flanked by a few brand sparkles,
/// echoing the illustration on the HRIS website without crowding the form.
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Align(
            alignment: Alignment(-0.34, -0.8),
            child: Icon(Icons.add_rounded, size: 13, color: AppColors.info),
          ),
          Align(
            alignment: Alignment(0.32, -0.55),
            child: Icon(Icons.check_rounded, size: 14, color: AppColors.success),
          ),
          Align(
            alignment: Alignment(0.4, 0.7),
            child: Icon(Icons.circle, size: 8, color: Color(0xFFF98D7B)),
          ),
          ShieldMark(size: 78),
        ],
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
