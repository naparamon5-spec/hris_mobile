import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'approval_list_screen.dart';
import 'leave_hours_screen.dart';
import 'leave_of_absence_screen.dart';
import 'payslip_screen.dart';
import 'timesheet_screen.dart';

/// RECORD / REQUEST hub — mirrors the same-named group in the HRIS web sidebar.
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'Record / Request',
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
                records: _callApprovalRecords,
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
                records: _manualAdRecords,
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
                records: _overtimeRecords,
              ),
            ),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.view_week_rounded,
            label: 'Timesheet',
            color: AppColors.inkSoft,
            onTap: () => _go(context, const TimesheetScreen()),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.receipt_long_rounded,
            label: 'Payslip',
            color: AppColors.inkSoft,
            badge: true,
            onTap: () => _go(context, const PayslipScreen()),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

// -----------------------------------------------------------------------------
// MOCK DATA — Call Approval, Manual Arrival/Departure, Overtime
// -----------------------------------------------------------------------------
const _callApprovalRecords = <ApprovalRecord>[
  ApprovalRecord('243647', 'September 03, 2026', 'September 03, 2026',
      'ARIEL SERRANO', 'September 03, 2026',
      year: 2026, month: 9, day: 3),
  ApprovalRecord('243470', 'August 27, 2026', 'August 27, 2026',
      'ARIEL SERRANO', 'August 27, 2026',
      year: 2026, month: 8, day: 27),
  ApprovalRecord('242917', 'August 20, 2026', 'August 20, 2026',
      'ARIEL SERRANO', 'August 20, 2026',
      year: 2026, month: 8, day: 20),
  ApprovalRecord('243489', 'August 27, 2026', 'August 19, 2026',
      'ARIEL SERRANO', 'September 01, 2026',
      year: 2026, month: 8, day: 19, status: 'Approved'),
  ApprovalRecord('242277', 'August 18, 2026', 'August 18, 2026',
      'ARIEL SERRANO', 'August 18, 2026',
      year: 2026, month: 8, day: 18),
  ApprovalRecord('242103', 'August 13, 2026', 'August 13, 2026',
      'ARIEL SERRANO', 'August 13, 2026',
      year: 2026, month: 8, day: 13),
  ApprovalRecord('241976', 'August 10, 2026', 'August 10, 2026',
      'ARIEL SERRANO', 'August 10, 2026',
      year: 2026, month: 8, day: 10),
  ApprovalRecord('241668', 'August 06, 2026', 'August 06, 2026',
      'ARIEL SERRANO', 'August 06, 2026',
      year: 2026, month: 8, day: 6),
];

// Manual Arrival/Departure uses a "Witnessed By" column instead of an
// approved date (approvedDate is left blank for these records).
const _manualAdRecords = <ApprovalRecord>[
  ApprovalRecord('MAD24512', 'September 02, 2026', 'September 02, 2026',
      'ARIEL SERRANO', '',
      year: 2026, month: 9, day: 2, witnessedBy: 'SOFIA REYES'),
  ApprovalRecord('MAD24488', 'August 28, 2026', 'August 26, 2026',
      'ARIEL SERRANO', '',
      year: 2026,
      month: 8,
      day: 26,
      status: 'Approved',
      witnessedBy: 'MARK DELA CRUZ'),
  ApprovalRecord('MAD24390', 'August 21, 2026', 'August 21, 2026',
      'ARIEL SERRANO', '',
      year: 2026, month: 8, day: 21, witnessedBy: 'SOFIA REYES'),
  ApprovalRecord('MAD24201', 'August 14, 2026', 'August 14, 2026',
      'ARIEL SERRANO', '',
      year: 2026, month: 8, day: 14, witnessedBy: 'JOHN SANTOS'),
  ApprovalRecord('MAD24098', 'August 07, 2026', 'August 07, 2026',
      'ARIEL SERRANO', '',
      year: 2026, month: 8, day: 7, witnessedBy: 'SOFIA REYES'),
];

// Overtime shows applied/approved hours in addition to the shared columns.
const _overtimeRecords = <ApprovalRecord>[
  ApprovalRecord('OT30217', 'September 04, 2026', 'September 04, 2026',
      'ARIEL SERRANO', 'September 04, 2026',
      year: 2026,
      month: 9,
      day: 4,
      appliedHours: '3.00',
      approvedHours: '3.00'),
  ApprovalRecord('OT30185', 'August 29, 2026', 'August 29, 2026',
      'ARIEL SERRANO', 'August 29, 2026',
      year: 2026,
      month: 8,
      day: 29,
      appliedHours: '2.00',
      approvedHours: '2.00'),
  ApprovalRecord('OT30142', 'August 25, 2026', 'August 22, 2026',
      'ARIEL SERRANO', 'August 26, 2026',
      year: 2026,
      month: 8,
      day: 22,
      status: 'Approved',
      appliedHours: '4.00',
      approvedHours: '3.50'),
  ApprovalRecord('OT30044', 'August 15, 2026', 'August 15, 2026',
      'ARIEL SERRANO', 'August 15, 2026',
      year: 2026,
      month: 8,
      day: 15,
      appliedHours: '1.50',
      approvedHours: '1.50'),
  ApprovalRecord('OT29981', 'August 08, 2026', 'August 08, 2026',
      'ARIEL SERRANO', 'August 08, 2026',
      year: 2026,
      month: 8,
      day: 8,
      appliedHours: '5.00',
      approvedHours: '5.00'),
];
