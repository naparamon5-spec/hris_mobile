import 'package:flutter/material.dart';

import '../screens/approvals_center_screen.dart';
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

  static GlobalKey<NavigatorState>? _nav;
  static bool _homeMounted = false;
  static WidgetBuilder? _pending;

  /// Called by HomeShell when it mounts: opens a request held until sign-in.
  static void attachHome() {
    _homeMounted = true;
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _nav?.currentState?.push(MaterialPageRoute(builder: pending)));
  }

  static void detachHome() => _homeMounted = false;

  /// Records the decision for [token] and opens the request. [nav] is the
  /// app's root navigator (ready — the splash has routed).
  static Future<void> handle(String token, GlobalKey<NavigatorState> nav) async {
    _nav = nav;
    final context = nav.currentContext;
    if (context == null) return;

    Map<String, dynamic> result;
    showLoadingOverlay(context, immediate: true);
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
    if (witness) {
      final ctx = nav.currentContext;
      if (ctx != null && ctx.mounted) {
        await showSuccessDialog(
          ctx,
          title: approved ? 'Approved as witness' : 'Disapproved as witness',
          message: '${result['message'] ?? ''}',
        );
      }
      return;
    }

    // Everyone else goes straight to the request's details in their Decided
    // list, which show its updated status (no extra dialog to tap through).
    final Widget screen = ApprovalsCenterScreen(
      module: type == 'other' ? 'requests' : 'records',
      scope: 'history',
      initialTaskId: '$type#$id',
      initialRecordId: id,
    );
    if (AppSession.instance.isSignedIn && _homeMounted) {
      nav.currentState?.push(MaterialPageRoute(builder: (_) => screen));
    } else {
      // Signed out: open it once they sign in.
      _pending = (_) => screen;
    }
  }
}
