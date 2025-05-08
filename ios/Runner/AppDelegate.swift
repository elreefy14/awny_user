import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }

      GeneratedPluginRegistrant.register(with: self)
      GMSServices.provideAPIKey("AIzaSyAHnpWZ4bVrjI25FMnWD4uvoTTp3X75COM")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
