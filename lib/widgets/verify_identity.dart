import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/biometric_service.dart';
import '../data/hris_api.dart';
import 'ui.dart';

/// Gates a sensitive screen behind an identity check and returns true only on
/// success. With [allowBiometrics], the OS prompt (Face ID / fingerprint, with
/// the device PIN or passcode as its own fallback) is tried first; if it fails
/// or is cancelled, the password prompt below takes over. The password is
/// verified against the backend, showing the blur loader while verifying and an
/// error toast on a wrong password.
Future<bool> verifyIdentity(
  BuildContext context, {
  String title = "We'll verify it's you",
  String message =
      'For your privacy, please confirm your password to view this information.',
  String? subject,
  String? subjectDetail,
  String buttonLabel = 'Verify',
  bool allowBiometrics = false,
  String biometricReason = "Verify it's you to continue",
}) async {
  if (allowBiometrics) {
    final caps = await BiometricService.instance.capabilities();
    if (caps.deviceSupported &&
        await BiometricService.instance
            .authenticate(reason: biometricReason, biometricOnly: false)) {
      return true;
    }
    if (!context.mounted) return false;
  }

  final password = await promptPassword(context,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      subject: subject,
      subjectDetail: subjectDetail);
  if (password == null || password.isEmpty || !context.mounted) return false;

  showLoadingOverlay(context);
  try {
    final ok = await HrisApi.instance.verifyPassword(password);
    if (!context.mounted) return false;
    hideLoadingOverlay(context);
    if (!ok) {
      await showToast(context,
          'The password you entered is incorrect. Please try again.',
          isSuccess: false, title: 'Incorrect Password');
      return false;
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      hideLoadingOverlay(context);
      await showToast(context, e.message, isSuccess: false, title: 'Verification Failed');
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      hideLoadingOverlay(context);
      await showToast(context, "We couldn't verify your password.\n($e)",
          isSuccess: false, title: 'Verification Failed');
    }
    return false;
  }
}
