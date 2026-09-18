import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'notifications/push_service.dart';
import 'session_store.dart';
import 'tenants.dart';

/// The signed-in user's role. Elevated roles (manager, department head,
/// executive) can review approvals and file the extra "Other Requests".
enum UserRole { employee, manager, head, executive }

/// Thrown by [AppSession.login] when the account has 2FA enabled and a valid
/// one-time code has not yet been supplied. The UI should prompt for the code
/// and call [AppSession.completeTwoFactor].
class TwoFactorRequiredException implements Exception {}

/// Maps the backend `privilege` string to a [UserRole]. Unknown values fall
/// back to the least-privileged role.
UserRole roleFromPrivilege(String? privilege) {
  switch ((privilege ?? '').trim().toLowerCase()) {
    case 'manager':
      return UserRole.manager;
    case 'head':
      return UserRole.head;
    case 'executive':
      return UserRole.executive;
    case 'employee':
    default:
      return UserRole.employee;
  }
}

/// Session state, now backed by the HRIS API. Holds the signed-in user, their
/// tokens, and the role that gates the manager-only sections. Performs the
/// actual login/logout calls against the backend.
class AppSession extends ChangeNotifier {
  AppSession._() {
    // Let the HTTP client renew an expired access token mid-session.
    api.onUnauthorized = _refreshAccessToken;
  }
  static final AppSession instance = AppSession._();

  /// Shared HTTP client. Kept here so the access token set at login is reused
  /// by every other API call in the app.
  final ApiClient api = ApiClient();

  final SessionStore _store = SessionStore.instance;

  UserRole _role = UserRole.employee;
  String? _userId;
  String? _userName;

  /// The company chosen at sign-in. Kept across logout so we can return the
  /// user to that company's login screen (not the company picker).
  Tenant? _tenant;
  Tenant? get tenant => _tenant;
  set tenant(Tenant? t) {
    if (_tenant != t) {
      _tenant = t;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
  String? _position;
  String? _company;
  String? _refreshToken;

  // Last successful credentials, kept in memory so biometric / PIN unlock can
  // re-authenticate. In a production app this would be a refresh token in
  // secure storage rather than the password; this is a demo stand-in.
  String? _rememberedUserId;
  String? _rememberedPassword;
  bool _rememberedRemember = false;

  // True only when biometric credentials are actually persisted (saved when
  // enabling biometrics, or restored from secure storage). Kept separate from
  // the transient _remembered* values that every login attempt overwrites, so a
  // failed password login never makes the screen fall back to the biometric
  // panel.
  bool _biometricCredsSaved = false;

  UserRole get role => _role;
  String? get userId => _userId;
  String? get userName => _userName;

  /// Job title (position) and employer, from the login response.
  String? get position => _position;
  String? get company => _company;

  /// Stored so a future token-refresh flow can call `POST /auth/refresh`.
  String? get refreshToken => _refreshToken;
  bool get isSignedIn => api.accessToken != null;

  /// True when biometric sign-in has persisted credentials to reuse (set when
  /// enabling biometrics or restoring them from secure storage). A plain
  /// password login attempt — successful or failed — does not flip this.
  bool get hasSavedCredentials =>
      _biometricCredsSaved &&
      (_rememberedUserId?.isNotEmpty ?? false) &&
      (_rememberedPassword?.isNotEmpty ?? false);

  /// True for manager / head / executive — the roles that can approve records
  /// and requests and see the extra request types.
  bool get canApprove => _role != UserRole.employee;

  /// Signs in against `POST /public/login`. On success stores the tokens and
  /// user, and updates the role. Throws [ApiException] on failure so the UI can
  /// show the message.
  Future<void> login({
    required String userId,
    required String password,
    bool remember = false,
    String? otp,
  }) async {
    // Remember the attempt so a 2FA step (or biometric unlock) can re-submit
    // the same credentials together with the one-time code.
    _rememberedUserId = userId;
    _rememberedPassword = password;
    _rememberedRemember = remember;

    final data = await api.post('/public/login', body: {
      'user_id': userId,
      'password': password,
      'checked': remember,
      // The chosen company routes the login to that tenant's database.
      if (tenant?.id != null) 'tenant': tenant!.id,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
    });

    if (data is! Map) {
      throw ApiException('Unexpected response from server.');
    }

    // 2FA-enabled account, first step: server asks for the code before issuing
    // tokens.
    if (data['twoFactorRequired'] == true && data['accessToken'] == null) {
      throw TwoFactorRequiredException();
    }

    api.accessToken = data['accessToken'] as String?;
    _refreshToken = data['refreshToken'] as String?;

    final user = data['user'];
    Map<String, dynamic>? userMap;
    if (user is Map) {
      userMap = user.cast<String, dynamic>();
      _applyUser(userMap);
    }

    // Persist so the session survives app restarts / OS reclaim.
    await _store.saveSession(
      accessToken: api.accessToken,
      refreshToken: _refreshToken,
      user: userMap,
      tenantId: tenant?.id,
    );

    // Register this device for push notifications (best-effort).
    await _registerPush();

    notifyListeners();
  }

  void _applyUser(Map<String, dynamic> user) {
    _userId = user['user_id'] as String?;
    _userName = user['user_name'] as String?;
    _position = (user['position'] as String?)?.trim();
    _company = (user['company'] as String?)?.trim();
    _role = roleFromPrivilege(user['privilege'] as String?);
  }

  /// Restores a persisted session on app launch. Returns true if the user is
  /// signed in afterwards. Renews the access token via the refresh token.
  Future<bool> restore() async {
    final stored = await _store.read();
    if (stored == null) return false;

    _refreshToken = stored.refreshToken;
    api.accessToken = stored.accessToken;
    if (stored.user != null) _applyUser(stored.user!);
    if (stored.tenantId != null) {
      for (final t in kTenants) {
        if (t.id == stored.tenantId) {
          tenant = t;
          break;
        }
      }
    }

    // Restore biometric credentials so biometric sign-in works after restart.
    final bio = await _store.readBiometric();
    if (bio != null) {
      _rememberedUserId = bio.userId;
      _rememberedPassword = bio.password;
      _biometricCredsSaved = true;
    }

    // Renew the access token; if that fails the session is no longer valid.
    final ok = await _refreshAccessToken();
    if (ok) notifyListeners();
    return ok;
  }

  /// Uses the refresh token to obtain a fresh access token. Returns false (and
  /// clears the session) if the refresh token is missing or rejected.
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final data = await api.post('/public/refresh', body: {
        'refreshToken': _refreshToken,
      });
      if (data is Map && data['accessToken'] is String) {
        api.accessToken = data['accessToken'] as String;
        if (data['user'] is Map) {
          _applyUser((data['user'] as Map).cast<String, dynamic>());
        }
        await _store.saveAccessToken(api.accessToken);
        return true;
      }
      return false;
    } catch (_) {
      // Refresh token invalid/expired — drop the stored session.
      api.accessToken = null;
      _refreshToken = null;
      await _store.clearSession();
      return false;
    }
  }

  /// Stores the current user's password so biometric sign-in can reuse it,
  /// including across app restarts. Called after the password is verified when
  /// enabling biometrics.
  Future<void> saveBiometricCredentials(String password) async {
    _rememberedUserId = _userId;
    _rememberedPassword = password;
    _biometricCredsSaved = true;
    await _store.saveBiometric(_userId, password);
  }

  /// Forgets the stored biometric credentials (on disabling biometrics).
  Future<void> clearBiometricCredentials() async {
    _rememberedPassword = null;
    _biometricCredsSaved = false;
    await _store.clearBiometric();
  }

  /// Completes a login that returned [TwoFactorRequiredException], re-submitting
  /// the remembered credentials with the 6-digit [otp].
  Future<void> completeTwoFactor(String otp) async {
    await login(
      userId: _rememberedUserId ?? '',
      password: _rememberedPassword ?? '',
      remember: _rememberedRemember,
      otp: otp,
    );
  }

  /// Signs in via biometrics / PIN, reusing the credentials from the last
  /// password login this app run. Throws if there are none (e.g. fresh install
  /// or after a full restart) so the caller can show the password form.
  Future<void> biometricLogin() async {
    if (!hasSavedCredentials) {
      throw ApiException(
        'Sign in with your Employee ID and password once to enable biometric sign-in.',
      );
    }
    await login(
      userId: _rememberedUserId!,
      password: _rememberedPassword!,
      remember: _rememberedRemember,
    );
  }

  /// Clears the session. Best-effort call to the backend logout; local state is
  /// cleared regardless.
  Future<void> logout() async {
    // Drop this device's push token while the auth header is still valid.
    await _unregisterPush();
    try {
      await api.post('/auth/logout');
    } catch (_) {
      // Ignore — we clear locally either way.
    }
    api.accessToken = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    _position = null;
    _company = null;
    _role = UserRole.employee;
    // Clear the persisted session (biometric enrollment is kept so the user
    // can sign back in with biometrics).
    await _store.clearSession();
    notifyListeners();
  }

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  // ---- Push notifications ----
  String? _fcmToken;

  /// Sends this device's FCM token to the backend and keeps it updated on
  /// rotation. Best-effort: any failure (e.g. Firebase not yet configured) is
  /// swallowed so it never blocks sign-in.
  Future<void> _registerPush() async {
    try {
      final token = await PushService.instance.getToken();
      if (token == null || token.isEmpty) return;
      _fcmToken = token;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await api.post('/auth/fcm-token',
          body: {'fcm_token': token, 'platform': platform});
      PushService.instance.onTokenRefresh((t) async {
        _fcmToken = t;
        try {
          await api.post('/auth/fcm-token',
              body: {'fcm_token': t, 'platform': platform});
        } catch (_) {}
      });
    } catch (_) {
      // Firebase not configured / permission denied — ignore.
    }
  }

  Future<void> _unregisterPush() async {
    final t = _fcmToken;
    if (t == null) return;
    try {
      await api.post('/auth/fcm-token/remove', body: {'fcm_token': t});
    } catch (_) {}
    _fcmToken = null;
  }
}
