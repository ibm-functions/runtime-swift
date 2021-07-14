import Dispatch
import LanguageTranslatorV3
func main(args: [String:Any]) -> [String:Any] {
    print("Start of main...")
    var resp :[String:String] = ["translation":"To be translated"]
    let _whisk_semaphore = DispatchSemaphore(value: 0)
    print("Get username...")
    let username = args["username"] as! String
    print("Start of password/apikey...")
    let password = args["password"] as! String
    print("Get URL...")
    let url = args["url"] as! String
    print("Create authenticator...")
    let authenticator = WatsonIAMAuthenticator(apiKey: password)

    print("LanguageTranslator start creation...")

    guard let languageTranslator = try? LanguageTranslator(version: "2018-09-16", authenticator: authenticator) else {
        return ["error": "Could not create languageTranslator!"]
    }

    print("LanguageTranslator created.")

    languageTranslator.serviceURL = url

    languageTranslator.translate(text: ["Hello"], source: "en", target: "it" ) { (response, error) in
        if let error = error {
            print(error)
            return
        }
        guard let translation = response?.result else {
            print("missing response")
            return
        }
        print(translation)
        resp["translation"] = (translation.translations.first?.translation)!
        _whisk_semaphore.signal()

    }
    _ = _whisk_semaphore.wait(timeout: .distantFuture)
    return resp

}