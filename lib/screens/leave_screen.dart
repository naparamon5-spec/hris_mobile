import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _filters = const ['All', 'Approved', 'Pending', 'Rejected'];
  int _selected = 0;

  List<LeaveRequest> get _visible {
    if (_selected == 0) return kLeaveRequests;
    return kLeaveRequests
        .where((r) => r.status == _filters[_selected])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Leave Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRequestSheet(context),
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request leave',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
          children: [
            _BalanceHeader(),
            const SizedBox(height: 22),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final sel = i == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.brandGradient : null,
                        color: sel ? null : AppColors.card,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: sel ? null : kSoftShadow,
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: sel ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ..._visible.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LeaveCard(request: r),
                )),
            if (_visible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: const [
                    Icon(Icons.inbox_rounded,
                        size: 56, color: AppColors.inkFaint),
                    SizedBox(height: 12),
                    Text('No requests here',
                        style: TextStyle(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RequestSheet(),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Total leave balance',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '2026 Credits',
                  style: TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text(
                '18.0',
                style: TextStyle(
                  color: AppColors.brandRed,
                  fontSize: 36,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'days remaining',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _pill('Annual', '9.0'),
              const SizedBox(width: 8),
              _pill('Sick', '7.0'),
              const SizedBox(width: 8),
              _pill('Personal', '2.0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.request});
  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => showToast(context, '${request.type} details'),
      child: Row(
        children: [
          IconBadge(
              icon: request.icon,
              color: request.statusColor,
              size: 48,
              iconSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(request.type,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    StatusPill(
                        label: request.status, color: request.statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.inkFaint),
                    const SizedBox(width: 5),
                    Text(request.range,
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12.5)),
                    const SizedBox(width: 10),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                          color: AppColors.inkFaint,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(request.days,
                        style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet();

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _types = const [
    ('Annual Leave', Icons.beach_access_rounded),
    ('Sick Leave', Icons.healing_rounded),
    ('Work From Home', Icons.home_work_rounded),
    ('Emergency', Icons.emergency_rounded),
  ];
  int _type = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('New leave request',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            const Text('Leave type',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < _types.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _type = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == i
                            ? AppColors.dangerSoft
                            : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _type == i
                                ? AppColors.brandRed
                                : Colors.transparent,
                            width: 1.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_types[i].$2,
                              size: 18,
                              color: _type == i
                                  ? AppColors.brandRed
                                  : AppColors.inkSoft),
                          const SizedBox(width: 8),
                          Text(_types[i].$1,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _type == i
                                      ? AppColors.brandRed
                                      : AppColors.ink)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _dateField('From', 'Jun 23')),
                const SizedBox(width: 14),
                Expanded(child: _dateField('To', 'Jun 27')),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Reason',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 10),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a short note for your manager…',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showToast(context, 'Leave request submitted ✓');
              },
              child: const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.inkSoft),
              const SizedBox(width: 10),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
