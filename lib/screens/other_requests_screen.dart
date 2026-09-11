import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'feature_screen.dart';

/// A request type the employee can file from "Other Requests".
class _RequestType {
  const _RequestType(this.label, this.icon, this.subtitle);
  final String label;
  final IconData icon;
  final String subtitle;
}

const _types = <_RequestType>[
  _RequestType('Certificate of Employment', Icons.badge_outlined,
      'Request an official COE'),
  _RequestType('Official Business', Icons.directions_walk_rounded,
      'File an out-of-office work trip'),
  _RequestType('Schedule Adjustment', Icons.edit_calendar_rounded,
      'Request a change to your schedule'),
  _RequestType('Undertime', Icons.timelapse_rounded,
      'File an early-out / undertime'),
  _RequestType('Loan / Cash Advance', Icons.savings_outlined,
      'Apply for a loan or cash advance'),
  _RequestType('Reimbursement', Icons.request_quote_outlined,
      'Claim work-related expenses'),
];

/// "Other Requests" — a single hub that lists the employee's filed requests
/// (empty for now) with a Create button that opens a type picker.
class OtherRequestsScreen extends StatelessWidget {
  const OtherRequestsScreen({super.key});

  void _openCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create a request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select the type of request to file.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = _types[i];
                  return ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FeatureScreen(
                            title: t.label,
                            icon: t.icon,
                            color: AppColors.brandRed,
                          ),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    leading: IconBadge(
                        icon: t.icon, color: AppColors.brandRed, size: 42),
                    title: Text(
                      t.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      t.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkFaint,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inkFaint),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Other Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: AppColors.fieldFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inbox_rounded,
                    size: 32, color: AppColors.inkFaint),
              ),
              const SizedBox(height: 16),
              const Text(
                'No requests yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Tap Create to file a certificate, official business, '
                  'undertime and other requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
