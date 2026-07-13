import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let assetRegistrar = self.registrar(forPlugin: "AssetRegistrar")!
    
    JSContextManager.flutterRegistrar = assetRegistrar
    JSContextManager.shared.setupContext(registrar: assetRegistrar)
    ChannelManager.shared.setup(messenger: controller.binaryMessenger)
    AudioManager.shared.setupChannels(messenger: controller.binaryMessenger)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
