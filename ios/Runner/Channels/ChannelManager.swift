import Foundation
import Flutter

class ChannelManager {
    static let shared = ChannelManager()
    
    var dataChannel: FlutterMethodChannel?
    
    func setup(messenger: FlutterBinaryMessenger) {
        dataChannel = FlutterMethodChannel(name: "com.ytmultimate/data", binaryMessenger: messenger)
        
        dataChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleDataCall(call: call, result: result)
        }
    }
    
    private func handleDataCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "search":
            guard let args = call.arguments as? [String: Any],
                  let query = args["query"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing query", details: nil))
                return
            }
            let escaped = query.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\"", with: "\\\"")
            JSContextManager.shared.evaluateAsync(script: "globalThis.search('\(escaped)')") { res in
                result(res)
            }
            
        case "getSong":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
                return
            }
            JSContextManager.shared.evaluateAsync(script: "globalThis.getSong('\(id)')") { res in
                result(res)
            }
            
        case "getPlaylist":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
                return
            }
            JSContextManager.shared.evaluateAsync(script: "globalThis.getPlaylist('\(id)')") { res in
                result(res)
            }
            
        case "getArtist":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
                return
            }
            JSContextManager.shared.evaluateAsync(script: "globalThis.getArtist('\(id)')") { res in
                result(res)
            }
            
        case "getAlbum":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
                return
            }
            JSContextManager.shared.evaluateAsync(script: "globalThis.getAlbum('\(id)')") { res in
                result(res)
            }
            
        case "getStream":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
                return
            }
            JSContextManager.shared.evaluateAsync(script: "globalThis.getStream('\(id)')") { res in
                result(res)
            }
            
        case "getHome":
            JSContextManager.shared.evaluateAsync(script: "globalThis.getHome()") { res in
                result(res)
            }
            
        case "getLibrary":
            JSContextManager.shared.evaluateAsync(script: "globalThis.getLibrary()") { res in
                result(res)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
