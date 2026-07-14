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
    
    guard let assetRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "AssetRegistrar") else {
      print("Failed to obtain AssetRegistrar")
      return
    }
    
    JSContextManager.shared.setupContext(registrar: assetRegistrar)
    ChannelManager.shared.setup(messenger: assetRegistrar.messenger())
  }
}
