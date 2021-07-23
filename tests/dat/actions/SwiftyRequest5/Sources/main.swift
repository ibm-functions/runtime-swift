import Dispatch
import Foundation
import LanguageTranslatorV3

func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["error":"Action failed"]
    var echoURL:String
    if let echoUrlValue = args["url"]  {
        echoURL = echoUrlValue as! String
    } else {
        echoURL = "https://httpbin.org/post"
    }

    // setting body data to {"Data":"string"}
    let origJson: [String: Any] = args
    guard let data = try? JSONSerialization.data(withJSONObject: origJson, options: []) else {
        return ["error": "Could not encode json"]
    }
    let url = URL(string: echoURL)
    var request = URLRequest(url: url)   
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.httpMethod = "POST"
    request.httpBody = data 
    
    let session = URLSession.shared

    let task = session.dataTask(with: request, completionHandler: { data, response, error in

        guard error == nil else {
            completion(nil, error)
            return
        }

        guard let data = data else {
            completion(nil, NSError(domain: "dataNilError", code: -100001, userInfo: nil))
            return
        }

        do {
            //create json object from data
            guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                completion(nil, NSError(domain: "invalidJSONTypeError", code: -100009, userInfo: nil))
                return
            }
            print(json)
            resp = json
        } catch let error {
            print(error.localizedDescription)
        }
    })

    task.resume()
    return resp
}

func main2(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["translation":"To be translated"]
    let dispatchGroup = DispatchGroup()

    let username = args["url"] as! String
    let password = args["password"] as! String

    let authenticator = WatsonIAMAuthenticator(apiKey: password)
    guard let languageTranslator = try? LanguageTranslator(version: "2018-09-16", authenticator: authenticator) else {
        print("error: Could not create languageTranslator!")
        return
    }

    languageTranslator.serviceURL = url 
    languageTranslator.translate(text: ["Hello"], source: "en", target: "es") { (response, error) in
        if let error = error {
            print(error)
            return
        }
        guard let translation = response?.result else {
            print("missing response")
            return
        }
        print(translation)
        let result = Output(translation: (translation.translations.first?.translation)!)
        print(result)
        resp["translation"]= result
        completion(result, nil)
    }
    
    return resp
}


