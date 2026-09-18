import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// One item awaiting a manager's decision (a team member's filing). Shared by
/// both the Records and Requests inboxes.
class ApprovalItem {
  ApprovalItem({
    required this.no,
    required this.employee,
    required this.role,
    required this.category,
    required this.detail,
    required this.dateFiled,
    this.approvedDate = '',
    this.decidedBy = '',
    this.status = 'For Approval',
  });

  final String no;
  final String employee;
  final String role;

  /// e.g. "Overtime", "Leave of Absence".
  final String category;

  /// Human summary (date range / hours) shown on the card.
  final String detail;
  final String dateFiled;

  String approvedDate;
  String decidedBy;

  /// 'For Approval' | 'Approved' | 'Rejected'.
  String status;
}

/// APPROVALS hub (exec / department head). Two modules: Records and Requests.
/// Each opens an inbox split into "For Approval" and "Approved" tabs.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  Widget build(BuildContext context) {
    final recordsPending =
        _records.where((r) => r.status == 'For Approval').length;
    final requestsPending =
        _requests.where((r) => r.status == 'For Approval').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Approvals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text(
              'Review and act on your team’s filings.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            _ModuleCard(
              icon: Icons.fact_check_rounded,
              title: 'Records',
              subtitle: 'Overtime, time in/out & call approvals',
              pending: recordsPending,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ApprovalInboxScreen(
                    title: 'Records',
                    icon: Icons.fact_check_rounded,
                    items: _records,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Requests',
              subtitle: 'Leave of absence & leave hours',
              pending: requestsPending,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ApprovalInboxScreen(
                    title: 'Requests',
                    icon: Icons.assignment_turned_in_rounded,
                    items: _requests,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-level Records / Requests card with a pending-count badge.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pending,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.brandRed, size: 48, iconSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brandRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pending',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}

/// Inbox for a single module — "For Approval" and "Approved" tabs over the same
/// list. Approving/rejecting moves an item from the first tab to the second.
class _ApprovalInboxScreen extends StatefulWidget {
  const _ApprovalInboxScreen({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<ApprovalItem> items;

  @override
  State<_ApprovalInboxScreen> createState() => _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends State<_ApprovalInboxScreen> {
  static const _me = 'Ramon Napa';

  List<ApprovalItem> get _pending =>
      widget.items.where((i) => i.status == 'For Approval').toList();
  List<ApprovalItem> get _decided =>
      widget.items.where((i) => i.status != 'For Approval').toList();

  void _decide(ApprovalItem item, bool approve) {
    setState(() {
      item.status = approve ? 'Approved' : 'Rejected';
      item.decidedBy = _me;
      item.approvedDate = 'September 11, 2026';
    });
    showToast(
      context,
      approve ? '${item.no} has been approved.' : '${item.no} has been rejected.',
      isSuccess: true,
      title: approve ? 'Approved' : 'Rejected',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(widget.title),
          bottom: TabBar(
            labelColor: AppColors.brandRed,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.brandRed,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            tabs: [
              Tab(text: 'For Approval (${_pending.length})'),
              Tab(text: 'Approved (${_decided.length})'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _list(_pending, pendingTab: true),
              _list(_decided, pendingTab: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<ApprovalItem> items, {required bool pendingTab}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.fieldFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                pendingTab
                    ? Icons.inbox_rounded
                    : Icons.check_circle_outline_rounded,
                size: 30,
                color: AppColors.inkFaint,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              pendingTab ? 'All caught up' : 'Nothing approved yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pendingTab
                  ? 'No filings are waiting for your approval.'
                  : 'Approved items will appear here.',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ApprovalItemCard(
        item: items[i],
        icon: widget.icon,
        onApprove: pendingTab ? () => _decide(items[i], true) : null,
        onReject: pendingTab ? () => _decide(items[i], false) : null,
      ),
    );
  }
}

class _ApprovalItemCard extends StatelessWidget {
  const _ApprovalItemCard({
    required this.item,
    required this.icon,
    this.onApprove,
    this.onReject,
  });

  final ApprovalItem item;
  final IconData icon;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color _statusColor() {
    switch (item.status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.brandRed;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = onApprove != null;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: item.employee, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.employee,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: item.status, color: _statusColor()),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.category} • ${item.detail}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _kv('Ref. no.', item.no)),
              Expanded(child: _kv('Date filed', item.dateFiled)),
            ],
          ),
          if (!pending && item.decidedBy.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _kv('Decided by', item.decidedBy)),
                Expanded(child: _kv('Decided on', item.approvedDate)),
              ],
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandRed,
                      side: BorderSide(color: AppColors.dangerSoft, width: 1.6),
                      backgroundColor: AppColors.dangerSoft,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.inkFaint,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// MOCK DATA — filings from the team awaiting the head/exec's decision.
// -----------------------------------------------------------------------------
final List<ApprovalItem> _records = [
  ApprovalItem(
    no: 'OT30302',
    employee: 'Daniel Cruz',
    role: 'Backend Developer',
    category: 'Overtime',
    detail: '3.00 hrs • Sep 09, 2026',
    dateFiled: 'September 09, 2026',
  ),
  ApprovalItem(
    no: 'MAD24560',
    employee: 'Noah Santos',
    role: 'IT Support Specialist',
    category: 'Manual Arrival/Departure',
    detail: 'Time in 08:05 • Sep 10, 2026',
    dateFiled: 'September 10, 2026',
  ),
  ApprovalItem(
    no: '243712',
    employee: 'Grace Lim',
    role: 'Talent Acquisition',
    category: 'Call Approval',
    detail: 'CA date • Sep 08, 2026',
    dateFiled: 'September 08, 2026',
  ),
  ApprovalItem(
    no: 'OT30188',
    employee: 'Bea Mendoza',
    role: 'Marketing Associate',
    category: 'Overtime',
    detail: '2.50 hrs • Aug 29, 2026',
    dateFiled: 'August 29, 2026',
    status: 'Approved',
    decidedBy: 'Ramon Napa',
    approvedDate: 'August 30, 2026',
  ),
];

final List<ApprovalItem> _requests = [
  ApprovalItem(
    no: 'LOA-2261',
    employee: 'Aisha Khan',
    role: 'Product Designer',
    category: 'Leave of Absence',
    detail: 'Vacation • Sep 14–15, 2026 (2 days)',
    dateFiled: 'September 05, 2026',
  ),
  ApprovalItem(
    no: 'LOA-2274',
    employee: 'Marco Villanueva',
    role: 'Finance Manager',
    category: 'Leave of Absence',
    detail: 'Sick • Sep 12, 2026 (1 day)',
    dateFiled: 'September 10, 2026',
  ),
  ApprovalItem(
    no: 'LH-4488',
    employee: 'Daniel Cruz',
    role: 'Backend Developer',
    category: 'Leave Hours',
    detail: '4.00 hrs • Sep 11, 2026',
    dateFiled: 'September 09, 2026',
  ),
  ApprovalItem(
    no: 'LOA-2205',
    employee: 'Sofia Reyes',
    role: 'People Operations Lead',
    category: 'Leave of Absence',
    detail: 'Vacation • Aug 26–27, 2026 (2 days)',
    dateFiled: 'August 20, 2026',
    status: 'Approved',
    decidedBy: 'Ramon Napa',
    approvedDate: 'August 21, 2026',
  ),
];
