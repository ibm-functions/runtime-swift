print("debug1")
import Foundation
import LanguageTranslatorV3


struct Input: Codable {
    let username: String
    let password: String
    let url: String
}
struct Output: Codable {
    let translation: String
}

func main(param: Input, completion: @escaping (Output?, Error?) -> Void) -> Void {

    print("Start of main...")

    let authenticator = WatsonIAMAuthenticator(apiKey: param.password)

    print("LanguageTranslator start creation...")

    guard let languageTranslator = try? LanguageTranslator(version: "2018-09-16", authenticator: authenticator) else {
        print("error: Could not create languageTranslator!")
        return
    }

    print("LanguageTranslator created.")

    languageTranslator.serviceURL = param.url 
    languageTranslator.translate(text: ["Hello"], source: "en", target: "it") { (response, error) in
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
        completion(result, nil)
    }

}