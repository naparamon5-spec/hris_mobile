import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';

/// The user cancelled the fingerprint / face prompt. Not an error to show.
class BiometricCancelled implements Exception {}

/// Holds the biometric sign-in token behind the phone's biometric lock: an
/// Android Keystore key that needs a fingerprint/face for every use, or an iOS
/// Keychain item limited to the current set of enrolled fingers/faces. Reading
/// it shows the OS biometric prompt; adding a new fingerprint or face to the
/// phone makes the stored token unreadable (biometric sign-in must then be
/// turned on again). Unlike plain secure storage, a rooted or jailbroken phone
/// can't simply read the token, and the in-app check can't be skipped.
class BioVault {
  BioVault._();
  static final BioVault instance = BioVault._();

  static const _name = 'hris_bio_token';

  static const _prompt = PromptInfo(
    androidPromptInfo: AndroidPromptInfo(
      title: 'Sign in to ANI HRIS',
      subtitle: 'Confirm with your fingerprint or face',
      negativeButton: 'Use password',
      confirmationRequired: false,
    ),
    iosPromptInfo: IosPromptInfo(
      saveTitle: 'Turn on biometric sign-in for ANI HRIS',
      accessTitle: 'Sign in to ANI HRIS',
    ),
  );

  Future<BiometricStorageFile> _file() => BiometricStorage().getStorage(
        _name,
        options: StorageFileInitOptions(
          // Every read needs the biometric (no unlock window) and only real
          // biometrics count — never the phone PIN.
          authenticationValidityDurationSeconds: -1,
          authenticationRequired: true,
          androidBiometricOnly: true,
          darwinBiometricOnly: true,
        ),
        promptInfo: _prompt,
      );

  /// True when this phone can keep a biometric-locked secret.
  Future<bool> available() async {
    try {
      return await BiometricStorage().canAuthenticate() ==
          CanAuthenticateResponse.success;
    } catch (e) {
      debugPrint('[BioVault] unavailable: $e');
      return false;
    }
  }

  /// Stores [token] (may show the biometric prompt). Throws
  /// [BiometricCancelled] if the user cancels.
  Future<void> write(String token) async {
    try {
      await (await _file()).write(token);
    } on AuthException catch (e) {
      if (_isCancel(e)) throw BiometricCancelled();
      rethrow;
    }
  }

  /// Shows the biometric prompt and returns the stored token, or null if
  /// there is none or it can no longer be read (fingerprints/faces changed).
  /// Throws [BiometricCancelled] if the user cancels.
  Future<String?> read() async {
    try {
      final v = await (await _file()).read();
      return (v == null || v.isEmpty) ? null : v;
    } on AuthException catch (e) {
      if (_isCancel(e)) throw BiometricCancelled();
      debugPrint('[BioVault] read failed: $e');
      return null;
    } catch (e) {
      // Key invalidated by a biometric change, or storage error.
      debugPrint('[BioVault] read failed: $e');
      return null;
    }
  }

  /// Removes the stored token. Best-effort.
  Future<void> delete() async {
    try {
      await (await _file()).delete();
    } catch (e) {
      debugPrint('[BioVault] delete failed: $e');
    }
  }

  static bool _isCancel(AuthException e) =>
      e.code == AuthExceptionCode.userCanceled ||
      e.code == AuthExceptionCode.canceled;
}
