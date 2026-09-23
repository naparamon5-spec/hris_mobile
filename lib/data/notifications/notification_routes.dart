import 'package:flutter/material.dart';

import '../../screens/approval_list_screen.dart';
import '../../screens/approvals_center_screen.dart';
import '../../screens/leave_of_absence_screen.dart';
import '../../screens/other_requests_screen.dart';
import '../../screens/payslip_screen.dart';
import '../../screens/timesheet_screen.dart';
import '../../screens/whos_out_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ui.dart';
import '../mock_data.dart';

/// Infers the kind of notification when backend or mock data omits it.
String inferKind(String? kind, String title, String body) {
  final k = (kind ?? '').trim().toLowerCase();
  if (k.isNotEmpty) return k;

  final text = '$title $body'.toLowerCase();
  if (text.contains('for your approval') ||
      text.contains('for approval') ||
      text.contains('pending approval')) {
    return 'pending_approval';
  }
  if (text.contains('approved') ||
      text.contains('disapproved') ||
      text.contains('rejected') ||
      text.contains('cancelled') ||
      text.contains('reopened')) {
    return 'decision';
  }
  if (text.contains('payslip') || text.contains('payday') || text.contains('salary')) {
    return 'payslip';
  }
  if (text.contains('timesheet') ||
      text.contains('clock out') ||
      text.contains('clock in') ||
      text.contains('checked in')) {
    return 'timesheet';
  }
  if (text.contains("who's out") || text.contains('whos out')) {
    return 'whos_out';
  }
  return '';
}

/// Infers the request type ('loa' | 'call-approval' | 'manual-ad' | 'overtime' | 'other').
String inferRequestType(String? requestType, String title, String body) {
  final raw = (requestType ?? '').trim().toLowerCase();
  if (raw == 'call-approval' || raw == 'call approval' || raw == 'ca') {
    return 'call-approval';
  }
  if (raw == 'manual-ad' || raw == 'manual arrival' || raw == 'mad') {
    return 'manual-ad';
  }
  if (raw == 'overtime' || raw == 'ot') return 'overtime';
  if (raw == 'loa' || raw == 'leave') return 'loa';
  if (raw == 'other' || raw == 'request') return 'other';
  if (raw.isNotEmpty) return raw;

  final text = '$title $body'.toLowerCase();
  if (text.contains('leave') || text.contains('loa')) return 'loa';
  if (text.contains('call approval') || text.contains('ca date') || RegExp(r'\bca\b').hasMatch(text)) {
    return 'call-approval';
  }
  if (text.contains('manual arrival') ||
      text.contains('arrival/departure') ||
      text.contains('manual time') ||
      text.contains('mad date') ||
      RegExp(r'\bmad\b').hasMatch(text)) {
    return 'manual-ad';
  }
  if (text.contains('overtime') || text.contains('overtime date') || RegExp(r'\bot\b').hasMatch(text)) {
    return 'overtime';
  }
  if (text.contains('other request') ||
      text.contains('certificate of employment') ||
      text.contains('coe') ||
      text.contains('itr') ||
      text.contains('epp') ||
      text.contains('bup')) {
    return 'other';
  }
  return '';
}

/// Extracts a request reference/number if not explicitly provided in requestId.
String inferRequestNo(String? explicitId, String title, String body) {
  final direct = (explicitId ?? '').trim();
  if (direct.isNotEmpty && !direct.startsWith('{')) return direct;

  final text = '$title $body';
  final match = RegExp(r'\(([A-Za-z0-9\-]+)\)|#([A-Za-z0-9\-]+)|\b(H\d+)\b').firstMatch(text);
  if (match != null) {
    return match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
  }
  return '';
}

/// Destination screen for a notification tap (inbox card or FCM payload).
Widget? screenForNotification({
  String? kind,
  String? requestType,
  String? requestId,
  String? requestNo,
  String title = '',
  String body = '',
}) {
  final resolvedKind = inferKind(kind, title, body);
  final resolvedType = inferRequestType(requestType, title, body);
  final resolvedNo = inferRequestNo(requestId, title, body);
  final targetId = (requestId ?? '').trim().isNotEmpty ? requestId!.trim() : resolvedNo;

  if (resolvedKind == 'pending_approval' || resolvedKind == 'for_approval') {
    return ApprovalsCenterScreen(
      module: resolvedType == 'other' ? 'requests' : 'records',
      scope: 'pending',
      initialTaskId: targetId,
      initialRecordId: targetId,
    );
  }

  if (resolvedKind == 'payslip' || resolvedKind == 'payday') {
    return const PayslipScreen();
  }

  if (resolvedKind == 'timesheet') {
    return const TimesheetScreen();
  }

  if (resolvedKind == 'whos_out') {
    return const WhosOutScreen();
  }

  switch (resolvedType) {
    case 'loa':
      return LeaveOfAbsenceScreen(
        initialRecordId: targetId,
        initialRecordNo: resolvedNo,
      );
    case 'call-approval':
      return ApprovalListScreen(
        title: 'Call Approval',
        subtitle: 'File and track call approval requests.',
        icon: Icons.fact_check_rounded,
        txnDateLabel: 'CA date',
        type: 'call-approval',
        initialRecordId: targetId,
        initialRecordNo: resolvedNo,
      );
    case 'manual-ad':
      return ApprovalListScreen(
        title: 'Manual Arrival/Departure',
        subtitle: 'File and track manual time in/out requests.',
        icon: Icons.punch_clock_rounded,
        txnDateLabel: 'MAD date',
        showWitnessedBy: true,
        type: 'manual-ad',
        initialRecordId: targetId,
        initialRecordNo: resolvedNo,
      );
    case 'overtime':
      return ApprovalListScreen(
        title: 'Overtime',
        subtitle: 'File and track overtime requests.',
        icon: Icons.access_time_filled_rounded,
        txnDateLabel: 'Overtime date',
        showHours: true,
        type: 'overtime',
        initialRecordId: targetId,
        initialRecordNo: resolvedNo,
      );
    case 'other':
      return OtherRequestsScreen(
        initialRecordId: targetId,
        initialRecordNo: resolvedNo,
      );
    default:
      return null;
  }
}

/// Opens the notification target screen if one is resolved; otherwise
/// opens a bottom sheet with full details of the notification.
void openNotification(BuildContext context, AppNotification item) {
  final screen = screenForNotification(
    kind: item.kind,
    requestType: item.requestType,
    requestId: item.requestId,
    title: item.title,
    body: item.body,
  );

  if (screen != null) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    return;
  }

  // Fallback: informational notifications (announcements, policies, welcome notices).
  showNotificationDetailSheet(context, item);
}

/// Shows a bottom sheet with complete details for general/informational notifications.
void showNotificationDetailSheet(BuildContext context, AppNotification item) {
  showPremiumBottomSheet(
    context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              IconBadge(
                icon: item.icon,
                color: item.color,
                size: 46,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              item.body,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
