import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/security_state.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    'My Employment',
    'Personal Background',
    'MDR',
    'Linked Accounts',
    'Certificates',
    'Security & Privacy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _ProfileHeroHeader(onLogout: () => _logout(context)),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.brandRed,
                unselectedLabelColor: AppColors.inkSoft,
                indicatorColor: AppColors.brandRed,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _EmploymentTab(),
            _PersonalBackgroundTab(),
            _MdrTab(),
            _LinkedAccountsTab(),
            _CertificatesTab(),
            _SecurityPrivacyTab(onLogout: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Expanded(child: _tabBar),
          const Divider(height: 1, thickness: 1, color: AppColors.line),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// HERO HEADER (City Skyline + Circular Red Avatar + Name/Role)
// -----------------------------------------------------------------------------
class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // City skyline banner
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE2E8F0),
                    Color(0xFFCBD5E1),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _CitySkylinePainter(),
              ),
            ),
            // Floating large avatar
            Positioned(
              bottom: -46,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandRed,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'R',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 54),
        // Employee Name
        const Text(
          'Ramon Napa ( Mon)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        // Role badge / uppercase title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'PROGRAMMER',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: MY EMPLOYMENT
// -----------------------------------------------------------------------------
class _EmploymentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // About Me Card
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'About Me',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.public_rounded, size: 18, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => showToast(context, 'Edit Bio'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.fieldFill,
                    side: const BorderSide(color: AppColors.line),
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Edit Bio',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Verified Employee',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Images',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showToast(context, 'Upload photo'),
                    child: const Text(
                      'Upload',
                      style: TextStyle(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Government Information Card
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Government Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 14),
              _infoRow('SSS No. :', '3522198730'),
              _infoRow('Pag Ibig No. :', '121306723493'),
              _infoRow('TIN :', '692098318'),
              _infoRow('Philhealth No. :', '012508011103'),
              _infoRow('Drivers License No. :', '—', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Current Employment Card
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Current Employment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.settings_outlined,
                      size: 18, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 14),
              _infoRow('Company :', 'Ardent Networks Inc.'),
              _infoRow('Department :', 'Information Technology'),
              _infoRow('Position :', 'PROGRAMMER'),
              _infoRow('Employment Status :', 'Regular'),
              _infoRow('Shift :', '08:30 AM - 05:30 PM (Makati HQ)'),
              _infoRow('Date Hired :', 'March 15, 2023', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 145,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.8),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: PERSONAL BACKGROUND
// -----------------------------------------------------------------------------
class _PersonalBackgroundTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              _row('Full Name', 'Ramon Napa'),
              _row('Nickname', 'Mon'),
              _row('Gender', 'Male'),
              _row('Civil Status', 'Single'),
              _row('Birth Date', 'August 14, 1995'),
              _row('Blood Type', 'O+'),
              _row('Mobile', '+63 917 882 1920'),
              _row('Work Email', 'ramon.napa@ardentnetworks.com.ph'),
              _row('Address', 'Makati City, Metro Manila', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              _row('Contact Name', 'Maria Napa'),
              _row('Relationship', 'Mother'),
              _row('Contact Phone', '+63 917 123 4567', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.8),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: MDR (MEMBER DATA RECORD)
// -----------------------------------------------------------------------------
class _MdrTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'PhilHealth MDR Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _item('PhilHealth PIN', '01-250801110-3'),
              _item('Membership Category', 'Employed - Private Sector'),
              _item('Employer', 'Ardent Networks Inc.'),
              _item('Monthly Contribution', '₱500.00'),
              _item('Declared Dependents', '0 (None)'),
              _item('Last Contribution Period', 'May 2026', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.8),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: LINKED ACCOUNTS
// -----------------------------------------------------------------------------
class _LinkedAccountsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _accountCard(
          icon: Icons.window_rounded,
          title: 'Microsoft 365',
          subtitle: 'ramon.napa@ardentnetworks.com.ph',
          connected: true,
        ),
        const SizedBox(height: 12),
        _accountCard(
          icon: Icons.g_mobiledata_rounded,
          title: 'Google Workspace',
          subtitle: 'Connected for Calendar & Meet',
          connected: true,
        ),
        const SizedBox(height: 12),
        _accountCard(
          icon: Icons.code_rounded,
          title: 'GitHub',
          subtitle: '@ramonnapa',
          connected: true,
        ),
        const SizedBox(height: 12),
        _accountCard(
          icon: Icons.verified_user_outlined,
          title: 'Authentik SSO',
          subtitle: 'Enterprise Identity Provider',
          connected: true,
        ),
      ],
    );
  }

  Widget _accountCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool connected,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Connected',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 5: CERTIFICATES
// -----------------------------------------------------------------------------
class _CertificatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _certItem(
          'Flutter Certified Application Developer',
          'Google Cloud & Flutter • Issued 2025',
          Icons.verified_rounded,
        ),
        const SizedBox(height: 12),
        _certItem(
          'AWS Certified Cloud Practitioner',
          'Amazon Web Services • Issued 2024',
          Icons.cloud_done_rounded,
        ),
        const SizedBox(height: 12),
        _certItem(
          'ITIL® 4 Foundation Certificate',
          'AXELOS Global Best Practice • Issued 2023',
          Icons.school_rounded,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showToast(context, 'Add certificate'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Certificate / Training'),
        ),
      ],
    );
  }

  Widget _certItem(String title, String issuer, IconData icon) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandRed, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  issuer,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 6: SECURITY & PRIVACY (BIOMETRICS, 2FA, PASSWORDS, SESSIONS)
// -----------------------------------------------------------------------------
class _SecurityPrivacyTab extends StatefulWidget {
  const _SecurityPrivacyTab({required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<_SecurityPrivacyTab> createState() => _SecurityPrivacyTabState();
}

class _SecurityPrivacyTabState extends State<_SecurityPrivacyTab> {
  final _sec = SecurityState.instance;

  @override
  void initState() {
    super.initState();
    _sec.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _sec.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _show2FADialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TwoFactorSetupSheet(),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                isDense: true,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                isDense: true,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              showToast(context, 'Password updated successfully!');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _testBiometrics() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 10),
            Icon(Icons.fingerprint_rounded, size: 64, color: AppColors.brandRed),
            SizedBox(height: 16),
            Text(
              'Biometric Authentication',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            SizedBox(height: 8),
            Text(
              'Touch sensor or look at camera to verify your identity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            SizedBox(height: 10),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Biometrics Card
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint_rounded,
                        color: AppColors.brandRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Biometric Login',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Face ID / Fingerprint recognition',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sec.biometricsEnabled,
                    activeColor: AppColors.brandRed,
                    onChanged: (val) {
                      _sec.setBiometricsEnabled(val);
                      showToast(
                          context,
                          val
                              ? 'Biometric sign-in enabled'
                              : 'Biometric sign-in disabled');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Log in securely and quickly using your device\'s biometric sensors without re-typing your password.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _testBiometrics,
                icon: const Icon(Icons.fingerprint_rounded, size: 18),
                label: const Text('Test Biometric Sensor'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Two-Factor Authentication (2FA) Card
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security_rounded,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Two-Factor Auth (2FA)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _sec.twoFactorEnabled ? 'Active & Protected' : 'Disabled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _sec.twoFactorEnabled
                                ? AppColors.success
                                : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sec.twoFactorEnabled,
                    activeColor: AppColors.brandRed,
                    onChanged: (val) {
                      if (val) {
                        _show2FADialog();
                      } else {
                        _sec.setTwoFactorEnabled(false);
                        showToast(context, '2FA has been disabled');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Method: ${_sec.twoFactorMethod}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Adds an extra layer of security requiring a 6-digit verification code when logging in from new devices.',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _show2FADialog,
                icon: const Icon(Icons.qr_code_rounded, size: 18),
                label: const Text('Configure 2FA & Backup Codes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Security Settings (Password & Sessions)
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Security Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.key_rounded, color: AppColors.inkSoft),
                title: const Text('Current Password',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('Last changed 45 days ago',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                trailing: TextButton(
                  onPressed: _showPasswordDialog,
                  child: const Text('Change'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_rounded, color: AppColors.inkSoft),
                title: const Text('Active Sessions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('iPhone 15 Pro • Active now',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                trailing: TextButton(
                  onPressed: () => showToast(context, 'All other sessions logged out'),
                  child: const Text('Log out others'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Log out button
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandRed,
            side: const BorderSide(color: AppColors.dangerSoft, width: 1.6),
            backgroundColor: AppColors.dangerSoft,
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text('ANI HRIS • v1.0.0',
              style: TextStyle(
                  color: AppColors.inkFaint,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2FA SETUP MODAL SHEET
// -----------------------------------------------------------------------------
class _TwoFactorSetupSheet extends StatefulWidget {
  @override
  State<_TwoFactorSetupSheet> createState() => _TwoFactorSetupSheetState();
}

class _TwoFactorSetupSheetState extends State<_TwoFactorSetupSheet> {
  final _codeController = TextEditingController();
  final _sec = SecurityState.instance;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyAndEnable() {
    _sec.setTwoFactorEnabled(true);
    Navigator.pop(context);
    showToast(context, '2FA successfully configured & verified!');
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
              Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.brandRed, size: 24),
              SizedBox(width: 10),
              Text(
                'Two-Factor Authentication Setup',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan this QR code with Google Authenticator or Microsoft Authenticator, or enter the setup key manually.',
            style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: const [
                  Icon(Icons.qr_code_2_rounded, size: 130, color: AppColors.ink),
                  SizedBox(height: 6),
                  Text(
                    'Key: ANI-HRIS-8842-SEC',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter 6-Digit Verification Code',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _verifyAndEnable,
            child: const Text('Verify & Activate 2FA'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SKYLINE PAINTER
// -----------------------------------------------------------------------------
class _CitySkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // Buildings silhouette path
    final w = size.width;
    final h = size.height;

    path.lineTo(0, h * 0.55);
    path.lineTo(w * 0.08, h * 0.55);
    path.lineTo(w * 0.08, h * 0.35);
    path.lineTo(w * 0.16, h * 0.35);
    path.lineTo(w * 0.16, h * 0.48);
    path.lineTo(w * 0.22, h * 0.48);
    path.lineTo(w * 0.22, h * 0.25);
    path.lineTo(w * 0.28, h * 0.25);
    path.lineTo(w * 0.28, h * 0.60);
    path.lineTo(w * 0.38, h * 0.60);
    path.lineTo(w * 0.38, h * 0.30);
    path.lineTo(w * 0.44, h * 0.30);
    path.lineTo(w * 0.44, h * 0.50);
    path.lineTo(w * 0.56, h * 0.50);
    path.lineTo(w * 0.56, h * 0.28);
    path.lineTo(w * 0.64, h * 0.28);
    path.lineTo(w * 0.64, h * 0.45);
    path.lineTo(w * 0.72, h * 0.45);
    path.lineTo(w * 0.72, h * 0.20);
    path.lineTo(w * 0.80, h * 0.20);
    path.lineTo(w * 0.80, h * 0.52);
    path.lineTo(w * 0.90, h * 0.52);
    path.lineTo(w * 0.90, h * 0.38);
    path.lineTo(w, h * 0.38);
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
