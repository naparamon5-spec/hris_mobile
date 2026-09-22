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
  // Legacy key from the password-based biometric login; cleaned up on migration.
  static const _kBioPassLegacy = 'bio_password';

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

  // ---- Biometric enrollment (kept across restarts so biometric works) ----
  // Stores the Employee ID + a refresh token; never the password.
  Future<void> saveBiometric(String? userId, String? refreshToken) async {
    await _write(_kBioUser, userId);
    await _write(_kBioRefresh, refreshToken);
    // Drop any password left over from the old scheme.
    await _storage.delete(key: _kBioPassLegacy);
  }

  Future<({String userId, String refreshToken})?> readBiometric() async {
    final u = await _read(_kBioUser);
    final r = await _read(_kBioRefresh);
    if (u == null || u.isEmpty || r == null || r.isEmpty) return null;
    return (userId: u, refreshToken: r);
  }

  Future<void> clearBiometric() async {
    await _storage.delete(key: _kBioUser);
    await _storage.delete(key: _kBioRefresh);
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
