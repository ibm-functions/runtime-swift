import Dispatch
import LanguageTranslatorV2
func main(args: [String:Any]) -> [String:Any] {
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