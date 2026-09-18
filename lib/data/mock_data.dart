import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UI models for the HRIS app. Each has a `fromJson` factory that maps the
/// backend response (see hris-server `data/seed.js`) into the shape the screens
/// render. The `k*` demo lists below are kept only as offline fallbacks.

/// Maps a backend icon token (e.g. "beach_access") to a Material icon.
IconData iconFromToken(String? token) {
  switch (token) {
    case 'beach_access':
      return Icons.beach_access_rounded;
    case 'healing':
      return Icons.healing_rounded;
    case 'home_work':
      return Icons.home_work_rounded;
    case 'emergency':
      return Icons.emergency_rounded;
    case 'check_circle':
      return Icons.check_circle_rounded;
    case 'receipt_long':
      return Icons.receipt_long_rounded;
    case 'schedule':
      return Icons.schedule_rounded;
    case 'campaign':
      return Icons.campaign_rounded;
    case 'celebration':
      return Icons.celebration_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

/// Maps a request status ("Approved" / "Pending" / "Rejected") to its color.
Color statusColorFor(String? status) {
  switch (status) {
    case 'Approved':
      return AppColors.success;
    case 'Pending':
      return AppColors.warning;
    case 'Rejected':
      return AppColors.defaultBrand;
    default:
      return AppColors.inkSoft;
  }
}

class Employee {
  const Employee({
    this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.status,
    this.color = AppColors.defaultBrand,
  });

  final String? id;
  final String name;
  final String role;
  final String department;
  final String status; // Active / Remote / On leave
  final Color color;

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'] as String?,
        name: (j['name'] ?? '') as String,
        role: (j['role'] ?? '') as String,
        department: (j['department'] ?? '') as String,
        status: (j['status'] ?? 'Active') as String,
      );
}

class LeaveRequest {
  const LeaveRequest({
    this.id,
    required this.type,
    required this.range,
    required this.days,
    required this.status, // Approved / Pending / Rejected
    required this.statusColor,
    required this.icon,
    this.reason = '',
  });

  final int? id;
  final String type;
  final String range;
  final String days;
  final String status;
  final Color statusColor;
  final IconData icon;
  final String reason;

  factory LeaveRequest.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? 'Pending') as String;
    return LeaveRequest(
      id: j['id'] as int?,
      type: (j['type'] ?? '') as String,
      range: (j['range'] ?? '') as String,
      days: (j['days'] ?? '') as String,
      status: status,
      statusColor: statusColorFor(status),
      icon: iconFromToken(j['icon'] as String?),
      reason: (j['reason'] ?? '') as String,
    );
  }
}

/// One labelled amount on a payslip breakdown (earning or deduction).
class PayItem {
  const PayItem({required this.label, required this.amount});
  final String label;
  final String amount;

  factory PayItem.fromJson(Map<String, dynamic> j) => PayItem(
        label: (j['label'] ?? '') as String,
        amount: (j['amount'] ?? '') as String,
      );
}

class Payslip {
  const Payslip({
    this.id,
    required this.period,
    required this.net,
    required this.status,
    this.gross,
    this.deductions,
    this.payDate,
    this.earnings = const [],
    this.deductionItems = const [],
  });

  final String? id;
  final String period;
  final String net;
  final String status;
  final String? gross;
  final String? deductions;
  final String? payDate;
  final List<PayItem> earnings;
  final List<PayItem> deductionItems;

  factory Payslip.fromJson(Map<String, dynamic> j) {
    List<PayItem> items(dynamic v) => ((v as List?) ?? [])
        .map((e) => PayItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return Payslip(
      id: j['id'] as String?,
      period: (j['period'] ?? '') as String,
      net: (j['net'] ?? '') as String,
      status: (j['status'] ?? '') as String,
      gross: j['gross'] as String?,
      deductions: j['deductions'] as String?,
      payDate: j['pay_date'] as String?,
      earnings: items(j['earnings']),
      deductionItems: items(j['deduction_items']),
    );
  }
}

/// One day on a timesheet (DTR) period.
class TimesheetDay {
  const TimesheetDay({
    required this.date,
    required this.dayType,
    required this.timeIn,
    required this.timeOut,
    required this.basicHrs,
    required this.basicNdHrs,
    required this.otHrs,
    required this.ndOtHrs,
    required this.leaveHrs,
    required this.totalHrs,
    required this.remarks,
  });

  final String date;
  final String dayType;
  final String timeIn;
  final String timeOut;
  final double basicHrs;
  final double basicNdHrs;
  final double otHrs;
  final double ndOtHrs;
  final double leaveHrs;
  final double totalHrs;
  final String remarks;

  factory TimesheetDay.fromJson(Map<String, dynamic> j) => TimesheetDay(
        date: (j['date'] ?? '') as String,
        dayType: (j['day_type'] ?? '') as String,
        timeIn: (j['time_in'] ?? '') as String,
        timeOut: (j['time_out'] ?? '') as String,
        basicHrs: (j['basic_hrs'] as num?)?.toDouble() ?? 0,
        basicNdHrs: (j['basic_nd_hrs'] as num?)?.toDouble() ?? 0,
        otHrs: (j['ot_hrs'] as num?)?.toDouble() ?? 0,
        ndOtHrs: (j['nd_ot_hrs'] as num?)?.toDouble() ?? 0,
        leaveHrs: (j['leave_hrs'] as num?)?.toDouble() ?? 0,
        totalHrs: (j['total_hrs'] as num?)?.toDouble() ?? 0,
        remarks: (j['remarks'] ?? '') as String,
      );
}

class TimesheetDetail {
  const TimesheetDetail({
    required this.days,
    required this.basicTotal,
    required this.basicNdTotal,
    required this.otTotal,
    required this.ndOtTotal,
    required this.leaveTotal,
    required this.grandTotal,
  });

  final List<TimesheetDay> days;
  final double basicTotal;
  final double basicNdTotal;
  final double otTotal;
  final double ndOtTotal;
  final double leaveTotal;
  final double grandTotal;

  factory TimesheetDetail.fromJson(Map<String, dynamic> j) {
    final t = (j['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    return TimesheetDetail(
      days: ((j['data'] as List?) ?? [])
          .map((e) => TimesheetDay.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      basicTotal: (t['basic'] as num?)?.toDouble() ?? 0,
      basicNdTotal: (t['basic_nd'] as num?)?.toDouble() ?? 0,
      otTotal: (t['ot'] as num?)?.toDouble() ?? 0,
      ndOtTotal: (t['nd_ot'] as num?)?.toDouble() ?? 0,
      leaveTotal: (t['leave'] as num?)?.toDouble() ?? 0,
      grandTotal: (t['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AppNotification {
  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.unread = false,
  });

  final int? id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool unread;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int?,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        time: (j['time'] ?? '') as String,
        icon: iconFromToken(j['icon'] as String?),
        color: AppColors.defaultBrand,
        unread: (j['unread'] ?? false) as bool,
      );

  AppNotification copyWith({bool? unread}) => AppNotification(
        id: id,
        title: title,
        body: body,
        time: time,
        icon: icon,
        color: color,
        unread: unread ?? this.unread,
      );
}

const String kCurrentUser = 'Ramon Napa ( Mon)';
const String kCurrentRole = 'PROGRAMMER';

const List<Employee> kEmployees = [
  Employee(
      name: 'Ramon Napa ( Mon)',
      role: 'PROGRAMMER',
      department: 'Information Technology',
      status: 'Active'),
  Employee(
      name: 'Sofia Reyes',
      role: 'People Operations Lead',
      department: 'Human Resources',
      status: 'Active'),
  Employee(
      name: 'Marco Villanueva',
      role: 'Finance Manager',
      department: 'Finance',
      status: 'Remote'),
  Employee(
      name: 'Aisha Khan',
      role: 'Product Designer',
      department: 'Design',
      status: 'On leave'),
  Employee(
      name: 'Daniel Cruz',
      role: 'Backend Developer',
      department: 'Engineering',
      status: 'Active'),
  Employee(
      name: 'Grace Lim',
      role: 'Talent Acquisition',
      department: 'Human Resources',
      status: 'Remote'),
  Employee(
      name: 'Noah Santos',
      role: 'IT Support Specialist',
      department: 'IT',
      status: 'Active'),
  Employee(
      name: 'Bea Mendoza',
      role: 'Marketing Associate',
      department: 'Marketing',
      status: 'Active'),
];

const List<LeaveRequest> kLeaveRequests = [
  LeaveRequest(
      type: 'Annual Leave',
      range: 'Jun 23 – Jun 27, 2026',
      days: '5 days',
      status: 'Approved',
      statusColor: AppColors.success,
      icon: Icons.beach_access_rounded),
  LeaveRequest(
      type: 'Sick Leave',
      range: 'May 14, 2026',
      days: '1 day',
      status: 'Approved',
      statusColor: AppColors.success,
      icon: Icons.healing_rounded),
  LeaveRequest(
      type: 'Work From Home',
      range: 'Jun 30, 2026',
      days: '1 day',
      status: 'Pending',
      statusColor: AppColors.warning,
      icon: Icons.home_work_rounded),
  LeaveRequest(
      type: 'Emergency Leave',
      range: 'Apr 02, 2026',
      days: '1 day',
      status: 'Rejected',
      statusColor: AppColors.defaultBrand,
      icon: Icons.emergency_rounded),
];

const List<Payslip> kPayslips = [
  Payslip(period: 'May 2026', net: '₱ 86,420.00', status: 'Paid'),
  Payslip(period: 'April 2026', net: '₱ 84,950.00', status: 'Paid'),
  Payslip(period: 'March 2026', net: '₱ 85,210.00', status: 'Paid'),
  Payslip(period: 'February 2026', net: '₱ 83,700.00', status: 'Paid'),
];

const List<AppNotification> kNotifications = [
  AppNotification(
      title: 'Leave approved',
      body: 'Your annual leave (Jun 23–27) was approved by Sofia Reyes.',
      time: '2h ago',
      icon: Icons.check_circle_rounded,
      color: AppColors.defaultBrand,
      unread: true),
  AppNotification(
      title: 'Payslip available',
      body: 'Your May 2026 payslip is now ready to view.',
      time: '5h ago',
      icon: Icons.receipt_long_rounded,
      color: AppColors.defaultBrand,
      unread: true),
  AppNotification(
      title: 'Timesheet reminder',
      body: 'Don\'t forget to clock out — you\'re still checked in.',
      time: 'Yesterday',
      icon: Icons.schedule_rounded,
      color: AppColors.defaultBrand),
  AppNotification(
      title: 'New policy update',
      body: 'The 2026 remote work policy has been published.',
      time: '2 days ago',
      icon: Icons.campaign_rounded,
      color: AppColors.defaultBrand),
  AppNotification(
      title: 'Welcome aboard',
      body: 'Bea Mendoza has joined the Marketing team.',
      time: '3 days ago',
      icon: Icons.celebration_rounded,
      color: AppColors.defaultBrand),
];
