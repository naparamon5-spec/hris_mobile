import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'directory_screen.dart';
import 'feature_screen.dart';

/// APPS hub — mirrors the "Apps" group in the HRIS web sidebar.
class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'Apps',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Everyday tools across the company.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
          ),
          const SizedBox(height: 22),
          const SmallCapsHeader('Apps'),
          NavListTile(
            icon: Icons.calendar_today_rounded,
            label: "Who's Out",
            color: AppColors.inkSoft,
            onTap: () => _feature(context, "Who's Out",
                Icons.calendar_today_rounded, AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.groups_rounded,
            label: 'My Community',
            color: AppColors.inkSoft,
            onTap: () => _feature(context, 'My Community',
                Icons.groups_rounded, AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.menu_book_rounded,
            label: 'Directory',
            color: AppColors.inkSoft,
            onTap: () => _go(context, const DirectoryScreen()),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.confirmation_number_rounded,
            label: 'Ticket',
            color: AppColors.inkSoft,
            onTap: () => _feature(context, 'Ticket',
                Icons.confirmation_number_rounded, AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          NavListTile(
            icon: Icons.meeting_room_rounded,
            label: 'Room Reservation',
            color: AppColors.inkSoft,
            onTap: () => _feature(context, 'Room Reservation',
                Icons.meeting_room_rounded, AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _feature(
          BuildContext context, String title, IconData icon, Color color) =>
      _go(context, FeatureScreen(title: title, icon: icon, color: color));
}
