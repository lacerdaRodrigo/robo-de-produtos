import Flutter
import UIKit

private final class AparenciaRadarPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let canal = FlutterMethodChannel(
      name: "br.com.radarbeneficios.app/aparencia",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(AparenciaRadarPlugin(), channel: canal)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let preferencias = UserDefaults.standard
    switch call.method {
    case "carregar":
      result(preferencias.string(forKey: "radar_tema"))
    case "salvar":
      let argumentos = call.arguments as? [String: Any]
      if let modo = argumentos?["modo"] as? String {
        preferencias.set(modo, forKey: "radar_tema")
      } else {
        preferencias.removeObject(forKey: "radar_tema")
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

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
    AparenciaRadarPlugin.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "AparenciaRadarPlugin")
    )
  }
}
