import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'directory_screen.dart';
import 'notifications_screen.dart';
import 'leave_screen.dart';
import 'payroll_screen.dart';
import 'attendance_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _TopBar(),
          const SizedBox(height: 22),
          _CheckInCard(),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 14),
          _QuickActions(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'This month'),
          const SizedBox(height: 14),
          _StatsRow(),
          const SizedBox(height: 24),
          SectionHeader(
              title: 'Time off balance',
              actionLabel: 'Manage',
              onAction: () => _go(context, const LeaveScreen())),
          const SizedBox(height: 14),
          _LeaveBalance(),
          const SizedBox(height: 24),
          SectionHeader(
              title: 'Announcements',
              actionLabel: 'See all',
              onAction: () => _go(context, const NotificationsScreen())),
          const SizedBox(height: 14),
          _Announcement(),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const InitialsAvatar(name: kCurrentUser, size: 50),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning 👋',
                  style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              const Text(kCurrentUser,
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        _circleIcon(
          context,
          icon: Icons.groups_rounded,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DirectoryScreen())),
        ),
        const SizedBox(width: 10),
        _circleIcon(
          context,
          icon: Icons.notifications_none_rounded,
          badge: true,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
      ],
    );
  }

  Widget _circleIcon(BuildContext context,
      {required IconData icon, bool badge = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kSoftShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.ink, size: 23),
            if (badge)
              Positioned(
                top: 12,
                right: 13,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.brandRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: kBrandShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF6CF0A8), size: 9),
                    SizedBox(width: 6),
                    Text('Checked in',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              Text('Mon, Jun 16',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('08:32',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('AM • clock-in',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Office • Makati HQ — 7h 12m worked today',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AttendanceScreen())),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppColors.brandRed, size: 20),
                        SizedBox(width: 8),
                        Text('Clock out',
                            style: TextStyle(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => showToast(context, 'Starting break timer…'),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.coffee_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(Icons.event_available_rounded, 'Request\nLeave', AppColors.brandRed,
          () => _go(context, const LeaveScreen())),
      _QA(Icons.payments_rounded, 'View\nPayslip', AppColors.info,
          () => _go(context, const PayrollScreen())),
      _QA(Icons.fingerprint_rounded, 'My\nAttendance', AppColors.success,
          () => _go(context, const AttendanceScreen())),
      _QA(Icons.groups_rounded, 'Team\nDirectory', AppColors.brandMaroon,
          () => _go(context, const DirectoryScreen())),
    ];
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(child: actions[i]),
          if (i != actions.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  void _go(BuildContext context, Widget s) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => s));
}

class _QA extends StatelessWidget {
  const _QA(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kSoftShadow,
        ),
        child: Column(
          children: [
            IconBadge(icon: icon, color: color, size: 46, iconSize: 24),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.timelapse_rounded,
            tint: AppColors.info,
            value: '168h',
            label: 'Hours worked',
            trend: '+4%',
            up: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.event_busy_rounded,
            tint: AppColors.warning,
            value: '2',
            label: 'Absences',
            trend: '-1',
            up: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            tint: AppColors.brandRed,
            value: '96%',
            label: 'Attendance',
            trend: '+2%',
            up: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    required this.trend,
    required this.up,
  });
  final IconData icon;
  final Color tint;
  final String value;
  final String label;
  final String trend;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: tint, size: 38, iconSize: 20),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: up ? AppColors.success : AppColors.brandRed),
              const SizedBox(width: 3),
              Text(trend,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: up ? AppColors.success : AppColors.brandRed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          _row('Annual leave', 9, 15, AppColors.brandRed),
          const SizedBox(height: 16),
          _row('Sick leave', 7, 10, AppColors.info),
          const SizedBox(height: 16),
          _row('Personal days', 2, 5, AppColors.warning),
        ],
      ),
    );
  }

  Widget _row(String label, int used, int total, Color color) {
    final pct = used / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Text('$used of $total left',
                style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.fieldFill,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _Announcement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('2026 Remote Work Policy',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
                SizedBox(height: 4),
                Text('New hybrid guidelines are now in effect. Tap to read.',
                    style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                        height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
