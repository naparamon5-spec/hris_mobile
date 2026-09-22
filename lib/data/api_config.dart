import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the Flutter app finds the HRIS backend (the `hris-server` Express API).
///
/// The tricky part is that "localhost" means different things per platform:
///   * Android emulator  -> the host machine is reachable at 10.0.2.2
///   * iOS simulator     -> localhost works, it shares the Mac's network
///   * Web / desktop      -> localhost works
///   * Physical device   -> must use the Mac's LAN IP (set [lanHostOverride])
///
/// Change [_port] if you run the server on a different port.
class ApiConfig {
  ApiConfig._();

  /// Backend base URL, supplied at build/run time as an environment value:
  ///
  ///   flutter run   --dart-define=API_BASE_URL=https://hris-api.ardentnetworks.com.ph/api/v1
  ///   flutter build --dart-define=API_BASE_URL=https://hris-api.ardentnetworks.com.ph/api/v1
  ///
  /// (or via a --dart-define-from-file JSON). When it isn't provided, the app
  /// falls back to the local per-platform dev host below, so `flutter run`
  /// with no defines keeps talking to a local `hris-server`.
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const int _port = 3000;

  /// Set this to your Mac's LAN IP (e.g. '192.168.1.20') when testing on a
  /// real phone on the same Wi-Fi. Leave null for emulators/simulators.
  static const String? lanHostOverride = null;

  /// Host portion of the local backend URL, resolved for the current platform.
  static String get _host {
    if (lanHostOverride != null) return lanHostOverride!;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  /// Base URL including the API version prefix. Uses the API_BASE_URL
  /// environment value when set; otherwise the local per-platform dev host.
  static String get baseUrl =>
      _envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://$_host:$_port/api/v1';
}
