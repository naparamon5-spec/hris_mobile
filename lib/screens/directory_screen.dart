import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _query = '';
  final _depts = const ['All', 'Engineering', 'Human Resources', 'Finance'];
  int _dept = 0;

  List<Employee> get _filtered {
    return kEmployees.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.toLowerCase().contains(_query.toLowerCase()) ||
          e.role.toLowerCase().contains(_query.toLowerCase());
      final matchesDept = _dept == 0 || e.department == _depts[_dept];
      return matchesQuery && matchesDept;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Directory'),
        actions: [
          IconButton(
              onPressed: () => showToast(context, 'View org chart'),
              icon: const Icon(Icons.account_tree_rounded)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search people or roles',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _depts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final sel = i == _dept;
                  return GestureDetector(
                    onTap: () => setState(() => _dept = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.ink : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(_depts[i],
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color:
                                  sel ? Colors.white : AppColors.inkSoft)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${_filtered.length} team members',
                  style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                itemCount: _filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _EmployeeCard(employee: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});
  final Employee employee;

  Color get _statusColor {
    switch (employee.status) {
      case 'Remote':
        return AppColors.info;
      case 'On leave':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _openProfile(context),
      child: Row(
        children: [
          InitialsAvatar(
              name: employee.name, size: 48, color: employee.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Text('${employee.role} · ${employee.department}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: employee.status, color: _statusColor),
          IconButton(
            onPressed: () => showToast(context, 'Calling ${employee.name}…'),
            icon: const Icon(Icons.phone_rounded,
                color: AppColors.inkSoft, size: 20),
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EmployeeSheet(employee: employee, color: _statusColor),
    );
  }
}

class _EmployeeSheet extends StatelessWidget {
  const _EmployeeSheet({required this.employee, required this.color});
  final Employee employee;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 22),
          InitialsAvatar(name: employee.name, size: 84, color: employee.color),
          const SizedBox(height: 14),
          Text(employee.name,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(employee.role,
              style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          StatusPill(label: employee.department, color: color),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _action(context, Icons.chat_bubble_rounded, 'Message')),
              const SizedBox(width: 12),
              Expanded(child: _action(context, Icons.phone_rounded, 'Call')),
              const SizedBox(width: 12),
              Expanded(child: _action(context, Icons.mail_rounded, 'Email')),
            ],
          ),
          const SizedBox(height: 20),
          SoftCard(
            child: Column(
              children: [
                _info(Icons.badge_rounded, 'Employee ID', 'ANI-2041'),
                const Divider(height: 22),
                _info(Icons.location_on_rounded, 'Location', 'Makati HQ'),
                const Divider(height: 22),
                _info(Icons.supervisor_account_rounded, 'Reports to',
                    'Sofia Reyes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        showToast(context, '$label ${employee.name}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brandRed, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkSoft),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13.5,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ],
    );
  }
}
