import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

import 'app_session.dart';
import 'hris_api.dart';

/// What the launch-time version check decided the app should do.
enum UpdateAction {
  /// Running version is fine — carry on normally.
  none,

  /// A newer version exists but the current one still works — show a
  /// dismissible "update available" prompt.
  soft,

  /// The current version is below the minimum the backend still supports —
  /// block the app behind a mandatory update screen.
  forced,
}

/// Result of [AppVersionGate.check]: the decision plus the store link to open.
class UpdateDecision {
  const UpdateDecision(this.action, {this.storeUrl});

  final UpdateAction action;
  final String? storeUrl;

  static const none = UpdateDecision(UpdateAction.none);
}

/// Launch-time app-version gate. Asks the backend for the min/latest version
/// for this platform + tenant, compares against the running build, and decides
/// whether to prompt (soft) or block (forced). Any failure — offline, backend
/// down, malformed response — resolves to [UpdateAction.none] so a version
/// check never keeps a user out of the app.
class AppVersionGate {
  AppVersionGate._();
  static final AppVersionGate instance = AppVersionGate._();

  /// The platform string the backend understands.
  static String get _platform => Platform.isAndroid ? 'android' : 'ios';

  Future<UpdateDecision> check({String? tenantId}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "1.1.0"

      final data = await HrisApi.instance.appVersion(
        platform: _platform,
        tenant: tenantId,
      );

      final min = (data['minSupportedVersion'] as String?) ?? current;
      final latest = (data['latestVersion'] as String?) ?? current;
      final storeUrl = data['storeUrl'] as String?;

      if (_isBelow(current, min)) {
        return UpdateDecision(UpdateAction.forced, storeUrl: storeUrl);
      }
      if (_isBelow(current, latest)) {
        return UpdateDecision(UpdateAction.soft, storeUrl: storeUrl);
      }
      return UpdateDecision.none;
    } catch (_) {
      // Never block launch on a failed check.
      return UpdateDecision.none;
    }
  }

  /// Convenience: the tenant id chosen for the current session, if any.
  static String? get currentTenantId => AppSession.instance.tenant?.id;

  /// True when [version] is strictly older than [floor], comparing dotted
  /// numeric parts ("1.2.0" < "1.10.0"). Non-numeric/junk parts count as 0.
  static bool _isBelow(String version, String floor) {
    final a = _parts(version);
    final b = _parts(floor);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai < bi;
    }
    return false; // equal
  }

  static List<int> _parts(String v) => v
      .split('+')
      .first // drop any build suffix
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
}
