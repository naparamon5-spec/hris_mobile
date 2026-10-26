import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import 'hris_api.dart';
import 'mock_data.dart';
import 'notifications/notification_routes.dart';

/// Live unread counts that drive the notification bell, Requests tab, and
/// Payslip / Timesheet / request-status row dots. Sourced from `/auth/notifications`.
class InboxBadges extends ChangeNotifier {
  InboxBadges._();
  static final InboxBadges instance = InboxBadges._();

  static const payslipKinds = {'payslip', 'payday'};
  static const timesheetKinds = {'timesheet'};

  int unread = 0;
  bool payslipNew = false;
  bool timesheetNew = false;

  /// Request types ('loa' | 'call-approval' | 'manual-ad' | 'overtime') with
  /// an unread status-change (decision) notification for the signed-in user.
  Set<String> decisionTypes = const {};

  bool get hasUnread => unread > 0;
  bool get requestsNew =>
      payslipNew || timesheetNew || decisionTypes.isNotEmpty;

  bool decisionNew(String requestType) => decisionTypes.contains(requestType);

  List<AppNotification> _unreadItems = const [];

  Future<void> refresh() async {
    try {
      final res = await HrisApi.instance.notifications();
      unread = res.unread;
      _unreadItems = res.items.where((n) => n.unread).toList();
      payslipNew = _unreadItems.any((n) => payslipKinds.contains(n.kind));
      timesheetNew = _unreadItems.any((n) => timesheetKinds.contains(n.kind));
      decisionTypes = _unreadItems
          .where(_isDecision)
          .map((n) => inferRequestType(n.requestType, n.title, n.body))
          .toSet();
      _syncAppBadge(unread);
      notifyListeners();
    } catch (_) {
      // Leave the last known counts; a later refresh will catch up.
    }
  }

  /// Keep the OS app-icon badge in sync with the in-app unread count.
  /// updateBadge is async, so swallow its Future errors too (e.g. a
  /// MissingPluginException before a full rebuild, or unsupported devices) —
  /// otherwise they surface as an unhandled exception.
  void _syncAppBadge(int count) {
    final n = count < 0 ? 0 : count;
    try {
      AppBadgePlus.updateBadge(n).catchError((_) {});
    } catch (_) {
      // Ignore — badging is best-effort.
    }
  }

  static bool _isDecision(AppNotification n) =>
      inferKind(n.kind, n.title, n.body) == 'decision';

  /// Marks matching unread rows as read (so the red dots clear after a visit).
  Future<void> consumeKinds(Set<String> kinds) =>
      _consume((n) => kinds.contains(n.kind));

  /// Clears the status-change dot for one request type after a visit.
  Future<void> consumeDecisions(String requestType) => _consume((n) =>
      _isDecision(n) &&
      inferRequestType(n.requestType, n.title, n.body) == requestType);

  Future<void> _consume(bool Function(AppNotification) test) async {
    final ids = _unreadItems
        .where((n) => test(n) && n.id != null)
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
    decisionTypes = const {};
    _unreadItems = const [];
    _syncAppBadge(0);
    notifyListeners();
  }
}
