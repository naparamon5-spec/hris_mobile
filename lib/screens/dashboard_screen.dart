import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'directory_screen.dart';
import 'notifications_screen.dart';
import 'leave_screen.dart';
import 'whos_out_screen.dart';
import 'leave_of_absence_screen.dart';
import 'payroll_screen.dart';
import 'feature_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _TopBar(),
          const SizedBox(height: 16),
          _TodayCard(),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Leave credits',
            actionLabel: 'View details',
            onAction: () => _go(context, const LeaveScreen()),
          ),
          const SizedBox(height: 12),
          _LeaveBalance(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 12),
          _QuickActions(),
          const SizedBox(height: 20),
          SectionHeader(
            title: "Who's out today",
            actionLabel: 'Calendar',
            onAction: () => _go(context, _whosOutPage()),
          ),
          const SizedBox(height: 12),
          _WhosOutToday(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'This month'),
          const SizedBox(height: 12),
          _MonthStats(),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// The Who's Out calendar wrapped in a Scaffold so it gets a back button when
  /// pushed from the dashboard (on its own tab it has no app bar).
  Widget _whosOutPage() => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text("Who's Out")),
        body: const WhosOutScreen(),
      );
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Stack(
            children: [
              const UserAvatar(name: kCurrentUser, size: 44),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello, Ramon 👋',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'PROGRAMMER • ANI',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _circleIcon(
          context,
          icon: Icons.groups_outlined,
          tooltip: 'Directory',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DirectoryScreen()),
          ),
        ),
        const SizedBox(width: 8),
        _circleIcon(
          context,
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badge: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _circleIcon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    bool badge = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.ink, size: 21),
            if (badge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.brandRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(
        Icons.event_busy_outlined,
        'Leave',
        () => _go(context, const LeaveOfAbsenceScreen()),
      ),
      _QA(
        Icons.access_time_rounded,
        'Overtime',
        () => _go(
          context,
          const FeatureScreen(
            title: 'Overtime',
            icon: Icons.access_time_rounded,
            color: AppColors.brandRed,
          ),
        ),
      ),
      _QA(
        Icons.calendar_month_outlined,
        'Timesheet',
        () => _go(
          context,
          const FeatureScreen(
            title: 'Timesheet',
            icon: Icons.calendar_month_outlined,
            color: AppColors.brandRed,
          ),
        ),
      ),
      _QA(
        Icons.receipt_long_outlined,
        'Payslip',
        () => _go(context, const PayrollScreen()),
      ),
    ];
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(child: actions[i]),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  void _go(BuildContext context, Widget s) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => s));
}

class _QA extends StatelessWidget {
  const _QA(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line, width: 1),
          boxShadow: kSoftShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.inkSoft.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.inkSoft, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim "today" banner: date, shift window and an attendance status pill.
/// Informational only — no clock in/out controls.
class _TodayCard extends StatelessWidget {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _wd = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday',
  ];

  /// Semi-monthly payday (15th / end of month) — next one from the demo date.
  DateTime get _payday {
    final t = kToday;
    if (t.day < 15) return DateTime(t.year, t.month, 15);
    return DateTime(t.year, t.month + 1, 0); // last day of this month
  }

  int get _daysToPayday => _payday.difference(kToday).inDays;

  @override
  Widget build(BuildContext context) {
    final t = kToday;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_wd[t.weekday - 1]}, ${_months[t.month - 1]} ${t.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next payday • ${_months[_payday.month - 1]} ${_payday.day}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_daysToPayday',
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
                const Text(
                  'days',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
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

/// Preview of who is on leave today, with overlapping avatars. Tapping opens
/// the full Who's Out calendar.
class _WhosOutToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final out = whosOutOn(kToday);

    if (out.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(
              icon: Icons.emoji_people_rounded,
              color: AppColors.success,
              size: 44,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "Everyone's in today 🎉",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    const maxAvatars = 4;
    final shown = out.take(maxAvatars).toList();
    final extra = out.length - shown.length;

    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(title: const Text("Who's Out")),
            body: const WhosOutScreen(),
          ),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 30.0 + (shown.length - 1) * 20 + (extra > 0 ? 20 : 0),
            height: 36,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 20.0,
                    child: _ring(
                      child: InitialsAvatar(
                        name: shown[i].name,
                        size: 32,
                        color: shown[i].color,
                      ),
                    ),
                  ),
                if (extra > 0)
                  Positioned(
                    left: shown.length * 20.0,
                    child: _ring(
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.fieldFill,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '+$extra',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${out.length} ${out.length == 1 ? "person" : "people"} out today',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shown.map((e) => e.name.split(' ').first).join(', ') +
                      (extra > 0 ? ' & $extra more' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }

  Widget _ring({required Widget child}) => Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
        ),
        padding: const EdgeInsets.all(2),
        child: child,
      );
}

/// A row of three at-a-glance stats for the current month.
class _MonthStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _stat(Icons.event_busy_rounded, '2', 'Leaves taken'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _stat(Icons.access_time_rounded, '8.5', 'OT hours'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _stat(Icons.fact_check_rounded, '3', 'Call Approvals'),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandRed, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Leave balance with VL and SL as prominent hero tiles.
class _LeaveBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _bigCredit(
                context,
                label: 'Vacation Leave',
                short: 'VL',
                val: '9.0',
                icon: Icons.beach_access_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigCredit(
                context,
                label: 'Sick Leave',
                short: 'SL',
                val: '7.0',
                icon: Icons.healing_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bigCredit(
    BuildContext context, {
    required String label,
    required String short,
    required String val,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.brandRed, size: 18),
              ),
              const Spacer(),
              Text(
                short,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaint,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandRed,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
