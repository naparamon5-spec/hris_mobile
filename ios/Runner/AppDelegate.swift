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
