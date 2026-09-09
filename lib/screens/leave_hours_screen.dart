import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// Leave Hours — the "Remaining Leave Hours" summary from the HRIS web app:
/// Approved Leave and Approved UT (AM/PM). Values show a dash placeholder when
/// no approved balance has been posted yet, matching the web behaviour.
class LeaveHoursScreen extends StatelessWidget {
  const LeaveHoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Hours')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: const [
            SmallCapsHeader('Remaining Leave Hours'),
            SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: _HoursCard(
                    label: 'Approved Leave',
                    value: '— —',
                    icon: Icons.directions_walk_rounded,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _HoursCard(
                    label: 'Approved UT (AM/PM)',
                    value: '— —',
                    icon: Icons.running_with_errors_rounded,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _EmptyNote(),
          ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'hrs',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ],
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
