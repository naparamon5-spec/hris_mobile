import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              const Text('Profile',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => showToast(context, 'Edit profile'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: kSoftShadow,
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: AppColors.ink, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileCard(),
          const SizedBox(height: 20),
          _StatsStrip(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 12),
          _MenuGroup(items: [
            _MenuItem(Icons.person_outline_rounded, 'Personal information',
                AppColors.brandRed),
            _MenuItem(Icons.work_outline_rounded, 'Employment details',
                AppColors.info),
            _MenuItem(Icons.folder_outlined, 'Documents & contracts',
                AppColors.brandMaroon),
            _MenuItem(Icons.account_balance_wallet_outlined,
                'Bank & tax details', AppColors.success),
          ]),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: 12),
          _MenuGroup(items: [
            _MenuItem(Icons.notifications_none_rounded, 'Notifications',
                AppColors.warning,
                trailing: 'On'),
            _MenuItem(Icons.lock_outline_rounded, 'Security & privacy',
                AppColors.info),
            _MenuItem(Icons.help_outline_rounded, 'Help & support',
                AppColors.brandMaroon),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
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
            child: Text('Ardent HR • v1.0.0',
                style: TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const InitialsAvatar(name: kCurrentUser, size: 70),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A1A1F), width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(kCurrentUser,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(kCurrentRole,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13.5)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('ARD-2041 • Engineering',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ],
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

class _StatsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _stat('3.5', 'Years'),
          _divider(),
          _stat('18', 'Leave days'),
          _divider(),
          _stat('96%', 'Attendance'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 34, color: AppColors.line);
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.color, {this.trailing});
  final IconData icon;
  final String label;
  final Color color;
  final String? trailing;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showToast(context, items[i].label),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    IconBadge(
                        icon: items[i].icon,
                        color: items[i].color,
                        size: 40,
                        iconSize: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(items[i].label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                    if (items[i].trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(items[i].trailing!,
                            style: const TextStyle(
                                color: AppColors.inkFaint,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inkFaint),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
