import UIKit

enum ProfileOptionAccessoryType {
    case arrow
    case switcher(Bool)
}

protocol ProfileOptionViewModelProtocol {
    var icon: UIImage? { get }
    var title: String { get }
    var accessoryTitle: String? { get }
    var accessoryType: ProfileOptionAccessoryType { get }
}

struct ProfileOptionViewModel: ProfileOptionViewModelProtocol {
    let title: String
    let icon: UIImage?
    let accessoryTitle: String?
    let accessoryType: ProfileOptionAccessoryType
}
