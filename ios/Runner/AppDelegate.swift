import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    disableBriefPasswordReveal(engineBridge)
    registerUptimeClock(engineBridge)
  }

  /// Milliseconds since the phone booted, still counting while it sleeps
  /// (Darwin's CLOCK_MONOTONIC does). Unlike the wall clock, the user can't
  /// change it, so the 3-minute background sign-out can't be skipped by
  /// setting the time back. Used by lib/data/uptime.dart.
  private func registerUptimeClock(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "UptimeClock")
    else { return }
    FlutterMethodChannel(name: "com.ardentnetworks.hris/clock", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "elapsedRealtime" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(NSNumber(value: clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000))
      }
  }

  /// Flutter briefly shows the last typed character of a password on mobile.
  /// The engine only turns that off via the optional `brieflyShowPassword`
  /// user setting, which only the platform side can send. Dart calls
  /// `hris/password_reveal` once it is running, passing the current settings
  /// so they're echoed back unchanged; iOS's later settings updates omit the
  /// key, so the value sticks.
  private func disableBriefPasswordReveal(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PasswordRevealSetting")
    else { return }
    let messenger = registrar.messenger()
    let settings = FlutterBasicMessageChannel(
      name: "flutter/settings",
      binaryMessenger: messenger,
      codec: FlutterJSONMessageCodec.sharedInstance())
    FlutterMethodChannel(name: "hris/password_reveal", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "disable", var data = call.arguments as? [String: Any] else {
          result(FlutterMethodNotImplemented)
          return
        }
        data["brieflyShowPassword"] = false
        settings.sendMessage(data)
        result(nil)
      }
  }
}
