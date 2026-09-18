import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/hris_api.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';
import 'notifications_screen.dart';
import 'leave_hours_screen.dart';
import 'whos_out_screen.dart';
import 'leave_of_absence_screen.dart';
import 'approval_list_screen.dart';
import 'approvals_center_screen.dart';
import 'other_requests_screen.dart';
import 'timesheet_screen.dart';
import 'payslip_screen.dart';
import 'home_shell.dart';

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
            onAction: () => _go(context, const LeaveHoursScreen()),
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
            // Switch to the Who's Out tab (keeps the bottom nav, no back button).
            onAction: () => HomeShellScope.of(context)?.selectTab(2),
          ),
          const SizedBox(height: 12),
          _WhosOutToday(),
          _ApproverPendingSection(),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Recent activity',
            actionLabel: 'View all',
            onAction: () => HomeShellScope.of(context)?.selectTab(1),
          ),
          const SizedBox(height: 12),
          _RecentActivity(),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _TopBar extends StatelessWidget {
  /// First name, capitalized (e.g. "RAMON ARGONZA NAPA" -> "Ramon").
  String _firstName(String? full) {
    final name = (full ?? 'there').trim();
    if (name.isEmpty) return 'there';
    final first = name.split(' ').first;
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  /// Abbreviates a multi-word company to its initials so it fits on one line
  /// (e.g. "ARDENT NETWORKS INC." -> "ANI"); short names are kept as-is.
  String _shortCompany(String company) {
    final words =
        company.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return company;
    return words
        .map((w) => w.replaceAll(RegExp(r'[^A-Za-z]'), ''))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  /// "POSITION • COMPANY" from the live session, falling back to role/privilege
  /// and the company name if either is missing.
  String _positionCompany() {
    final s = AppSession.instance;
    final position = (s.position?.isNotEmpty ?? false)
        ? s.position!
        : s.role.name.toUpperCase();
    final company =
        (s.company?.isNotEmpty ?? false) ? _shortCompany(s.company!) : 'ANI';
    return '$position • $company';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          // Switch to the Profile tab so the bottom nav stays visible, instead
          // of pushing a full-screen route over the shell.
          onTap: () => HomeShellScope.of(context)?.selectTab(3),
          child: UserAvatar(
              name: AppSession.instance.userName ?? kCurrentUser, size: 44),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${_firstName(AppSession.instance.userName)} 👋',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _positionCompany(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
          ApprovalListScreen(
            title: 'Overtime',
            subtitle: 'File and track overtime requests.',
            icon: Icons.access_time_filled_rounded,
            txnDateLabel: 'Overtime date',
            showHours: true,
            type: 'overtime',
          ),
        ),
      ),
      _QA(
        Icons.calendar_month_outlined,
        'Timesheet',
        () => _go(context, const TimesheetScreen()),
      ),
      _QA(
        Icons.receipt_long_outlined,
        'Payslip',
        () => _go(context, const PayslipScreen()),
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

  /// Today's real calendar date (time-of-day stripped so day math is exact).
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Semi-monthly payday: the 15th, or the last day of the month. Returns the
  /// next one on/after today (so payday itself shows "0 days").
  DateTime get _payday {
    final t = _today;
    if (t.day <= 15) return DateTime(t.year, t.month, 15);
    return DateTime(t.year, t.month + 1, 0); // last day of this month
  }

  int get _daysToPayday => _payday.difference(_today).inDays;

  @override
  Widget build(BuildContext context) {
    final t = _today;
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
                  _daysToPayday == 0
                      ? 'Payday • ${_months[_payday.month - 1]} ${_payday.day}'
                      : 'Next payday • ${_months[_payday.month - 1]} ${_payday.day}',
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _daysToPayday == 0
                  ? [
                      Text(
                        'Payday',
                        style: TextStyle(
                          color: AppColors.brandRed,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1,
                        ),
                      ),
                    ]
                  : [
                Text(
                  '$_daysToPayday',
                  style: TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
                Text(
                  _daysToPayday == 1 ? 'day' : 'days',
                  style: const TextStyle(
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
  /// Fetches this month from the backend (same source as the calendar) and
  /// keeps only those whose leave/CA range covers today.
  Future<List<OutEntry>> _loadToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final records = await HrisApi.instance.whosOutMonth(now.month, now.year);
    return records
        .map(OutEntry.fromRecord)
        .where((e) => e.covers(today))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<OutEntry>>(
      load: _loadToday,
      useGlobalLoader: true,
      builder: (context, out) {
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
          onTap: () => HomeShellScope.of(context)?.selectTab(2),
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkFaint),
            ],
          ),
        );
      },
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

class _ApproverPendingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApprovalAccess>(
      future: HrisApi.instance.approvalAccess(),
      builder: (context, snap) {
        final acc = snap.data;
        if (acc == null ||
            !acc.isApprover ||
            (acc.pending == 0 && acc.pendingRequests == 0)) {
          return const SizedBox.shrink();
        }
        final total = acc.pending + acc.pendingRequests;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const SectionHeader(title: 'Approvals required'),
            const SizedBox(height: 12),
            SoftCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ApprovalsCenterScreen(
                      module: 'records',
                      scope: 'pending',
                    ),
                  ),
                );
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.verified_user_rounded,
                    color: AppColors.brandRed,
                    size: 46,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$total filing${total == 1 ? '' : 's'} waiting for approval',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          acc.pendingRequests > 0
                              ? '${acc.pending} records, ${acc.pendingRequests} requests'
                              : 'Tap to review and decide on filings',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.inkFaint),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentItem {
  _RecentItem({
    required this.type,
    required this.app,
    required this.no,
    required this.date,
    required this.detail,
    required this.status,
    required this.sortDate,
    required this.targetScreen,
  });

  final String type;
  final String app;
  final String no;
  final String date;
  final String detail;
  final String status;
  final DateTime sortDate;
  final Widget targetScreen;
}

Future<List<_RecentItem>> _loadRecent() async {
  final items = <_RecentItem>[];
  final isVersatech = AppSession.instance.tenant?.id == 'versatech';

  final futures = <Future>[
    HrisApi.instance.requestRecords('loa').then((rows) {
      for (final r in rows) {
        final d =
            r.appliedDate ?? parseAppDateTime(r.dateFrom) ?? DateTime(2000);
        items.add(_RecentItem(
          type: 'loa',
          app: 'LOA',
          no: r.no,
          date: r.txnDate.isNotEmpty ? r.txnDate : r.dateApplied,
          detail: r.leaveType ?? 'Leave of Absence',
          status: r.status,
          sortDate: d,
          targetScreen: const LeaveOfAbsenceScreen(),
        ));
      }
    }).catchError((_) {}),
    HrisApi.instance.requestRecords('call-approval').then((rows) {
      for (final r in rows) {
        final d =
            parseAppDateTime(r.txnDate) ?? r.appliedDate ?? DateTime(2000);
        items.add(_RecentItem(
          type: 'call-approval',
          app: 'CA',
          no: r.no,
          date: r.txnDate.isNotEmpty ? r.txnDate : r.dateApplied,
          detail: 'Call Approval',
          status: r.status,
          sortDate: d,
          targetScreen: const ApprovalListScreen(
            title: 'Call Approval',
            subtitle: 'File and track call approval requests.',
            icon: Icons.fact_check_rounded,
            txnDateLabel: 'CA date',
            type: 'call-approval',
          ),
        ));
      }
    }).catchError((_) {}),
    HrisApi.instance.requestRecords('manual-ad').then((rows) {
      for (final r in rows) {
        final d =
            parseAppDateTime(r.txnDate) ?? r.appliedDate ?? DateTime(2000);
        items.add(_RecentItem(
          type: 'manual-ad',
          app: 'MAD',
          no: r.no,
          date: r.txnDate.isNotEmpty ? r.txnDate : r.dateApplied,
          detail: 'Manual Arrival/Departure',
          status: r.status,
          sortDate: d,
          targetScreen: const ApprovalListScreen(
            title: 'Manual Arrival/Departure',
            subtitle: 'File and track manual time in/out requests.',
            icon: Icons.punch_clock_rounded,
            txnDateLabel: 'MAD date',
            showWitnessedBy: true,
            type: 'manual-ad',
          ),
        ));
      }
    }).catchError((_) {}),
    HrisApi.instance.requestRecords('overtime').then((rows) {
      for (final r in rows) {
        final d =
            parseAppDateTime(r.txnDate) ?? r.appliedDate ?? DateTime(2000);
        final hrs = r.appliedHours?.isNotEmpty == true
            ? '${r.appliedHours} hrs'
            : 'Overtime';
        items.add(_RecentItem(
          type: 'overtime',
          app: 'OT',
          no: r.no,
          date: r.txnDate.isNotEmpty ? r.txnDate : r.dateApplied,
          detail: hrs,
          status: r.status,
          sortDate: d,
          targetScreen: const ApprovalListScreen(
            title: 'Overtime',
            subtitle: 'File and track overtime requests.',
            icon: Icons.access_time_filled_rounded,
            txnDateLabel: 'Overtime date',
            showHours: true,
            type: 'overtime',
          ),
        ));
      }
    }).catchError((_) {}),
    if (isVersatech)
      HrisApi.instance.requestRecords('other').then((rows) {
        for (final r in rows) {
          final d = r.appliedDate ?? DateTime(2000);
          items.add(_RecentItem(
            type: 'other',
            app: r.requestType ?? 'REQ',
            no: r.no,
            date: r.dateApplied,
            detail: r.reason ?? 'Other Request',
            status: r.status,
            sortDate: d,
            targetScreen: const OtherRequestsScreen(),
          ));
        }
      }).catchError((_) {}),
  ];

  await Future.wait(futures);
  items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
  return items.take(3).toList();
}

Color _recentStatusColor(String status) {
  switch (status) {
    case 'For Approval':
    case 'For Witness Approval':
    case 'Pending':
      return AppColors.warning;
    case 'Approved':
      return AppColors.success;
    case 'Posted':
      return AppColors.info;
    case 'Active':
    case 'Saved':
      return AppColors.inkSoft;
    case 'Cancelled':
    case 'Void':
      return AppColors.inkFaint;
    case 'Rejected':
    case 'Disapproved':
    default:
      return AppColors.brandRed;
  }
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AsyncView<List<_RecentItem>>(
      load: _loadRecent,
      useGlobalLoader: false,
      builder: (context, items) {
        if (items.isEmpty) {
          return SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.assignment_outlined,
                  color: AppColors.inkSoft,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'No recent filings yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _RecentCard(item: items[i]),
              if (i != items.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.item});
  final _RecentItem item;

  Color get _badgeColor {
    switch (item.app) {
      case 'LOA':
        return AppColors.info;
      case 'OT':
        return AppColors.warning;
      case 'CA':
        return AppColors.success;
      case 'MAD':
        return AppColors.brandRed;
      default:
        return AppColors.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => item.targetScreen),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.app,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.no,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    StatusPill(
                      label: item.status,
                      color: _recentStatusColor(item.status),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.detail,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.date.isNotEmpty) ...[
                      const Text(
                        ' • ',
                        style:
                            TextStyle(color: AppColors.inkFaint, fontSize: 12),
                      ),
                      Text(
                        item.date,
                        style: const TextStyle(
                          color: AppColors.inkFaint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Leave balance with VL and SL as prominent hero tiles, loaded from the API.
class _LeaveBalance extends StatelessWidget {
  // Remaining paid leave as HH:MM (matches the web / Leave Hours screen).
  String _hhmm(String? v) => (v == null || v.isEmpty) ? '— —' : v;

  @override
  Widget build(BuildContext context) {
    return AsyncView<LeaveBalance>(
      load: () => HrisApi.instance.leaveHours(),
      useGlobalLoader: true,
      builder: (context, b) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _bigCredit(
                  context,
                  label: 'Vacation Leave',
                  short: 'VL',
                  val: _hhmm(b.vlPaid),
                  unit: '',
                  icon: Icons.beach_access_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigCredit(
                  context,
                  label: 'Sick Leave',
                  short: 'SL',
                  val: _hhmm(b.slPaid),
                  unit: '',
                  icon: Icons.healing_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigCredit(
    BuildContext context, {
    required String label,
    required String short,
    required String val,
    required IconData icon,
    String unit = 'days',
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
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandRed,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
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
