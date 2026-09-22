import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/api_client.dart';
import '../data/app_session.dart';
import '../data/hris_api.dart';
import '../data/security_state.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';
import 'company_select_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_photo.dart';
import 'login_screen.dart';
import 'personal_background_tab.dart';

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
  ];

  // Tabs that are not yet available show a "coming soon" placeholder.
  // Certificates is a Versatech-only feature; disabled for other companies.
  Set<String> get _disabledTabs => AppSession.instance.tenant?.id == 'versatech'
      ? const <String>{}
      : const {'Certificates'};

  // Last selectable tab, used to bounce back off disabled (coming-soon) tabs.
  int _lastEnabledIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_guardDisabledTab);
  }

  // Prevents opening a disabled tab (e.g. Certificates) via tap or swipe.
  void _guardDisabledTab() {
    if (_tabController.indexIsChanging) return;
    final i = _tabController.index;
    if (_disabledTabs.contains(_tabs[i])) {
      _tabController.animateTo(_lastEnabledIndex);
    } else {
      _lastEnabledIndex = i;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_guardDisabledTab);
    _tabController.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _ProfileHeroHeader(onSettings: () => _openSettings(context)),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                onTap: (i) {
                  // Keep disabled (coming-soon) tabs unselectable.
                  if (_disabledTabs.contains(_tabs[i])) {
                    _tabController.index = _lastEnabledIndex;
                  }
                },
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
                tabs: _tabs
                    .map((t) => Tab(
                          child: Text(
                            t,
                            style: _disabledTabs.contains(t)
                                ? const TextStyle(color: AppColors.inkFaint)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _EmploymentTab(),
            const PersonalBackgroundTab(),
            _MdrTab(),
            _LinkedAccountsTab(),
            AppSession.instance.tenant?.id == 'versatech'
                ? const _CertificatesTab()
                : const _ComingSoonTab(
                    title: 'Certificates',
                    message: 'Certificates will be available here soon.',
                  ),
          ],
        ),
      ),
    );
  }
}

/// Standalone Security & Privacy page (reached from the profile's settings
/// gear) instead of a profile tab.
class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final tenant = AppSession.instance.tenant;
    await AppSession.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => tenant != null
            ? LoginScreen(company: tenant)
            : const CompanySelectScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: _SecurityPrivacyTab(onLogout: () => _logout(context)),
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
  const _ProfileHeroHeader({required this.onSettings});

  final VoidCallback onSettings;

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
            // Settings gear (scrolls away with the header).
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined,
                          color: AppColors.ink),
                      onPressed: onSettings,
                    ),
                  ),
                ),
              ),
            ),
            // Floating large avatar (tap to change profile photo)
            Positioned(
              bottom: -46,
              child: GestureDetector(
                onTap: () => editProfilePhoto(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
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
                      child: UserAvatar(
                        name: AppSession.instance.userName ?? 'Employee',
                        size: 84,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 54),
        // Employee Name
        Text(
          AppSession.instance.userName ?? 'Employee',
          style: const TextStyle(
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
            Text(
              (AppSession.instance.position?.isNotEmpty ?? false)
                  ? AppSession.instance.position!.toUpperCase()
                  : AppSession.instance.role.name.toUpperCase(),
              style: const TextStyle(
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
class _EmploymentTab extends StatefulWidget {
  @override
  State<_EmploymentTab> createState() => _EmploymentTabState();
}

class _EmploymentTabState extends State<_EmploymentTab> {
  final _reload = AsyncViewController();

  // The only editable "About Me" content.
  String _bio = '';

  @override
  void dispose() {
    _reload.dispose();
    super.dispose();
  }

  Future<void> _editBio(BuildContext context) async {
    final ctrl = TextEditingController(text: _bio);
    final saved = await showPremiumBottomSheet<bool>(
      context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.edit_note_rounded,
                    color: AppColors.brandRed, size: 24),
                SizedBox(width: 10),
                Text('Edit Bio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tell your team a little about yourself.',
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 5,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a short bio about yourself…',
                filled: true,
                fillColor: AppColors.fieldFill,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.brandRed, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() => _bio = ctrl.text.trim());
    if (mounted) {
      showToast(context, 'Your bio has been updated.',
          isSuccess: true, title: 'Bio Updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<Profile>(
      controller: _reload,
      useGlobalLoader: true,
      load: () => HrisApi.instance.getProfile(),
      builder: (context, p) => ListView(
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
              const SizedBox(height: 12),
              Text(
                _bio.isEmpty ? 'No bio yet. Tap “Edit Bio” to add one.' : _bio,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: _bio.isEmpty ? AppColors.inkFaint : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editBio(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.fieldFill,
                    side: const BorderSide(color: AppColors.line),
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Bio',
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
                    onTap: () => editProfilePhoto(context),
                    child: Text(
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
                  Icon(Icons.account_balance_rounded,
                      size: 18, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 14),
              _infoRow('SSS No. :', p.background.sss ?? '—'),
              _infoRow('Pag-IBIG No. :',
                  (p.background.pagibig?.isNotEmpty ?? false)
                      ? p.background.pagibig!
                      : '—'),
              _infoRow('TIN :', p.background.tin ?? '—'),
              _infoRow('Philhealth No. :', p.background.philhealth ?? '—'),
              _infoRow(
                  'Driver\'s License No. :',
                  (p.background.driversLicense?.isNotEmpty ?? false)
                      ? p.background.driversLicense!
                      : '—',
                  isLast: true),
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
                  Icon(Icons.work_outline_rounded,
                      size: 18, color: AppColors.inkSoft),
                ],
              ),
              const SizedBox(height: 14),
              _infoRow('Date Hired :', p.background.dateHired ?? '—'),
              _infoRow(
                  'Years of Service :',
                  p.yearsOfService.isNotEmpty ? p.yearsOfService : '—'),
              _infoRow('Position :', p.role),
              _infoRow('Department :', p.department, isLast: true),
            ],
          ),
        ),
        ],
      ),
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
// TAB 5: CERTIFICATES (Versatech only)
// -----------------------------------------------------------------------------
class _CertificatesTab extends StatefulWidget {
  const _CertificatesTab();

  @override
  State<_CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<_CertificatesTab> {
  final _reload = AsyncViewController();

  // Lets the employee pick a certificate file to upload. Uploads are handled by
  // the HR web portal (the certificate store lives on an internal file share),
  // so here we confirm the selection without writing to the live database.
  Future<void> _upload(Cert cert) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      await showToast(
        context,
        'Your file for "${cert.name}" was selected. Certificate uploads are '
        'finalized by HR on the web portal.',
        isSuccess: true,
        title: 'File Selected',
      );
    } catch (_) {
      if (mounted) {
        showToast(context, "Couldn't open the file picker. Please try again.",
            isSuccess: false, title: 'Upload Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<CertLevel>>(
      controller: _reload,
      useGlobalLoader: true,
      load: () => HrisApi.instance.certificates(),
      builder: (context, levels) {
        if (levels.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text('No certifications available.',
                  style: TextStyle(
                      color: AppColors.inkFaint, fontWeight: FontWeight.w600)),
            ),
          );
        }
        final earned =
            levels.expand((l) => l.items).where((c) => c.active).length;
        final total = levels.expand((l) => l.items).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                const Text('Certification',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandRed.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$earned / $total earned',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandRed)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...levels.expand((lvl) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text('Level ${lvl.level}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                  ),
                  ...lvl.items.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CertRow(cert: c, onUpload: () => _upload(c)),
                      )),
                  const SizedBox(height: 6),
                ]),
          ],
        );
      },
    );
  }
}

class _CertRow extends StatelessWidget {
  const _CertRow({required this.cert, required this.onUpload});
  final Cert cert;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            cert.active
                ? Icons.verified_rounded
                : Icons.workspace_premium_outlined,
            color: cert.active ? AppColors.success : AppColors.inkFaint,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  cert.active
                      ? (cert.fileName.isNotEmpty
                          ? cert.fileName
                          : 'Uploaded')
                      : 'Not uploaded',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: cert.active
                          ? AppColors.success
                          : AppColors.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (cert.active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Active',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success)),
            )
          else
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandRed,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 38),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              label: const Text('Upload'),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: MDR (MEMBER DATA RECORD)
// -----------------------------------------------------------------------------
class _MdrTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AsyncView<Mdr>(
      useGlobalLoader: true,
      load: () => HrisApi.instance.profileMdr(),
      builder: (context, mdr) {
        final entries = mdr.items.entries.toList();
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mdr.status,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < entries.length; i++)
                    _item(entries[i].key, entries[i].value,
                        isLast: i == entries.length - 1),
                ],
              ),
            ),
          ],
        );
      },
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
  IconData _iconFor(String provider) {
    switch (provider) {
      case 'microsoft':
        return Icons.window_rounded;
      case 'google':
        return Icons.g_mobiledata_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'authentik':
        return Icons.verified_user_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<LinkedAccount>>(
      useGlobalLoader: true,
      load: () => HrisApi.instance.linkedAccounts(),
      builder: (context, accounts) {
        if (accounts.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
            children: const [
              _EmptyState(
                icon: Icons.link_off_rounded,
                title: 'No linked accounts',
                message:
                    'You have no external accounts linked to your profile yet.',
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            for (final a in accounts) ...[
              _accountCard(
                icon: _iconFor(a.provider),
                title: a.title,
                subtitle: a.subtitle,
                connected: a.connected,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
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

  bool? _twoFactorOn; // null while loading
  bool _twoFactorBusy = false;

  @override
  void initState() {
    super.initState();
    _sec.addListener(_onStateChange);
    _loadTwoFactor();
    // Keep the toggle in sync with reality: it's ON iff biometric credentials
    // are actually saved (survives sign-out and app updates, where the stored
    // preference flag may lag behind).
    final enrolled = AppSession.instance.hasSavedCredentials;
    if (_sec.biometricsEnabled != enrolled) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _sec.setBiometricsEnabled(enrolled));
    }
  }

  @override
  void dispose() {
    _sec.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTwoFactor() async {
    try {
      final on = await HrisApi.instance.twoFactorStatus();
      if (mounted) setState(() => _twoFactorOn = on);
    } catch (_) {
      if (mounted) setState(() => _twoFactorOn = false);
    }
  }

  // ---- Change password (own page) ----
  Future<void> _changePassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  // ---- Enable biometrics (verify password first, then remember it) ----
  Future<void> _enableBiometrics() async {
    final password = await _promptPassword(
      title: 'Enable Biometric Sign-in',
      message:
          'Confirm your password so we can sign you in with biometrics next time.',
      buttonLabel: 'Confirm & Enable',
      accent: AppColors.success,
    );
    if (password == null) return;
    showLoadingOverlay(context);
    try {
      final ok = await HrisApi.instance.verifyPassword(password);
      if (!ok) {
        hideLoadingOverlay(context);
        if (mounted) showToast(context, 'The password you entered is incorrect. Please try again.', isSuccess: false, title: 'Incorrect Password');
        return;
      }
      // Set the preference before saving creds so a crash between the two can
      // never leave creds with the flag off (which reconciliation would purge).
      _sec.setBiometricsEnabled(true);
      await AppSession.instance.saveBiometricCredentials();
      if (mounted) {
        hideLoadingOverlay(context);
        showToast(context, 'You can now sign in quickly using biometrics.',
            isSuccess: true,
            title: 'Biometric Enabled',
            illustration:
                const FingerprintIllustration(size: 150, enabled: true));
      }
    } on ApiException catch (e) {
      hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    }
  }

  Future<void> _disableBiometrics() async {
    await AppSession.instance.clearBiometricCredentials();
    _sec.setBiometricsEnabled(false);
    if (mounted) {
      showToast(context, 'Biometric sign-in has been turned off.',
          isSuccess: true,
          title: 'Biometric Disabled',
          illustration:
              const FingerprintIllustration(size: 150, enabled: false));
    }
  }

  Future<void> _disableBiometricsWithPassword() async {
    final password = await _promptPassword(
      title: 'Disable Biometric Sign-in',
      message: 'Confirm your password to disable biometric sign-in.',
      buttonLabel: 'Confirm & Disable',
    );
    if (password == null) return;
    showLoadingOverlay(context);
    try {
      final ok = await HrisApi.instance.verifyPassword(password);
      if (!mounted) return;
      hideLoadingOverlay(context);
      if (!ok) {
        showToast(context, 'The password you entered is incorrect. Please try again.', isSuccess: false, title: 'Incorrect Password');
        return;
      }
      await _disableBiometrics();
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    }
  }

  Future<String?> _promptPassword({
    required String title,
    required String message,
    String buttonLabel = 'Confirm',
    Color? accent,
  }) =>
      promptPassword(
        context,
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        accent: accent ?? AppColors.brandRed,
      );

  // ---- Enable 2FA ----
  Future<void> _enableTwoFactor() async {
    if (_twoFactorBusy) return;
    setState(() => _twoFactorBusy = true);
    showLoadingOverlay(context);
    try {
      final setup = await HrisApi.instance.twoFactorSetup();
      if (!mounted) return;
      hideLoadingOverlay(context);
      final enabled = await showPremiumBottomSheet<bool>(
        context,
        isScrollControlled: true,
        builder: (_) => _TwoFactorSetupSheet(setup: setup),
      );
      if (enabled == true && mounted) {
        setState(() => _twoFactorOn = true);
        showToast(context,
            'Two-factor authentication has been successfully enabled.',
            isSuccess: true,
            title: '2FA Enabled',
            illustration: SecurityIllustration(
                size: 150, accent: AppColors.brandRedSoft));
      }
    } on ApiException catch (e) {
      hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    } finally {
      if (mounted) setState(() => _twoFactorBusy = false);
    }
  }

  // ---- Disable 2FA (requires a current code) ----
  Future<void> _disableTwoFactor() async {
    final code = await _promptCode(
      title: 'Disable Two-Factor',
      message:
          'Enter a current code from your authenticator app to turn 2FA off.',
    );
    if (code == null) return;
    setState(() => _twoFactorBusy = true);
    showLoadingOverlay(context);
    try {
      await HrisApi.instance.twoFactorDisable(code);
      if (mounted) {
        hideLoadingOverlay(context);
        setState(() => _twoFactorOn = false);
        showToast(context, 'Two-factor authentication has been disabled.',
            isSuccess: true,
            title: '2FA Disabled',
            illustration: const SecurityIllustration(
                size: 150, accent: Color(0xFF94A3B8)));
      }
    } on ApiException catch (e) {
      hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    } finally {
      if (mounted) setState(() => _twoFactorBusy = false);
    }
  }

  Future<String?> _promptCode(
      {required String title, required String message}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                  counterText: '', hintText: '000000', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: AppColors.brandRed,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
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
                    child: Icon(Icons.fingerprint_rounded,
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
                  AppSwitch(
                    value: _sec.biometricsEnabled,
                    onChanged: (val) async {
                      if (val) {
                        await _enableBiometrics();
                      } else {
                        await _disableBiometricsWithPassword();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Log in securely and quickly using your device\'s biometric sensors without re-typing your password.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Two-Factor Authentication (TOTP) — real, backed by /auth/2fa/*.
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
                    child: Icon(Icons.security_rounded,
                        color: AppColors.brandRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Two-Factor Auth (2FA)',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(
                          _twoFactorOn == null
                              ? 'Checking…'
                              : (_twoFactorOn!
                                  ? 'Active & Protected'
                                  : 'Disabled'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _twoFactorOn == true
                                ? AppColors.success
                                : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_twoFactorOn == null || _twoFactorBusy)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: AppColors.brandRed),
                    )
                  else
                    AppSwitch(
                      value: _twoFactorOn!,
                      onChanged: (val) =>
                          val ? _enableTwoFactor() : _disableTwoFactor(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Use Google Authenticator or Microsoft Authenticator to require a 6-digit code at login.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Change Password — real, backed by /auth/profile/change-password.
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
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.key_rounded, color: AppColors.inkSoft),
                title: const Text('Change Password',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('Update your account password',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                trailing: TextButton(
                  onPressed: _changePassword,
                  child: const Text('Change'),
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
            side: BorderSide(color: AppColors.dangerSoft, width: 1.6),
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
// 2FA SETUP SHEET (QR + verify)
// -----------------------------------------------------------------------------
class _TwoFactorSetupSheet extends StatefulWidget {
  const _TwoFactorSetupSheet({required this.setup});
  final TwoFactorSetup setup;

  @override
  State<_TwoFactorSetupSheet> createState() => _TwoFactorSetupSheetState();
}

class _TwoFactorSetupSheetState extends State<_TwoFactorSetupSheet> {
  final _code = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 6) {
      showToast(context, 'Please enter a valid 6-digit code from your authenticator app.', isSuccess: false, title: 'Invalid Code');
      return;
    }
    setState(() => _verifying = true);
    showLoadingOverlay(context);
    try {
      await HrisApi.instance.twoFactorVerify(code);
      if (!mounted) return;
      hideLoadingOverlay(context);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Verification Failed');
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
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.brandRed, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Set up Two-Factor Auth',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan this QR code in Google Authenticator or Microsoft Authenticator, then enter the 6-digit code it shows.',
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
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
                child: QrImageView(
                  data: widget.setup.otpauthUrl,
                  version: QrVersions.auto,
                  size: 190,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text("Can't scan? Enter this key manually:",
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.setup.secret));
                showToast(context, 'Setup key has been copied to your clipboard.', isSuccess: true, title: 'Copied');
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.setup.secret,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Icon(Icons.copy_rounded,
                        size: 16, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Enter 6-Digit Code',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                  counterText: '', hintText: '000000', isDense: true),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Verify & Enable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED: COMING SOON + EMPTY STATE
// -----------------------------------------------------------------------------
class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
      children: [
        _EmptyState(
          icon: Icons.workspace_premium_outlined,
          title: title,
          message: message,
          badge: 'Coming soon',
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: AppColors.inkFaint),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
        ),
      ],
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
