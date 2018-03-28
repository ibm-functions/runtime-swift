print("debug1")
import Foundation
import LanguageTranslatorV2


struct Input: Codable {
    let username: String
    let password: String
    let url: String?
}
struct Output: Codable {
    let translation: String
}
func main(param: Input, completion: @escaping (Output?, Error?) -> Void) -> Void {
    let languageTranslator = LanguageTranslator(username: param.username , password: param.password)
    let request = TranslateRequest(text: ["Hello"], source: "en", target: "es")
    let failure = {(error: Error) in
        print(" calling translate Error")
        print(error)
        completion(nil, error)
    }

    let _ = languageTranslator.translate(
       request: request,
       failure: failure) {translation in
        print(translation)
        let result = Output(translation: translation.translations.first?.translationOutput as! String)
        print(result)
        completion(result, nil)

    }

}
