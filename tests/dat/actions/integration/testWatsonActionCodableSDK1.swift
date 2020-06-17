print("debug1")
import Foundation
import LanguageTranslatorV3


struct Input: Codable {
    let username: String
    let password: String
    let url: String?
}
struct Output: Codable {
    let translation: String
}
func main(param: Input, completion: @escaping (Output?, Error?) -> Void) -> Void {
    let languageTranslator = LanguageTranslator(username: param.username , password: param.password, version: "2018-09-16")
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
        let result = Output(translation: (translation.translations.first?.translationOutput)!)
        print(result)
        completion(result, nil)
    }

}
