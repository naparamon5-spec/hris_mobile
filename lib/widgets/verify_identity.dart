import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import 'ui.dart';

/// Gates a sensitive screen behind a password check: prompts for the password,
/// verifies it against the backend, and returns true only on success. Shows the
/// blur loader while verifying and an error toast on a wrong password.
Future<bool> verifyIdentity(
  BuildContext context, {
  String title = "We'll verify it's you",
  String message =
      'For your privacy, please confirm your password to view this information.',
}) async {
  final password = await promptPassword(context, title: title, message: message);
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
  }
}
