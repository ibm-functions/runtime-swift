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
print("debug2")
func main(param: Input, completion: @escaping (Output?, Error?) -> Void) -> Void {
    print("debug3")
    let languageTranslator = LanguageTranslator(username: param.username , password: param.password)
        let failure = {(error: Error) in
            print(" calling translate Error")
            print(error)
            completion(nil, error)
        }
    print("debug4 \(param.username) \(param.password)")

    let _ = languageTranslator.translate(
        _: "Hello",
       from: "en",
       to: "es",
       failure: failure) {translation in
        //print(translation)
        print("debug5")
        let result = Output(translation: translation.translations[0].translation as String)
        print(result)
        completion(result, nil)

    }

}
