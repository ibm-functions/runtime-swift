import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Dispatch

class Whisk {
    
    static var baseUrl = ProcessInfo.processInfo.environment["__OW_API_HOST"]
    static var apiKey = ProcessInfo.processInfo.environment["__OW_API_KEY"]
    // This will allow user to modify the default JSONDecoder and JSONEncoder used by epilogue
    static var jsonDecoder = JSONDecoder()
    static var jsonEncoder = JSONEncoder()
    
    class func invoke(actionNamed action : String, withParameters params : [String:Any], blocking: Bool = true) -> [String:Any] {
        let parsedAction = parseQualifiedName(name: action)
        let strBlocking = blocking ? "true" : "false"
        let path = "/api/v1/namespaces/\(parsedAction.namespace)/actions/\(parsedAction.name)?blocking=\(strBlocking)"
        
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "POST")
    }
    
    class func trigger(eventNamed event : String, withParameters params : [String:Any]) -> [String:Any] {
        let parsedEvent = parseQualifiedName(name: event)
        let path = "/api/v1/namespaces/\(parsedEvent.namespace)/triggers/\(parsedEvent.name)?blocking=true"
        
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "POST")
    }
    
    class func createTrigger(triggerNamed trigger: String, withParameters params : [String:Any]) -> [String:Any] {
        let parsedTrigger = parseQualifiedName(name: trigger)
        let path = "/api/v1/namespaces/\(parsedTrigger.namespace)/triggers/\(parsedTrigger.name)"
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "PUT")
    }
    
    class func createRule(ruleNamed ruleName: String, withTrigger triggerName: String, andAction actionName: String) -> [String:Any] {
        let parsedRule = parseQualifiedName(name: ruleName)
        let path = "/api/v1/namespaces/\(parsedRule.namespace)/rules/\(parsedRule.name)"
        let params = ["trigger":triggerName, "action":actionName]
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "PUT")
    }
    
    // handle the GCD dance to make the post async, but then obtain/return
    // the result from this function sync
    private class func sendWhiskRequestSyncronish(uriPath: String, params : [String:Any], method: String) -> [String:Any] {
        var response : [String:Any]!
        var auth: String = ""
        
        let queue = DispatchQueue.global()
        let invokeGroup = DispatchGroup()
        
        if isIAMEnabled {
            auth = getAuthHeader()
        } else {
            auth = getBasicAuth()
        }
        invokeGroup.enter()
        queue.async {
            postUrlSession(uriPath: "\(baseUrl!)\(uriPath)", params: params, contentType: "application/json", method: method, auth: auth, extraHeaders: ["x-namespace-id":namespace!], group: invokeGroup) { result in
                response = result
            }
        }
        
        // On one hand, FOREVER seems like an awfully long time...
        // But on the other hand, I think we can rely on the system to kill this
        // if it exceeds a reasonable execution time.
        switch invokeGroup.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.success:
            break
        case DispatchTimeoutResult.timedOut:
            break
        }
        
        return response
    }
    
    private class func getBasicAuth() -> String {
        let loginData: Data = apiKey!.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let base64EncodedAuthKey  = loginData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return "Basic \(base64EncodedAuthKey)"
    }
    
    
    /**
     * Using new UrlSession
     */
    private class func postUrlSession(uriPath: String, params : [String:Any], contentType: String, method: String, auth: String, extraHeaders: [String:String], group: DispatchGroup, callback : @escaping([String:Any]) -> Void) {
        
        guard let encodedPath = uriPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            callback(["error": "Error encoding uri path for http request \(uriPath)"])
            return
        }
        if let url = URL(string: encodedPath) {
            var request = URLRequest(url: url)
            request.httpMethod = method
            do {
                if contentType == "application/json" {
                    request.httpBody = try JSONSerialization.data(withJSONObject: params)
                } else {
                    //url form encode
                    var parameterBody = ""
                    for (key, value) in params {
                        let p = "\(key)=\(Whisk.percentEscapeString(value as! String))"
                        parameterBody = parameterBody == "" ? p : parameterBody + "&" + p
                    }
                    request.httpBody = parameterBody.data(using: String.Encoding.utf8)
                }
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
                
                request.addValue(auth, forHTTPHeaderField: "Authorization")
                for (key, value) in extraHeaders {
                    request.addValue(value, forHTTPHeaderField: key)
                }

                
                
                let session = URLSession(configuration: URLSessionConfiguration.default)
                let task = session.dataTask(with: request, completionHandler: {data, response, error -> Void in
                    // exit group after we are done
                    defer {
                        group.leave()
                    }
                    if let error = error {
                        callback(["error":error.localizedDescription])
                    } else {
                        
                        if let data = data {
                            do {
                                //let outputStr  = String(data: data, encoding: String.Encoding.utf8) as String!
                                //print(outputStr)
                                let respJson = try JSONSerialization.jsonObject(with: data)
                                if respJson is [String:Any] {
                                    callback(respJson as! [String:Any])
                                } else {
                                    callback(["error":" response from server is not a dictionary"])
                                }
                            } catch {
                                callback(["error":"Error creating json from response: \(error)"])
                            }
                        }
                    }
                })
                task.resume()
            } catch {
                callback(["error":"Got error creating params body: \(error)"])
            }
        }
    }
    
    // separate an OpenWhisk qualified name (e.g. "/whisk.system/samples/date")
    // into namespace and name components
    private class func parseQualifiedName(name qualifiedName : String) -> (namespace : String, name : String) {
        var defaultNamespace = "_"
        if isIAMEnabled {
            defaultNamespace = namespace!
        }
        let delimiter = "/"
        let segments :[String] = qualifiedName.components(separatedBy: delimiter)
        
        if segments.count > 2 {
            return (segments[1], Array(segments[2..<segments.count]).joined(separator: delimiter))
        } else if segments.count == 2 {
            // case "/action" or "package/action"
            let name = qualifiedName.hasPrefix(delimiter) ? segments[1] : segments.joined(separator: delimiter)
            return (defaultNamespace, name)
        } else {
            return (defaultNamespace, segments[0])
        }
    }
    private class func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")
        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+")
    }
    
    // IAM Token handler
    private static var tokenInfo : [String:Any]! = [:]
    private static var namespace = ProcessInfo.processInfo.environment["__OW_NAMESPACE"]
    private static var iamApikey = ProcessInfo.processInfo.environment["__OW_IAM_NAMESPACE_API_KEY"]
    private static var isIAMEnabled = iamApikey != nil
    private static var  iamUrl = ProcessInfo.processInfo.environment["__OW_IAM_API_URL"] != nil
        ? ProcessInfo.processInfo.environment["__OW_IAM_API_URL"]
        : "https://iam.bluemix.net/identity/token"
    private class func sendIAMRequest(params : [String:Any]) -> [String:Any] {
        var response : [String:Any]!
        let queue = DispatchQueue.global()
        let invokeGroup = DispatchGroup()
        invokeGroup.enter()
        queue.async {
            postUrlSession(uriPath: iamUrl!, params: params, contentType: "application/x-www-form-urlencoded", method: "POST", auth: "Basic Yng6Yng=", extraHeaders: [:], group: invokeGroup) { result in
                response = result
            }
        }
        switch invokeGroup.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.success:
            break
        case DispatchTimeoutResult.timedOut:
            break
        }
        return response
    }
    private class func requestToken() {
        if isIAMEnabled {
            tokenInfo = sendIAMRequest(params: ["grant_type":"urn:ibm:params:oauth:grant-type:apikey","apikey":iamApikey!])
        }
    }
    private class func refreshToken() {
        tokenInfo = sendIAMRequest(params: ["grant_type":"refresh_token","apikey":tokenInfo["refresh_token"]!])
    }
    private class func isRefreshTokenExpired() -> Bool {
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        let expirationDate = Date(timeIntervalSince1970: Double(tokenInfo["expiration"] as! Int))
        let refreshExpirationDate = expirationDate.addingTimeInterval(sevenDays)
        let expired = refreshExpirationDate.timeIntervalSinceNow <= 0
        return expired
    }
    private class func isTokenExpired() -> Bool {
        let buffer = 0.8
        let expirationDate = Date(timeIntervalSince1970: Double(tokenInfo["expiration"] as! Int))
        let refreshDate = expirationDate.addingTimeInterval(-1.0 * (1.0 - buffer) * Double(tokenInfo["expires_in"] as! Int))
        let expired = refreshDate.timeIntervalSinceNow <= 0
        return expired
    }
    private class func getToken() -> String {
        guard isIAMEnabled else {
            return ""
        }
        let tokenExists = tokenInfo.keys.contains("access_token")
        if !tokenExists || isRefreshTokenExpired() {
            requestToken()
        } else if isTokenExpired() {
            refreshToken()
        }
        return tokenInfo["access_token"] as! String
    }
    private class func getAuthHeader() -> String {
        let token = getToken()
        return "Bearer \(token)"
    }
}



