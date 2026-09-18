import 'package:flutter/foundation.dart';

/// Centralized state for biometrics and two-factor authentication (2FA).
class SecurityState extends ChangeNotifier {
  SecurityState._();
  static final SecurityState instance = SecurityState._();

  bool _biometricsEnabled = true;
  bool _twoFactorEnabled = true;
  String _twoFactorMethod = 'Authenticator App (TOTP)';
  final String _backupPhone = '+63 917 •••• 4567';

  bool get biometricsEnabled => _biometricsEnabled;
  bool get twoFactorEnabled => _twoFactorEnabled;
  String get twoFactorMethod => _twoFactorMethod;
  String get backupPhone => _backupPhone;

  void setBiometricsEnabled(bool value) {
    _biometricsEnabled = value;
    notifyListeners();
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
