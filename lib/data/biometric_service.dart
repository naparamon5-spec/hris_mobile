import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// The capabilities the current device actually exposes, so the UI can show
/// only what's really there (fingerprint / face / iris) plus whether a device
/// PIN/pattern/passcode can be used as a fallback.
class BiometricCapabilities {
  BiometricCapabilities({
    required this.hasFingerprint,
    required this.hasFace,
    required this.hasIris,
    required this.canCheck,
    required this.deviceSupported,
  });

  final bool hasFingerprint;
  final bool hasFace;
  final bool hasIris;

  /// Biometrics are available AND enrolled.
  final bool canCheck;

  /// Device supports auth (biometrics or device credential like PIN/passcode).
  final bool deviceSupported;

  /// True when the device has no enrolled biometrics — only a PIN/passcode
  /// (or nothing) is available.
  bool get onlyDeviceCredential => !hasFingerprint && !hasFace && !hasIris;
}

/// Thin wrapper over local_auth. Queries what the device supports and runs the
/// real OS authentication prompt.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Inspects the device for enrolled biometrics and overall support.
  Future<BiometricCapabilities> capabilities() async {
    bool canCheck = false;
    bool supported = false;
    List<BiometricType> types = const [];
    try {
      canCheck = await _auth.canCheckBiometrics;
      supported = await _auth.isDeviceSupported();
      types = await _auth.getAvailableBiometrics();
    } on PlatformException {
      // Leave defaults (all false) — the caller falls back to PIN/password.
    }
    return BiometricCapabilities(
      hasFingerprint: types.contains(BiometricType.fingerprint),
      hasFace: types.contains(BiometricType.face),
      hasIris: types.contains(BiometricType.iris),
      canCheck: canCheck,
      deviceSupported: supported,
    );
  }

  /// Runs the OS auth prompt. [biometricOnly] forces a biometric (no PIN
  /// fallback). Returns true only on a verified match. Throws no exceptions —
  /// returns false on any platform error.
  Future<bool> authenticate({
    String reason = 'Verify your identity to sign in',
    bool biometricOnly = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
