import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';

/// Leave Hours — the "Remaining Leave Hours" summary from the HRIS web app:
/// Approved Leave and Approved UT (AM/PM). Values show a dash placeholder when
/// no approved balance has been posted yet, matching the web behaviour.
class LeaveHoursScreen extends StatelessWidget {
  const LeaveHoursScreen({super.key});

  String _fmt(String? v) => (v == null || v.isEmpty) ? '— —' : v;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Hours')),
      body: SafeArea(
        child: AsyncView<LeaveBalance>(
          load: () => HrisApi.instance.leaveHours(),
          useGlobalLoader: true,
          builder: (context, b) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const SmallCapsHeader('Remaining Leave Hours'),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: _HoursCard(
                      label: 'Approved Leave',
                      value: _fmt(b.approvedLeave),
                      icon: Icons.event_note_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HoursCard(
                      label: 'Approved UT (AM/PM)',
                      value: _fmt(b.approvedUt),
                      icon: Icons.timelapse_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HoursCard(
                      label: 'Additional VL',
                      value: _fmt(b.additionalVl),
                      icon: Icons.more_time_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HoursCard(
                      label: 'SL Paid',
                      value: _fmt(b.slPaid),
                      icon: Icons.healing_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HoursCard(
                      label: 'VL Paid',
                      value: _fmt(b.vlPaid),
                      icon: Icons.beach_access_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              const _EmptyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  const _HoursCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.brandRed, size: 24),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w800,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.inkFaint),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Balances appear once your requests are approved.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
