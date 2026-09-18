import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../data/tenants.dart';
import '../theme/app_colors.dart';
import '../widgets/brand.dart';
import 'login_screen.dart';

/// First step of sign-in: pick the company (tenant). Selecting one opens the
/// login screen scoped to that company; a "Switch company" link there returns
/// here.
class CompanySelectScreen extends StatefulWidget {
  const CompanySelectScreen({super.key});

  @override
  State<CompanySelectScreen> createState() => _CompanySelectScreenState();
}

class _CompanySelectScreenState extends State<CompanySelectScreen> {
  String _query = '';
  late final Future<List<Tenant>> _tenantsFuture = _loadTenants();

  /// Loads companies from `/public/tenants`, falling back to the bundled list
  /// if the backend is unreachable (this is the pre-login entry screen).
  Future<List<Tenant>> _loadTenants() async {
    try {
      final list = await HrisApi.instance.tenants();
      return list.isEmpty ? kTenants : list;
    } catch (_) {
      return kTenants;
    }
  }

  void _select(Tenant t) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(company: t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AniHrisIcon(size: 68)),
              const SizedBox(height: 16),
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
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Select your company to continue',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Company',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search companies…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<Tenant>>(
                  future: _tenantsFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                            color: AppColors.brandRed),
                      );
                    }
                    final results = snap.data!
                        .where((t) =>
                            t.name
                                .toLowerCase()
                                .contains(_query.toLowerCase()) ||
                            t.subtitle
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                        .toList();
                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'No companies found',
                          style: TextStyle(color: AppColors.inkFaint),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _CompanyCard(
                          tenant: results[i],
                          onTap: () => _select(results[i])),
                    );
                  },
                ),
              ),
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
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.tenant, required this.onTap});
  final Tenant tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              TenantLogo(tenant: tenant, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tenant.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded company logo tile. Shows the company's logo image when one is
/// available; otherwise a monogram over its brand gradient.
class TenantLogo extends StatelessWidget {
  const TenantLogo({super.key, required this.tenant, this.size = 40});

  final Tenant tenant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    // Prefer the bundled company logo (assets/logos/<tenant id>.png), shown on a
    // clean white tile so wordmark logos aren't cropped. Falls back to a network
    // logo (if configured) and finally the brand monogram.
    return Image.asset(
      'assets/logos/${tenant.id}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _networkOrMonogram(radius),
      frameBuilder: (context, child, frame, wasSync) =>
          _whiteTile(radius, child),
    );
  }

  // White rounded tile with padding + hairline border for a logo image.
  Widget _whiteTile(BorderRadius radius, Widget child) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _networkOrMonogram(BorderRadius radius) {
    if (tenant.logo != null) {
      return _whiteTile(
        radius,
        Image.network(
          tenant.logo!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Center(child: Text(
            tenant.initial,
            style: TextStyle(
              color: AppColors.defaultBrand,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.44,
            ),
          )),
        ),
      );
    }
    return _monogram(radius);
  }

  Widget _monogram(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: tenant.gradient,
        borderRadius: radius,
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

/// The company's full wordmark logo (`assets/logos/<id>.png`), rendered at
/// [height] with its natural width. Used on the login screen so the selected
/// company shows its real logo. Falls back to the monogram tile + name.
class TenantWordmark extends StatelessWidget {
  const TenantWordmark({
    super.key,
    required this.tenant,
    this.height = 32,
    this.maxWidth = 220,
  });

  final Tenant tenant;
  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height, maxWidth: maxWidth),
      child: Image.asset(
        'assets/logos/${tenant.id}.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TenantLogo(tenant: tenant, size: height * 0.85),
          const SizedBox(width: 8),
          Text(
            tenant.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
