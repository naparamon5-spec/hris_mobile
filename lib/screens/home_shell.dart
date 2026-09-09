import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'requests_screen.dart';
import 'apps_screen.dart';
import 'profile_screen.dart';

/// Bottom-nav container that hosts the primary areas, mapped from the HRIS web
/// sidebar: Home, Record/Request, Apps, and Profile (the sidebar's "Menu").
/// Directory and Notifications are reached from the Dashboard app bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  final _tabs = const [
    DashboardScreen(),
    RequestsScreen(),
    AppsScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NavItem(Icons.grid_view_rounded, 'Home'),
    _NavItem(Icons.assignment_rounded, 'Requests'),
    _NavItem(Icons.apps_rounded, 'Apps'),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Color(0x14101828),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < _items.length; i++)
                  _NavButton(
                    item: _items[i],
                    selected: _index == i,
                    onTap: () => setState(() => _index = i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.brandGradient : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected ? kBrandShadow : null,
                ),
                child: Icon(
                  item.icon,
                  size: 23,
                  color: selected ? Colors.white : AppColors.inkFaint,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.brandRed : AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
