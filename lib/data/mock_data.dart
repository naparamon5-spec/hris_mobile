import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UI models for the HRIS app. Each has a `fromJson` factory that maps the
/// backend response (see hris-server `data/seed.js`) into the shape the screens
/// render.

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
    case 'assignment':
      return Icons.assignment_turned_in_rounded;
    case 'cancel':
      return Icons.cancel_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'people':
      return Icons.emoji_people_rounded;
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

/// Display sequence of a deduction, matching the HRIS website's payslip: loans,
/// NHIP (PhilHealth), provident fund, HDMF (Pag-IBIG), SSS, withholding tax, then
/// anything else. Loans are checked first so "SSS Loan" stays with the loans
/// rather than the SSS premium.
int deductionRank(String label) {
  final l = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  if (RegExp(r'\bloans?\b').hasMatch(l)) return 0;
  if (RegExp(r'\bnhip\b|phil ?health|\bphic\b').hasMatch(l)) return 1;
  // "PRVIDENT" is how the payroll data spells it on the website.
  if (RegExp(r'\bpro?vident\b').hasMatch(l)) return 2;
  if (RegExp(r'\bhdmf\b|pag ?ibig').hasMatch(l)) return 3;
  if (RegExp(r'\bsss\b').hasMatch(l)) return 4;
  if (RegExp(r'\bw?tax\b').hasMatch(l)) return 5;
  return 6;
}

/// [items] in the fixed deduction sequence; items of equal rank keep the order
/// the server sent them in.
List<PayItem> sortDeductions(List<PayItem> items) {
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final byRank = deductionRank(a.$2.label) - deductionRank(b.$2.label);
      return byRank != 0 ? byRank : a.$1 - b.$1;
    });
  return [for (final e in indexed) e.$2];
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
      deductionItems: sortDeductions(items(j['deduction_items'])),
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
    this.kind = '',
    this.requestType = '',
    this.requestId = '',
  });

  final int? id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool unread;
  final String kind;
  final String requestType;
  final String requestId;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt(),
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        time: (j['time'] ?? '') as String,
        icon: iconFromToken(j['icon'] as String?),
        color: AppColors.defaultBrand,
        unread: (j['unread'] ?? false) as bool,
        kind: (j['kind'] ?? j['type'] ?? '') as String,
        requestType: (j['request_type'] ?? '') as String,
        requestId: '${j['request_id'] ?? j['id'] ?? ''}',
      );

  AppNotification copyWith({bool? unread}) => AppNotification(
        id: id,
        title: title,
        body: body,
        time: time,
        icon: icon,
        color: color,
        unread: unread ?? this.unread,
        kind: kind,
        requestType: requestType,
        requestId: requestId,
      );
}
