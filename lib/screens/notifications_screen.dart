import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => showToast(context, 'All marked as read'),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            _Banner(),
            const SizedBox(height: 22),
            const Text('Today',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            ...kNotifications
                .take(2)
                .map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationCard(item: n),
                    )),
            const SizedBox(height: 12),
            const Text('Earlier',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            ...kNotifications
                .skip(2)
                .map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationCard(item: n),
                    )),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unread = kNotifications.where((n) => n.unread).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: kBrandShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$unread new notifications',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 3),
                Text('Stay on top of approvals and updates',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => showToast(context, item.title),
      border: item.unread
          ? Border.all(color: AppColors.brandRed.withValues(alpha: 0.25))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: item.icon, color: item.color, size: 46, iconSize: 23),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                    ),
                    if (item.unread)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                            color: AppColors.brandRed,
                            shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.body,
                    style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.8,
                        height: 1.35)),
                const SizedBox(height: 8),
                Text(item.time,
                    style: const TextStyle(
                        color: AppColors.inkFaint,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
