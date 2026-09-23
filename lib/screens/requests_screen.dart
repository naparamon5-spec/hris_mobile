import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/hris_api.dart';
import '../data/inbox_badges.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'approval_list_screen.dart';
import 'approvals_center_screen.dart';
import 'leave_hours_screen.dart';
import 'leave_of_absence_screen.dart';
import 'other_requests_screen.dart';
import 'payslip_screen.dart';
import 'timesheet_screen.dart';

/// RECORD / REQUEST hub — mirrors the same-named group in the HRIS web sidebar.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  // A key that changes each time we return from an approvals screen forces the
  // FutureBuilder to re-fetch the pending counts (real-time counter).
  Key _accessKey = UniqueKey();
  void _refreshAccess() => setState(() => _accessKey = UniqueKey());

  Future<void> _handleRefresh() async {
    await InboxBadges.instance.refresh();
    if (mounted) _refreshAccess();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: InboxBadges.instance,
        builder: (context, _) => RefreshIndicator(
          color: AppColors.brandRed,
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
          const Text(
            'File Request',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Log time and file requests for approval.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
          ),
          const SizedBox(height: 22),
          const SmallCapsHeader('Record / Request'),
          NavListTile(
            icon: Icons.more_time_rounded,
            label: 'Leave Hours',
            color: AppColors.inkSoft,
            onTap: () => _go(context, const LeaveHoursScreen()),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.event_busy_rounded,
            label: 'Leave of Absence',
            color: AppColors.inkSoft,
            onTap: () => _go(context, const LeaveOfAbsenceScreen()),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.fact_check_rounded,
            label: 'Call Approval',
            color: AppColors.inkSoft,
            onTap: () => _go(
              context,
              ApprovalListScreen(
                title: 'Call Approval',
                subtitle: 'File and track call approval requests.',
                icon: Icons.fact_check_rounded,
                txnDateLabel: 'CA date',
                type: 'call-approval',
              ),
            ),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.punch_clock_rounded,
            label: 'Manual Arrival/Departure',
            color: AppColors.inkSoft,
            onTap: () => _go(
              context,
              ApprovalListScreen(
                title: 'Manual Arrival/Departure',
                subtitle: 'File and track manual time in/out requests.',
                icon: Icons.punch_clock_rounded,
                txnDateLabel: 'MAD date',
                showWitnessedBy: true,
                type: 'manual-ad',
              ),
            ),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.access_time_filled_rounded,
            label: 'Overtime',
            color: AppColors.inkSoft,
            onTap: () => _go(
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
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.view_week_rounded,
            label: 'Timesheet',
            color: AppColors.inkSoft,
            badge: InboxBadges.instance.timesheetNew,
            onTap: () {
              InboxBadges.instance.consumeKinds(InboxBadges.timesheetKinds);
              _go(context, const TimesheetScreen());
            },
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.receipt_long_rounded,
            label: 'Payslip',
            color: AppColors.inkSoft,
            badge: InboxBadges.instance.payslipNew,
            onTap: () {
              InboxBadges.instance.consumeKinds(InboxBadges.payslipKinds);
              _go(context, const PayslipScreen());
            },
          ),
          // ---- Versatech only: additional request types ----
          if (AppSession.instance.tenant?.id == 'versatech') ...[
            const SizedBox(height: 10),
            NavListTile(
              icon: Icons.post_add_rounded,
              label: 'Other Requests',
              color: AppColors.inkSoft,
              onTap: () => _go(context, const OtherRequestsScreen()),
            ),
          ],
          // ---- Approvers only — shown when the signed-in user is a department
          // approver in vw_emp_list_with_approver (real data, not just role). ----
          FutureBuilder<ApprovalAccess>(
            key: _accessKey,
            future: HrisApi.instance.approvalAccess(),
            builder: (context, snap) {
              final acc = snap.data;
              if (acc == null || !acc.isApprover) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  const SmallCapsHeader('Approvals'),
                  NavListTile(
                    icon: Icons.verified_user_rounded,
                    label: acc.pending > 0
                        ? 'Records Approval (${acc.pending})'
                        : 'Records Approval',
                    color: AppColors.inkSoft,
                    badge: acc.pending > 0,
                    onTap: () async {
                      await _go(
                        context,
                        const ApprovalsCenterScreen(
                          module: 'records',
                          scope: 'pending',
                        ),
                      );
                      _refreshAccess();
                    },
                  ),
                  const SizedBox(height: 10),
                  NavListTile(
                    icon: Icons.task_alt_rounded,
                    label: 'Approved Records',
                    color: AppColors.inkSoft,
                    onTap: () async {
                      await _go(
                        context,
                        const ApprovalsCenterScreen(
                          module: 'records',
                          scope: 'history',
                        ),
                      );
                      _refreshAccess();
                    },
                  ),
                  // Request Approval covers the Other Requests (COE/EPP/ITR/
                  // COL/BUP/ID from th_request_head). Shown to every approver;
                  // if the tenant has no such requests, the list is simply
                  // empty and the badge stays clear.
                  const SizedBox(height: 10),
                  NavListTile(
                    icon: Icons.assignment_turned_in_rounded,
                    label: acc.pendingRequests > 0
                        ? 'Request Approval (${acc.pendingRequests})'
                        : 'Request Approval',
                    color: AppColors.inkSoft,
                    badge: acc.pendingRequests > 0,
                    onTap: () async {
                      await _go(
                        context,
                        const ApprovalsCenterScreen(
                          module: 'requests',
                          scope: 'pending',
                        ),
                      );
                      _refreshAccess();
                    },
                  ),
                  const SizedBox(height: 10),
                  NavListTile(
                    icon: Icons.fact_check_outlined,
                    label: 'Approved Requests',
                    color: AppColors.inkSoft,
                    onTap: () async {
                      await _go(
                        context,
                        const ApprovalsCenterScreen(
                          module: 'requests',
                          scope: 'history',
                        ),
                      );
                      _refreshAccess();
                    },
                  ),
                ],
              );
            },
          ),
        ],
          ),
        ),
      ),
    );
  }

  Future<void> _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
