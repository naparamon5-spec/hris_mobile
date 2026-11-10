import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Clears secure storage on a fresh install.
///
/// iOS keeps Keychain items after the app is deleted, so a reinstall would
/// find the previous session and biometric enrollment. Files in the app's
/// support folder are deleted with the app, so a missing marker file means
/// this is a new install.
class FreshInstallReset {
  FreshInstallReset._();

  static const _marker = 'fresh_install_checked';
  // Written by TenantCache on earlier builds; its presence means an existing
  // install was updated, not reinstalled.
  static const _tenantCache = 'tenants_cache.json';

  /// Call first in `main()`, before anything reads secure storage.
  static Future<void> run() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final marker = File('${dir.path}/$_marker');
      if (await marker.exists()) return;
      final isUpdate = await File('${dir.path}/$_tenantCache').exists();
      if (!isUpdate) {
        await const FlutterSecureStorage().deleteAll();
        await const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ).deleteAll();
      }
      await dir.create(recursive: true);
      await marker.writeAsString('1');
    } catch (e) {
      debugPrint('[FreshInstallReset] skipped: $e');
    }
  }
}
