import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../data/inbox_badges.dart';
import 'dashboard_screen.dart';
import 'requests_screen.dart';
import 'whos_out_screen.dart';
import 'profile_screen.dart';

/// Bottom-nav container that hosts the primary areas, mapped from the HRIS web
/// sidebar: Home, Record/Request, Who's Out, and Profile (the sidebar's "Menu").
/// Directory and Notifications are reached from the Dashboard app bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  // Tabs are built lazily: only a visited tab is instantiated, so sign-in
  // shows the Dashboard immediately instead of loading all four tabs (and
  // their network calls) at once. Visited tabs stay alive via IndexedStack.
  late final Set<int> _visited = {widget.initialIndex};

  @override
  void initState() {
    super.initState();
    InboxBadges.instance.refresh();
  }

  static const _items = [
    _NavItem(Icons.grid_view_rounded, 'Home'),
    _NavItem(Icons.assignment_rounded, 'Requests'),
    _NavItem(Icons.calendar_month_rounded, "Who's Out"),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  Widget _tabFor(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const RequestsScreen();
      case 2:
        return const WhosOutScreen();
      default:
        return const ProfileScreen();
    }
  }

  void _select(int i) => setState(() {
        _index = i;
        _visited.add(i);
      });

  @override
  Widget build(BuildContext context) {
    // The loading overlay is mounted globally in main.dart's MaterialApp
    // builder, so it is not wrapped here.
    return Scaffold(
      body: HomeShellScope(
        selectTab: _select,
        child: IndexedStack(
          index: _index,
          children: [
            for (int i = 0; i < _items.length; i++)
              _visited.contains(i) ? _tabFor(i) : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < _items.length; i++)
                  _NavButton(
                    item: _items[i],
                    selected: _index == i,
                    onTap: () => _select(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets descendants (e.g. the dashboard) switch the shell's active tab instead
/// of pushing a full-screen route, so the bottom nav stays visible.
class HomeShellScope extends InheritedWidget {
  const HomeShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(int index) selectTab;

  static HomeShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>();

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) => false;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 24,
                color: selected ? AppColors.brandRed : AppColors.inkFaint,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.brandRed : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
