import Foundation

struct AcalaContributeData: Decodable {
    let result: Bool
    let address: String
    let email: String?
    let referral: String?
    let amount: String
    let signature: String
}
