import 'package:flutter/material.dart';

import '../../screens/approval_list_screen.dart';
import '../../screens/approvals_center_screen.dart';
import '../../screens/leave_of_absence_screen.dart';
import '../../screens/other_requests_screen.dart';
import '../../screens/payslip_screen.dart';
import '../../screens/timesheet_screen.dart';
import '../../screens/whos_out_screen.dart';
import '../mock_data.dart';

/// Destination for a notification tap (inbox card or FCM payload).
Widget? screenForNotification({
  String? kind,
  String? requestType,
}) {
  final k = (kind ?? '').trim();
  final type = (requestType ?? '').trim();
  if (k == 'pending_approval' || k == 'for_approval') {
    return ApprovalsCenterScreen(
      module: type == 'other' ? 'requests' : 'records',
      scope: 'pending',
    );
  }
  if (k == 'payslip' || k == 'payday') return const PayslipScreen();
  if (k == 'timesheet') return const TimesheetScreen();
  if (k == 'whos_out') return const WhosOutScreen();
  switch (type) {
    case 'loa':
      return const LeaveOfAbsenceScreen();
    case 'call-approval':
      return ApprovalListScreen(
        title: 'Call Approval',
        subtitle: 'File and track call approval requests.',
        icon: Icons.fact_check_rounded,
        txnDateLabel: 'CA date',
        type: 'call-approval',
      );
    case 'manual-ad':
      return ApprovalListScreen(
        title: 'Manual Arrival/Departure',
        subtitle: 'File and track manual time in/out requests.',
        icon: Icons.punch_clock_rounded,
        txnDateLabel: 'MAD date',
        showWitnessedBy: true,
        type: 'manual-ad',
      );
    case 'overtime':
      return ApprovalListScreen(
        title: 'Overtime',
        subtitle: 'File and track overtime requests.',
        icon: Icons.access_time_filled_rounded,
        txnDateLabel: 'Overtime date',
        showHours: true,
        type: 'overtime',
      );
    case 'other':
      return const OtherRequestsScreen();
    default:
      return null;
  }
}

void openNotification(BuildContext context, AppNotification item) {
  final screen = screenForNotification(
    kind: item.kind,
    requestType: item.requestType,
  );
  if (screen == null) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
