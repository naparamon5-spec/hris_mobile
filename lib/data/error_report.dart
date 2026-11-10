import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Sends an unexpected error to Crashlytics (when Firebase is set up) so the
/// technical details reach developers instead of the user's screen.
void reportError(Object error, [StackTrace? stack, String? reason]) {
  debugPrint('[error] ${reason ?? ''} $error');
  try {
    FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason, fatal: false);
  } catch (_) {
    // Firebase not initialised (tests, unconfigured builds): ignore.
  }
}
