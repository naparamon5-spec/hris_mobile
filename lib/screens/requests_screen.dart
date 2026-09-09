import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'feature_screen.dart';
import 'leave_hours_screen.dart';
import 'leave_of_absence_screen.dart';
import 'payroll_screen.dart';

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
            color: AppColors.brandRed,
            onTap: () => _go(context, const LeaveHoursScreen()),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.event_busy_rounded,
            label: 'Leave of Absence',
            color: AppColors.brandMaroon,
            onTap: () => _go(context, const LeaveOfAbsenceScreen()),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.fact_check_rounded,
            label: 'Call Approval',
            color: AppColors.info,
            onTap: () => _feature(context, 'Call Approval',
                Icons.fact_check_rounded, AppColors.info),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.punch_clock_rounded,
            label: 'Manual Arrival/Departure',
            color: AppColors.success,
            onTap: () => _feature(context, 'Manual Arrival/Departure',
                Icons.punch_clock_rounded, AppColors.success),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.access_time_filled_rounded,
            label: 'Overtime',
            color: AppColors.warning,
            onTap: () => _feature(context, 'Overtime',
                Icons.access_time_filled_rounded, AppColors.warning),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.view_week_rounded,
            label: 'Timesheet',
            color: AppColors.info,
            onTap: () => _feature(
                context, 'Timesheet', Icons.view_week_rounded, AppColors.info),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.receipt_long_rounded,
            label: 'Payslip',
            color: AppColors.brandRed,
            badge: true,
            onTap: () => _go(context, const PayrollScreen()),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _feature(
          BuildContext context, String title, IconData icon, Color color) =>
      _go(context, FeatureScreen(title: title, icon: icon, color: color));
}
