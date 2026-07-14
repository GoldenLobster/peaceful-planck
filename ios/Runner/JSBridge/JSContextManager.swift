import Foundation
import JavaScriptCore
import Flutter

class JSContextManager {
    static let shared = JSContextManager()
    var context: JSContext?
    private var timers: [Int: Timer] = [:]
    
    private init() {
    }
    
    func setupContext(registrar: FlutterPluginRegistrar) {
        context = JSContext()
        context?.exceptionHandler = { context, exception in
            if let exception = exception {
                print("JS Error: \(exception)")
            }
        }
        
        context?.evaluateScript("var global = globalThis; var window = globalThis;")
        injectPolyfills()
        loadBundle(registrar: registrar)
    }
    
    private func injectPolyfills() {
        guard let context = context else { return }
        
        let nativeFetch: @convention(block) (String, String) -> Void = { reqStr, callbackId in
            guard let data = reqStr.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let urlString = dict["url"] as? String,
                  let url = URL(string: urlString) else {
                JSContextManager.shared.rejectFetch(callbackId: callbackId, error: "Invalid Request")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = dict["method"] as? String ?? "GET"
            
            if let headers = dict["headers"] as? [String: String] {
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            if let bodyStr = dict["body"] as? String, !bodyStr.isEmpty {
                request.httpBody = bodyStr.data(using: .utf8)
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    JSContextManager.shared.rejectFetch(callbackId: callbackId, error: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    JSContextManager.shared.rejectFetch(callbackId: callbackId, error: "Invalid Response")
                    return
                }
                
                let status = httpResponse.statusCode
                let statusText = HTTPURLResponse.localizedString(forStatusCode: status)
                var headersDict: [String: String] = [:]
                for (k, v) in httpResponse.allHeaderFields {
                    if let key = k as? String, let val = v as? String {
                        headersDict[key] = val
                    }
                }
                
                let headersJson = (try? JSONSerialization.data(withJSONObject: headersDict)) ?? Data()
                let headersStr = String(data: headersJson, encoding: .utf8) ?? "{}"
                
                let bodyBase64 = data?.base64EncodedString() ?? ""
                
                JSContextManager.shared.resolveFetch(callbackId: callbackId, status: status, statusText: statusText, headers: headersStr, bodyBase64: bodyBase64)
            }
            task.resume()
        }
        
        let nativeSetTimeout: @convention(block) (Int, Int) -> Void = { id, ms in
            DispatchQueue.main.async {
                let timer = Timer.scheduledTimer(withTimeInterval: Double(ms) / 1000.0, repeats: false) { _ in
                    JSContextManager.shared.context?.evaluateScript("globalThis.fireTimeout(\(id))")
                    JSContextManager.shared.timers.removeValue(forKey: id)
                }
                JSContextManager.shared.timers[id] = timer
            }
        }
        
        let nativeClearTimeout: @convention(block) (Int) -> Void = { id in
            DispatchQueue.main.async {
                JSContextManager.shared.timers[id]?.invalidate()
                JSContextManager.shared.timers.removeValue(forKey: id)
            }
        }

        let nativeSetInterval: @convention(block) (Int, Int) -> Void = { id, ms in
            DispatchQueue.main.async {
                let timer = Timer.scheduledTimer(withTimeInterval: Double(ms) / 1000.0, repeats: true) { _ in
                    JSContextManager.shared.context?.evaluateScript("globalThis.fireInterval(\(id))")
                }
                JSContextManager.shared.timers[id] = timer
            }
        }
        
        let nativeClearInterval: @convention(block) (Int) -> Void = { id in
            DispatchQueue.main.async {
                JSContextManager.shared.timers[id]?.invalidate()
                JSContextManager.shared.timers.removeValue(forKey: id)
            }
        }
        
        context.setObject(nativeFetch, forKeyedSubscript: "nativeFetch" as NSString)
        context.setObject(nativeSetTimeout, forKeyedSubscript: "nativeSetTimeout" as NSString)
        context.setObject(nativeClearTimeout, forKeyedSubscript: "nativeClearTimeout" as NSString)
        context.setObject(nativeSetInterval, forKeyedSubscript: "nativeSetInterval" as NSString)
        context.setObject(nativeClearInterval, forKeyedSubscript: "nativeClearInterval" as NSString)
    }
    
    private func resolveFetch(callbackId: String, status: Int, statusText: String, headers: String, bodyBase64: String) {
        DispatchQueue.main.async {
            let escapedHeaders = headers.replacingOccurrences(of: "\\", with: "\\\\")
                                        .replacingOccurrences(of: "\"", with: "\\\"")
            
            let script = "globalThis['fetch_resolve_\(callbackId)'](\(status), '\(statusText)', '\(escapedHeaders)', '\(bodyBase64)');"
            self.context?.evaluateScript(script)
        }
    }
    
    private func rejectFetch(callbackId: String, error: String) {
        DispatchQueue.main.async {
            let script = "globalThis['fetch_reject_\(callbackId)']('\(error)');"
            self.context?.evaluateScript(script)
        }
    }
    
    private func loadBundle(registrar: FlutterPluginRegistrar) {
        let key = registrar.lookupKey(forAsset: "assets/js/bundle.js")
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
            print("Failed to find bundle.js")
            return
        }
        
        do {
            let script = try String(contentsOfFile: path)
            context?.evaluateScript(script)
            print("JS bundle loaded.")
        } catch {
            print("Failed to load bundle.js: \(error)")
        }
    }
    
    func evaluateAsync(script: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Need a way to await JS Promises. We can use a callback injection.
            let callbackId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let wrappedScript = """
            (async () => {
                try {
                    let res = await \(script);
                    globalThis['resolve_\(callbackId)'](res ? res.toString() : '');
                } catch(e) {
                    globalThis['reject_\(callbackId)'](e.toString());
                }
            })();
            """
            
            let resolveBlock: @convention(block) (String) -> Void = { result in
                DispatchQueue.main.async {
                    self.context?.setObject(nil, forKeyedSubscript: "resolve_\(callbackId)" as NSString)
                    self.context?.setObject(nil, forKeyedSubscript: "reject_\(callbackId)" as NSString)
                    completion(result)
                }
            }
            
            let rejectBlock: @convention(block) (String) -> Void = { error in
                DispatchQueue.main.async {
                    self.context?.setObject(nil, forKeyedSubscript: "resolve_\(callbackId)" as NSString)
                    self.context?.setObject(nil, forKeyedSubscript: "reject_\(callbackId)" as NSString)
                    print("Async JS Error: \(error)")
                    completion("ERROR:" + error)
                }
            }
            
            DispatchQueue.main.async {
                self.context?.setObject(resolveBlock, forKeyedSubscript: "resolve_\(callbackId)" as NSString)
                self.context?.setObject(rejectBlock, forKeyedSubscript: "reject_\(callbackId)" as NSString)
                self.context?.evaluateScript(wrappedScript)
            }
        }
    }
}
