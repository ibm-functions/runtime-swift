import Dispatch
import LanguageTranslatorV3
func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["translation":"To be translated"]
    let dispatchGroup = DispatchGroup()
    let username = args["username"] as! String
    let password = args["password"] as! String
    let authenticator = WatsonIAMAuthenticator(apiKey: password)
//    let languageTranslator = LanguageTranslator(username: username, password: password, version: "2018-09-16")
    let languageTranslator = LanguageTranslator(version: "2018-09-16", authenticator: authenticator)
//    languageTranslator.serviceURL = 
    let request = TranslateRequest(text: ["Hello"], source: "en", target: "it")

    let failure = { (error: Error) in print(error) }
    dispatchGroup.enter()
    languageTranslator.translate(request: request, failure: failure) {translation in
        print(translation)
        resp["translation"] = translation.translations.first?.translationOutput as! String
        dispatchGroup.leave()
    }
    _ = dispatchGroup.wait(timeout: .distantFuture)
    return resp
}