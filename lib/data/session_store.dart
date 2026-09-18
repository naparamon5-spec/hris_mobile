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
  static const _kBioPass = 'bio_password';

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

  // ---- Biometric credentials (kept across restarts so biometric works) ----
  Future<void> saveBiometric(String? userId, String? password) async {
    await _write(_kBioUser, userId);
    await _write(_kBioPass, password);
  }

  Future<({String userId, String password})?> readBiometric() async {
    final u = await _read(_kBioUser);
    final p = await _read(_kBioPass);
    if (u == null || u.isEmpty || p == null || p.isEmpty) return null;
    return (userId: u, password: p);
  }

  Future<void> clearBiometric() async {
    await _storage.delete(key: _kBioUser);
    await _storage.delete(key: _kBioPass);
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
