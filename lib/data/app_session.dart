import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'notifications/push_service.dart';
import 'security_state.dart';
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

  // Last login attempt's credentials, kept in memory only so a 2FA step can
  // re-submit them with the one-time code. Never persisted.
  String? _rememberedUserId;
  String? _rememberedPassword;
  bool _rememberedRemember = false;

  // Biometric enrollment (persisted in the OS secure enclave via SessionStore).
  // Biometric sign-in restores the session from _bioRefreshToken — the password
  // is never stored or replayed. _bioUserId is shown on the login screen.
  String? _bioUserId;
  String? _bioRefreshToken;
  String? _bioTenantId;
  bool _biometricCredsSaved = false;

  UserRole get role => _role;
  String? get userId => _userId;
  String? get userName => _userName;

  /// The Employee ID saved for biometric sign-in (shown on the login screen's
  /// biometric panel). Null when there are no saved biometric credentials.
  String? get savedUserId => hasSavedCredentials ? _bioUserId : null;

  /// The company id the biometric enrollment belongs to. The login screen only
  /// offers the biometric panel when the selected company matches this.
  String? get savedTenantId => hasSavedCredentials ? _bioTenantId : null;

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
      (_bioUserId?.isNotEmpty ?? false) &&
      (_bioRefreshToken?.isNotEmpty ?? false);

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

    // If biometrics is already enrolled, refresh the stored token to the latest
    // one so it never goes stale mid-enrollment.
    if (_biometricCredsSaved && _refreshToken != null) {
      _bioUserId = _userId;
      _bioRefreshToken = _refreshToken;
      _bioTenantId = tenant?.id;
      await _store.saveBiometric(_userId, _refreshToken, tenant?.id);
    }

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
    // Always restore the last chosen company + biometric enrollment first —
    // even with no active session — so that after sign-out + restart the app
    // returns to that company's login screen (biometric panel) instead of the
    // company picker.
    final lastTenantId = await _store.readTenantId();
    if (lastTenantId != null) {
      for (final t in kTenants) {
        if (t.id == lastTenantId) {
          tenant = t;
          break;
        }
      }
    }
    final bio = await _store.readBiometric();
    if (bio != null) {
      _bioUserId = bio.userId;
      _bioRefreshToken = bio.refreshToken;
      _bioTenantId = bio.tenantId;
      _biometricCredsSaved = true;
    }

    // Reconcile: if biometrics was turned OFF in Settings but stale credentials
    // are still in the keychain (e.g. a delete that didn't persist), purge them
    // so the login screen never shows the biometric panel while it's disabled.
    // (SecurityState.load() runs before restore() in main().)
    if (_biometricCredsSaved && !SecurityState.instance.biometricsEnabled) {
      await clearBiometricCredentials();
    }

    final stored = await _store.read();
    if (stored == null) {
      // No active session, but we may still have a remembered company/biometric
      // enrollment above — let the UI route accordingly.
      if (tenant != null || _biometricCredsSaved) notifyListeners();
      return false;
    }

    _refreshToken = stored.refreshToken;
    api.accessToken = stored.accessToken;
    if (stored.user != null) _applyUser(stored.user!);

    // Renew the access token; if that fails the session is no longer valid.
    final ok = await _refreshAccessToken();
    if (ok) {
      // Re-register this device for push on every launch (tokens rotate and
      // dead ones are pruned server-side), not only on a fresh login.
      unawaited(_registerPush());
      notifyListeners();
    }
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

  /// Enables biometric sign-in by capturing the current session's refresh token
  /// (never the password) in the secure enclave. Call after the password has
  /// been verified in Settings. Throws if there is no live session to capture.
  Future<void> saveBiometricCredentials() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      throw ApiException(
        'Please sign in again before enabling biometric sign-in.',
      );
    }
    _bioUserId = _userId;
    _bioRefreshToken = _refreshToken;
    _bioTenantId = tenant?.id;
    _biometricCredsSaved = true;
    await _store.saveBiometric(_userId, _refreshToken, tenant?.id);
    notifyListeners();
  }

  /// Forgets the stored biometric enrollment (on disabling biometrics).
  Future<void> clearBiometricCredentials() async {
    _bioUserId = null;
    _bioRefreshToken = null;
    _bioTenantId = null;
    _biometricCredsSaved = false;
    await _store.clearBiometric();
    notifyListeners();
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

  /// Signs in via biometrics / PIN by restoring the session from the stored
  /// refresh token — no password is replayed. Throws [ApiException] if there is
  /// no enrollment, or if the token has expired/been revoked (in which case the
  /// enrollment is cleared so the UI falls back to the password form).
  Future<void> biometricLogin() async {
    if (!hasSavedCredentials) {
      throw ApiException(
        'Sign in with your Employee ID and password once to enable biometric sign-in.',
      );
    }
    try {
      final data = await api.post('/public/refresh', body: {
        'refreshToken': _bioRefreshToken,
      });
      if (data is! Map || data['accessToken'] is! String) {
        throw ApiException('Could not restore your session.');
      }
      api.accessToken = data['accessToken'] as String;
      _refreshToken = _bioRefreshToken;

      Map<String, dynamic>? userMap;
      if (data['user'] is Map) {
        userMap = (data['user'] as Map).cast<String, dynamic>();
        _applyUser(userMap);
      }

      // Persist the restored session so a later cold start resumes without
      // needing biometrics again.
      await _store.saveSession(
        accessToken: api.accessToken,
        refreshToken: _refreshToken,
        user: userMap,
        tenantId: tenant?.id,
      );

      await _registerPush();
      notifyListeners();
    } on ApiException {
      // Refresh token expired (>30d) or revoked — drop enrollment so the user
      // re-enables biometrics after a normal password sign-in.
      await clearBiometricCredentials();
      throw ApiException(
        'Your biometric sign-in has expired. Please sign in with your password.',
      );
    }
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
  bool _tokenRefreshBound = false;

  Future<void> _registerPush() async {
    final platform = Platform.isIOS ? 'ios' : 'android';

    // Bind the refresh listener FIRST (once), so a token that only becomes
    // available later — iOS APNs is often not ready at login time — is still
    // sent to the backend when it arrives or rotates.
    if (!_tokenRefreshBound) {
      _tokenRefreshBound = true;
      PushService.instance.onTokenRefresh((t) async {
        if (t.isEmpty || !isSignedIn) return;
        _fcmToken = t;
        try {
          await api.post('/auth/fcm-token',
              body: {'fcm_token': t, 'platform': platform});
        } catch (_) {}
      });
    }

    try {
      final token = await PushService.instance.getToken();
      if (token == null || token.isEmpty) return;
      _fcmToken = token;
      await api.post('/auth/fcm-token',
          body: {'fcm_token': token, 'platform': platform});
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
