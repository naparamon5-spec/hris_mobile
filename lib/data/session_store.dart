import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the signed-in session (tokens + basic user + company + optional
/// biometric credentials) in the OS secure store, so the app stays logged in
/// across restarts and when the OS reclaims it during multitasking.
class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUser = 'user_json';
  static const _kTenant = 'tenant_id';
  static const _kBioUser = 'bio_user_id';
  // Refresh token captured when biometrics is enabled. Biometric sign-in uses
  // it to restore the session WITHOUT ever storing or replaying the password.
  static const _kBioRefresh = 'bio_refresh_token';
  // The company the enrollment belongs to — the biometric panel is only offered
  // for this company (a different company must sign in with a password).
  static const _kBioTenant = 'bio_tenant_id';
  // Legacy key from the password-based biometric login; cleaned up on migration.
  static const _kBioPassLegacy = 'bio_password';
  // "Remember me" prefill — persists the Employee ID (NEVER the password) so
  // the login form can prefill it after a relaunch or logout.
  static const _kRememberId = 'remember_user_id';
  // The app version recorded on the previous launch. Used to force a sign-out
  // when a user updates to a new version so stale tokens/claims don't carry
  // over into a build that may have changed the auth contract.
  static const _kLastLaunchedVersion = 'last_launched_version';

  Future<String?> readLastLaunchedVersion() => _read(_kLastLaunchedVersion);
  Future<void> saveLastLaunchedVersion(String version) =>
      _write(_kLastLaunchedVersion, version);

  // When the app last went to the background (epoch ms). Lets the 3-minute
  // background sign-out still apply if the app was killed while backgrounded.
  static const _kBackgroundedAt = 'backgrounded_at';

  Future<DateTime?> readBackgroundedAt() async {
    final v = int.tryParse(await _read(_kBackgroundedAt) ?? '');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  Future<void> saveBackgroundedAt(DateTime? at) => at == null
      ? _storage.delete(key: _kBackgroundedAt)
      : _write(_kBackgroundedAt, at.millisecondsSinceEpoch.toString());

  Future<void> saveSession({
    required String? accessToken,
    required String? refreshToken,
    Map<String, dynamic>? user,
    String? tenantId,
  }) async {
    await _write(_kAccess, accessToken);
    await _write(_kRefresh, refreshToken);
    await _write(_kUser, user == null ? null : jsonEncode(user));
    await _write(_kTenant, tenantId);
  }

  /// Updates just the access token (after a refresh).
  Future<void> saveAccessToken(String? token) => _write(_kAccess, token);

  /// The last chosen company id, kept across sign-out so the app can return to
  /// that company's login screen (with the biometric panel) rather than the
  /// company picker.
  Future<String?> readTenantId() => _read(_kTenant);

  Future<StoredSession?> read() async {
    final access = await _read(_kAccess);
    final refresh = await _read(_kRefresh);
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      return null;
    }
    final userRaw = await _read(_kUser);
    Map<String, dynamic>? user;
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        user = (jsonDecode(userRaw) as Map).cast<String, dynamic>();
      } catch (_) {}
    }
    return StoredSession(
      accessToken: access,
      refreshToken: refresh,
      user: user,
      tenantId: await _read(_kTenant),
    );
  }

  // ---- Remember me (Employee ID prefill only — never the password) ----
  Future<void> saveRememberedUserId(String? userId) =>
      _write(_kRememberId, userId == null || userId.isEmpty ? null : userId);
  Future<String?> readRememberedUserId() => _read(_kRememberId);
  Future<void> clearRememberedUserId() async {
    await _storage.delete(key: _kRememberId);
  }

  // ---- Biometric enrollment (kept across restarts so biometric works) ----
  // Stores the Employee ID + a refresh token + the company; never the password.
  Future<void> saveBiometric(
      String? userId, String? refreshToken, String? tenantId) async {
    await _write(_kBioUser, userId);
    await _write(_kBioRefresh, refreshToken);
    await _write(_kBioTenant, tenantId);
    // Drop any password left over from the old scheme.
    await _storage.delete(key: _kBioPassLegacy);
  }

  Future<({String userId, String refreshToken, String? tenantId})?>
      readBiometric() async {
    final u = await _read(_kBioUser);
    final r = await _read(_kBioRefresh);
    if (u == null || u.isEmpty || r == null || r.isEmpty) return null;
    return (userId: u, refreshToken: r, tenantId: await _read(_kBioTenant));
  }

  Future<void> clearBiometric() async {
    await _storage.delete(key: _kBioUser);
    await _storage.delete(key: _kBioRefresh);
    await _storage.delete(key: _kBioTenant);
    await _storage.delete(key: _kBioPassLegacy);
  }

  /// Clears the session tokens/user (keeps biometric creds unless told).
  Future<void> clearSession({bool includeBiometric = false}) async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
    if (includeBiometric) await clearBiometric();
  }

  Future<void> _write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}

class StoredSession {
  StoredSession({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.tenantId,
  });

  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? tenantId;
}
