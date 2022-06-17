import Foundation
import FearlessUtils

protocol AccountViewModelFactoryProtocol {
    func buildViewModel(
        title: String,
        address: String,
        locale: Locale
    ) -> AccountViewModel

    func buildViewModel(
        title: String,
        address: String,
        name: String?,
        locale: Locale
    ) -> AccountViewModel
}

class AccountViewModelFactory: AccountViewModelFactoryProtocol {
    private let iconGenerator: IconGenerating

    init(iconGenerator: IconGenerating) {
        self.iconGenerator = iconGenerator
    }

    func buildViewModel(
        title: String,
        address: String,
        locale _: Locale
    ) -> AccountViewModel {
        AccountViewModel(
            title: title,
            name: address,
            icon: try? iconGenerator.generateFromAddress(address)
        )
    }

    func buildViewModel(
        title: String,
        address: String,
        name: String?,
        locale _: Locale
    ) -> AccountViewModel {
        AccountViewModel(
            title: title,
            name: name ?? address,
            icon: try? iconGenerator.generateFromAddress(address)
        )
    }
}
