import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'create_leave_of_absence_screen.dart';

/// Leave of Absence — the LOA records list from the HRIS web app, rebuilt as
/// mobile cards (the web table's columns don't fit a phone). Keeps the date
/// range filter and the "Create" action.
class LeaveOfAbsenceScreen extends StatelessWidget {
  const LeaveOfAbsenceScreen({super.key});

  static const _records = <_Loa>[
    _Loa('H23969', 'Aug 17, 2026', 'Aug 17, 2026', 'Approved Leave',
        'Ariel Serrano', 'Aug 18, 2026'),
    _Loa('H23859', 'Aug 05, 2026', 'Aug 05, 2026', 'Approved UT (AM/PM)',
        'Ariel Serrano', 'Aug 05, 2026'),
    _Loa('H23854', 'Aug 05, 2026', 'Aug 04, 2026', 'Approved Leave',
        'Ariel Serrano', 'Aug 12, 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave of Absence'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => showToast(context, 'Search records'),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Sort',
            onPressed: () => showToast(context, 'Sort records'),
            icon: const Icon(Icons.swap_vert_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateLeaveOfAbsenceScreen(),
          ),
        ),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: _FilterBar(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                itemCount: _records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _LoaCard(record: _records[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.calendar_today_rounded,
                    size: 17, color: AppColors.inkSoft),
                SizedBox(width: 10),
                Text(
                  'Aug 2026 – Oct 2026',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _iconBtn(context, Icons.filter_list_rounded, 'Filter'),
      ],
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, String tip) {
    return GestureDetector(
      onTap: () => showToast(context, tip),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

class _LoaCard extends StatelessWidget {
  const _LoaCard({required this.record});

  final _Loa record;

  bool get _isUt => record.type.contains('UT');

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => showToast(context, 'Open ${record.no}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                record.no,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              const StatusPill(
                label: 'Posted',
                color: AppColors.info,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconBadge(
                icon: _isUt
                    ? Icons.running_with_errors_rounded
                    : Icons.directions_walk_rounded,
                color: AppColors.brandRed,
                size: 40,
                iconSize: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  record.type,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(child: _kv('Date applied', record.dateApplied)),
              Expanded(child: _kv('LOA date', record.loaDate)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _kv('Approved by', record.approvedBy)),
              Expanded(child: _kv('Approved date', record.approvedDate)),
            ],
          ),
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
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _Loa {
  const _Loa(
    this.no,
    this.dateApplied,
    this.loaDate,
    this.type,
    this.approvedBy,
    this.approvedDate,
  );

  final String no;
  final String dateApplied;
  final String loaDate;
  final String type;
  final String approvedBy;
  final String approvedDate;
}
