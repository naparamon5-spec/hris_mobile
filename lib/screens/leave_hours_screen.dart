import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';

/// Leave Hours — the "Remaining Leave Hours" summary from the HRIS web app:
/// Approved Leave and Approved UT (AM/PM) always (dash when no balance), plus
/// VL / SL / Additional VL / Accumulated Leave only when they have a value.
class LeaveHoursScreen extends StatelessWidget {
  const LeaveHoursScreen({super.key});

  String _fmt(String? v) => (v == null || v.isEmpty) ? '— —' : v;

  /// A value worth showing: present and not "00:00".
  static bool _has(String? v) =>
      v != null && v.isNotEmpty && v.replaceAll(RegExp(r'[0:]'), '').isNotEmpty;

  List<Widget> _balanceCards(LeaveBalance b) => [
        if (_has(b.vlPaid))
          _HoursCard(
              label: 'VL Paid',
              value: b.vlPaid!,
              icon: Icons.beach_access_rounded),
        if (_has(b.slPaid))
          _HoursCard(
              label: 'SL Paid', value: b.slPaid!, icon: Icons.healing_rounded),
        if (_has(b.additionalVl))
          _HoursCard(
              label: 'Additional VL',
              value: b.additionalVl!,
              icon: Icons.more_time_rounded),
        if (_has(b.accumulatedLeave))
          _HoursCard(
              label: 'Accumulated Leave',
              value: b.accumulatedLeave!,
              icon: Icons.savings_rounded),
      ];

  static List<List<Widget>> _pairs(List<Widget> cards) => [
        for (var i = 0; i < cards.length; i += 2)
          cards.sublist(i, i + 2 > cards.length ? cards.length : i + 2),
      ];

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
              // VL / SL / Additional VL / Accumulated Leave only when the
              // employee actually has a balance for them.
              for (final pair in _pairs(_balanceCards(b))) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: pair[0]),
                    const SizedBox(width: 14),
                    Expanded(
                        child: pair.length > 1 ? pair[1] : const SizedBox()),
                  ],
                ),
              ],
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
