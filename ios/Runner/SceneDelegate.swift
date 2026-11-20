import Flutter
import UIKit
import app_links

class SceneDelegate: FlutterSceneDelegate {
  // Links arrive at the scene, and app_links only listens on the app delegate,
  // so hand every link over: when it launches the app, and when the app is
  // already running (anihris:// buttons, Universal Links).
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    let url =
      connectionOptions.urlContexts.first?.url
      ?? connectionOptions.userActivities.first?.webpageURL
    if let url { AppLinks.shared.handleLink(url: url) }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    if let url = URLContexts.first?.url { AppLinks.shared.handleLink(url: url) }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
    if let url = userActivity.webpageURL { AppLinks.shared.handleLink(url: url) }
  }
}
