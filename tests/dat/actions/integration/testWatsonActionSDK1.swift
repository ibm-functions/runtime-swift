import Dispatch
import LanguageTranslatorV3
func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:String] = ["translation":"To be translated"]
    let _whisk_semaphore = DispatchSemaphore(value: 0)
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
        resp["translation"] = (translation.translations.first?.translationOutput)!
        _whisk_semaphore.signal()

    }
    _ = _whisk_semaphore.wait(timeout: .distantFuture)
    return resp

}