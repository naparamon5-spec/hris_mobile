import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;
  int _selectedTab = 0; // 0: All, 1: Unread

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await HrisApi.instance.notifications();
      if (!mounted) return;
      setState(() {
        _notifications = res.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final previous = _notifications;
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(unread: false)).toList();
    });
    try {
      await HrisApi.instance.markAllNotificationsRead();
      if (mounted) showToast(context, 'All notifications have been marked as read.', isSuccess: true, title: 'Updated');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _notifications = previous); // revert on failure
      showToast(context, e.message);
    }
  }

  Future<void> _markSingleAsRead(int index) async {
    final n = _notifications[index];
    if (!n.unread || n.id == null) return;
    setState(() => _notifications[index] = n.copyWith(unread: false));
    try {
      await HrisApi.instance.markNotificationRead(n.id!);
    } on ApiException {
      // Silent — the list still reads fine; a refresh corrects it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final unreadCount = _notifications.where((n) => n.unread).length;
    final displayed = _selectedTab == 0
        ? _notifications
        : _notifications.where((n) => n.unread).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Centered All / Unread Segmented Tab
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SegmentTab(
                      label: 'All',
                      badgeCount: _notifications.length,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _SegmentTab(
                      label: 'Unread',
                      badgeCount: unreadCount,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brandRed))
                  : _error != null
                      ? _NotifError(message: _error!, onRetry: _load)
                      : displayed.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 32,
                              color: AppColors.inkFaint,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No unread notifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'You are all caught up for now!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.brandRed,
                      onRefresh: _load,
                      child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: displayed.length,
                      itemBuilder: (context, i) {
                        final item = displayed[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NotificationCard(
                            item: item,
                            onTap: () {
                              final originalIndex =
                                  _notifications.indexOf(item);
                              if (originalIndex != -1) {
                                _markSingleAsRead(originalIndex);
                              }
                              showToast(context, item.title);
                            },
                          ),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifError extends StatelessWidget {
  const _NotifError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppColors.inkFaint),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13.5,
                color: isSelected ? Colors.white : AppColors.inkSoft,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.line,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      border: item.unread
          ? Border.all(color: AppColors.brandRed.withValues(alpha: 0.35))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: item.icon,
            color: item.color,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight:
                              item.unread ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (item.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.8,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
