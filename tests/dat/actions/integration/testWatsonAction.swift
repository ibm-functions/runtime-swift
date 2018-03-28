import Dispatch
import LanguageTranslatorV2
func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["translation":"To be translated"]
    let dispatchGroup = DispatchGroup()
    let username = args["username"] as! String
    let password = args["password"] as! String
    let languageTranslator = LanguageTranslator(username: username, password: password)
    let request = TranslateRequest(text: ["Hello"], source: "en", target: "es")
    
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