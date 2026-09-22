import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized state for biometrics and two-factor authentication (2FA).
class SecurityState extends ChangeNotifier {
  SecurityState._();
  static final SecurityState instance = SecurityState._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kBioEnabled = 'biometrics_enabled';

  // Off by default until the user explicitly enables it in Settings. Persisted
  // so the choice survives restarts (and stays in sync with whether biometric
  // credentials are actually saved).
  bool _biometricsEnabled = false;
  bool _twoFactorEnabled = true;
  String _twoFactorMethod = 'Authenticator App (TOTP)';
  final String _backupPhone = '+63 917 •••• 4567';

  bool get biometricsEnabled => _biometricsEnabled;
  bool get twoFactorEnabled => _twoFactorEnabled;
  String get twoFactorMethod => _twoFactorMethod;
  String get backupPhone => _backupPhone;

  /// Loads the persisted biometric preference. Call once at startup (main()).
  Future<void> load() async {
    try {
      final v = await _storage.read(key: _kBioEnabled);
      if (v != null) {
        _biometricsEnabled = v == 'true';
        notifyListeners();
      }
    } catch (_) {
      // Keep the default (off) if secure storage is unavailable.
    }
  }

  void setBiometricsEnabled(bool value) {
    _biometricsEnabled = value;
    notifyListeners();
    // Persist best-effort; the in-memory value is already updated.
    _storage.write(key: _kBioEnabled, value: value.toString()).catchError((_) {});
  }

  void setTwoFactorEnabled(bool value) {
    _twoFactorEnabled = value;
    notifyListeners();
  }

  void setTwoFactorMethod(String method) {
    _twoFactorMethod = method;
    notifyListeners();
  }
}
