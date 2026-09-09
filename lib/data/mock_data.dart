import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lightweight, immutable demo data so every screen renders realistic,
/// consistent content without a backend.

class Employee {
  const Employee({
    required this.name,
    required this.role,
    required this.department,
    required this.status,
    this.color = AppColors.brandRed,
  });

  final String name;
  final String role;
  final String department;
  final String status; // Active / Remote / On leave
  final Color color;
}

class LeaveRequest {
  const LeaveRequest({
    required this.type,
    required this.range,
    required this.days,
    required this.status, // Approved / Pending / Rejected
    required this.statusColor,
    required this.icon,
  });

  final String type;
  final String range;
  final String days;
  final String status;
  final Color statusColor;
  final IconData icon;
}

class Payslip {
  const Payslip({
    required this.period,
    required this.net,
    required this.status,
  });

  final String period;
  final String net;
  final String status;
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.unread = false,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final bool unread;
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
      statusColor: AppColors.brandRed,
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
      color: AppColors.brandRed,
      unread: true),
  AppNotification(
      title: 'Payslip available',
      body: 'Your May 2026 payslip is now ready to view.',
      time: '5h ago',
      icon: Icons.receipt_long_rounded,
      color: AppColors.brandRed,
      unread: true),
  AppNotification(
      title: 'Timesheet reminder',
      body: 'Don\'t forget to clock out — you\'re still checked in.',
      time: 'Yesterday',
      icon: Icons.schedule_rounded,
      color: AppColors.brandRed),
  AppNotification(
      title: 'New policy update',
      body: 'The 2026 remote work policy has been published.',
      time: '2 days ago',
      icon: Icons.campaign_rounded,
      color: AppColors.brandRed),
  AppNotification(
      title: 'Welcome aboard',
      body: 'Bea Mendoza has joined the Marketing team.',
      time: '3 days ago',
      icon: Icons.celebration_rounded,
      color: AppColors.brandRed),
];
