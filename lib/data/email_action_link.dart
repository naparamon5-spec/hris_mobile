import 'dart:convert';

import 'package:flutter/material.dart';

import '../screens/approvals_center_screen.dart';
import '../widgets/email_decision_sheet.dart';
import '../widgets/ui.dart';
import 'api_client.dart';
import 'app_session.dart';
import 'hris_api.dart';

/// Approve / Disapprove links from approval emails:
///   https://hris-api.ardentnetworks.com.ph/email-action?token=x
/// On a phone with the app installed the OS opens them here instead of the
/// browser. The app records the decision (same as the browser link — the
/// signed token is the credential, no session needed), shows the website's
/// result message, then opens that request in Approvals.
class EmailActionLinks {
  EmailActionLinks._();

  /// The link's token, or null when [uri] isn't an email-action link.
  static String? tokenFrom(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty);
    final isAction = uri.host == 'email-action' ||
        (segments.isNotEmpty && segments.last == 'email-action');
    final token = uri.queryParameters['token'];
    return isAction && token != null && token.isNotEmpty ? token : null;
  }

  /// 'approve' / 'disapprove' read from the token's (signed) payload, only
  /// to word the confirm prompt; the server verifies the token itself.
  static String? actionOf(String token) {
    try {
      final body = token.split('.').first;
      final json = utf8.decode(base64Url.decode(base64Url.normalize(body)));
      final a = (jsonDecode(json) as Map)['a'];
      return a == 'approve' || a == 'disapprove' ? a as String : null;
    } catch (_) {
      return null;
    }
  }

  static GlobalKey<NavigatorState>? _nav;
  static bool _homeMounted = false;
  static VoidCallback? _pending;

  /// Called by HomeShell when it mounts: opens a request held until sign-in.
  static void attachHome() {
    _homeMounted = true;
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => pending());
  }

  static void detachHome() {
    _homeMounted = false;
    // Never carry a request over to whoever signs in next.
    _pending = null;
  }

  /// Records the decision for [token] and opens the request. [nav] is the
  /// app's root navigator (ready — the splash has routed).
  static Future<void> handle(String token, GlobalKey<NavigatorState> nav) async {
    _nav = nav;
    final context = nav.currentContext;
    if (context == null) return;

    // Ask first: links can be opened by other apps or pages, and a decision
    // can't be undone.
    final action = actionOf(token);
    if (action == null) {
      await showToast(context, 'This link is invalid or has expired.',
          isSuccess: false, title: 'Not done');
      return;
    }
    final approve = action == 'approve';
    final confirmed = await showConfirmDialog(
      context,
      title: approve ? 'Approve this request?' : 'Disapprove this request?',
      message: approve
          ? 'This approves the request from your approval email. It cannot be undone.'
          : 'This disapproves the request from your approval email. It cannot be undone.',
      confirmLabel: approve ? 'Approve' : 'Disapprove',
      cancelLabel: 'Cancel',
      destructive: !approve,
    );
    if (!confirmed) return;
    final ctx0 = nav.currentContext;
    if (ctx0 == null || !ctx0.mounted) return;

    Map<String, dynamic> result;
    showLoadingOverlay(ctx0, immediate: true);
    try {
      result = await HrisApi.instance.emailAction(token);
    } on ApiException catch (e) {
      hideLoadingOverlay();
      final ctx = nav.currentContext;
      if (ctx != null && ctx.mounted) {
        await showToast(ctx, e.message, isSuccess: false, title: 'Not done');
      }
      return;
    } catch (_) {
      hideLoadingOverlay();
      final ctx = nav.currentContext;
      if (ctx != null && ctx.mounted) {
        await showToast(ctx, 'Something went wrong. Please try again later.',
            isSuccess: false, title: 'Not done');
      }
      return;
    }
    hideLoadingOverlay();

    final type = '${result['type'] ?? ''}';
    final id = '${result['id'] ?? ''}';
    final witness = result['witness'] == true;
    final approved = result['action'] == 'approve';

    // Like the website, a MAD witness can't view the MAD once they've decided
    // it (it has moved on to the department head, or ended) — just confirm.
    // Signed out: also just confirm. The request's details are never kept to
    // show after a later sign-in, which may be someone else's.
    if (witness || !AppSession.instance.isSignedIn || !_homeMounted) {
      final ctx = nav.currentContext;
      if (ctx != null && ctx.mounted) {
        await showSuccessDialog(
          ctx,
          title: witness
              ? (approved ? 'Approved as witness' : 'Disapproved as witness')
              : (approved ? 'Approved' : 'Disapproved'),
          message: '${result['message'] ?? ''}',
        );
      }
      return;
    }

    // Everyone else goes straight to the request, in their Decided list, with
    // the same details the email and the website show (sent by the server)
    // and its updated status — no extra dialog to tap through.
    final details = result['details'];
    void open() {
      final nav = _nav?.currentState;
      if (nav == null) return;
      final hasDetails = details is Map;
      nav.push(MaterialPageRoute(
        builder: (_) => ApprovalsCenterScreen(
          module: type == 'other' ? 'requests' : 'records',
          scope: 'all',
          // Without the server's details, fall back to the list's own sheet.
          initialTaskId: hasDetails ? null : '$type#$id',
          initialRecordId: hasDetails ? null : id,
        ),
      ));
      if (!hasDetails) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _nav?.currentContext;
        if (ctx == null || !ctx.mounted) return;
        showPremiumBottomSheet(
          ctx,
          isScrollControlled: true,
          builder: (_) => EmailDecisionSheet(
            details: details.cast<String, dynamic>(),
            status: '${result['status'] ?? ''}',
          ),
        );
      });
    }

    open();
  }
}
