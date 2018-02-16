import SwiftyRequest
import Dispatch
import Foundation
import LanguageTranslatorV2

func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["error":"Action failed"]
    let echoURL = "http://httpbin.org/post"
    
    // setting body data to {"Data":"string"}
    let origJson: [String: Any] = args
    guard let data = try? JSONSerialization.data(withJSONObject: origJson, options: []) else {
        return ["error": "Could not encode json"]
    }
    let request = RestRequest(method: .post, url: echoURL)
    request.messageBody = data
    let semaphore = DispatchSemaphore(value: 0)
    //sending with query ?hour=9
    request.responseData(queryItems: [URLQueryItem(name: "hour", value: "9")]) { response in
        switch response.result {
        case .success(let retval):
            if let json = try? JSONSerialization.jsonObject(with: retval, options: []) as! [String:Any]  {
                resp = json
            } else {
                resp = ["error":"Response from server is not a dictionary like"]
            }
        case .failure(let error):
            resp = ["error":"Failed to get data response: \(error)"]
        }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .distantFuture)
    return resp
}

func main2(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["translation":"To be translated"]
    let dispatchGroup = DispatchGroup()
    let username = args["username"] as! String
    let password = args["password"] as! String
    let languageTranslator = LanguageTranslator(username: username, password: password)
    
    let failure = { (error: Error) in print(error) }
    dispatchGroup.enter()
    languageTranslator.translate("Hello", from: "en", to: "es", failure: failure) {translation in
        print(translation)
        resp["translation"] = translation.translations[0].translation as String
        dispatchGroup.leave()
    }
    dispatchGroup.wait(timeout: .distantFuture)
    return resp
}
let params = ["username":"5f7b2061-ca43-4713-b11d-e79e99940826","password":"FgBTfQLicFdj"]
//let r = main(args:["message":"serverless"])
let r = main2(args:params)
print(r)

