import 'package:flutter/foundation.dart';

import 'hris_api.dart';
import 'mock_data.dart';

/// Live unread counts that drive the notification bell, Requests tab, and
/// Payslip / Timesheet row dots. Sourced from `/auth/notifications`.
class InboxBadges extends ChangeNotifier {
  InboxBadges._();
  static final InboxBadges instance = InboxBadges._();

  static const payslipKinds = {'payslip', 'payday'};
  static const timesheetKinds = {'timesheet'};

  int unread = 0;
  bool payslipNew = false;
  bool timesheetNew = false;

  bool get hasUnread => unread > 0;
  bool get requestsNew => payslipNew || timesheetNew;

  List<AppNotification> _unreadItems = const [];

  Future<void> refresh() async {
    try {
      final res = await HrisApi.instance.notifications();
      unread = res.unread;
      _unreadItems = res.items.where((n) => n.unread).toList();
      payslipNew = _unreadItems.any((n) => payslipKinds.contains(n.kind));
      timesheetNew = _unreadItems.any((n) => timesheetKinds.contains(n.kind));
      notifyListeners();
    } catch (_) {
      // Leave the last known counts; a later refresh will catch up.
    }
  }

  /// Marks matching unread rows as read (so the red dots clear after a visit).
  Future<void> consumeKinds(Set<String> kinds) async {
    final ids = _unreadItems
        .where((n) => kinds.contains(n.kind) && n.id != null)
        .map((n) => n.id!)
        .toList();
    for (final id in ids) {
      try {
        await HrisApi.instance.markNotificationRead(id);
      } catch (_) {}
    }
    await refresh();
  }

  void clear() {
    unread = 0;
    payslipNew = false;
    timesheetNew = false;
    _unreadItems = const [];
    notifyListeners();
  }
}
