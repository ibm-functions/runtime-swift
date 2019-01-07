import Dispatch
import LanguageTranslatorV3
func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["translation":"To be translated"]
    let dispatchGroup = DispatchGroup()
    let username = args["username"] as! String
    let password = args["password"] as! String
    let languageTranslator = LanguageTranslator(username: username, password: password, version: "2018-09-16")


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
        resp["translation"] = translation.translations.first?.translationOutput as! String
        dispatchGroup.leave()

    }
    _ = dispatchGroup.wait(timeout: .distantFuture)
    return resp

}