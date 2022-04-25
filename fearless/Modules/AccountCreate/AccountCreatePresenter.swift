import UIKit
import IrohaCrypto
import SoraFoundation

final class AccountCreatePresenter {
    static let maxEthereumDerivationPathLength: Int = 15

    weak var view: AccountCreateViewProtocol?
    var wireframe: AccountCreateWireframeProtocol!
    var interactor: AccountCreateInteractorInputProtocol!

    let usernameSetup: UsernameSetupModel

    private var mnemonic: [String]?
    private var selectedCryptoType: CryptoType = .sr25519

    private var substrateDerivationPathViewModel: InputViewModelProtocol?
    private var ethereumDerivationPathViewModel: InputViewModelProtocol?

    init(usernameSetup: UsernameSetupModel) {
        self.usernameSetup = usernameSetup
    }

    private func applySubstrateCryptoTypeViewModel() {
        let viewModel = createCryptoTypeViewModel(selectedCryptoType)
        view?.setSelectedSubstrateCrypto(model: viewModel)
    }

    private func applyEthereumCryptoTypeViewModel() {
        let viewModel = createCryptoTypeViewModel(.ecdsa)
        view?.setEthereumCrypto(model: viewModel)
    }

    private func createCryptoTypeViewModel(_ cryptoType: CryptoType) -> TitleWithSubtitleViewModel {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        return TitleWithSubtitleViewModel(
            title: cryptoType.titleForLocale(locale),
            subtitle: cryptoType.subtitleForLocale(locale)
        )
    }

    private func applySubstrateDerivationPathViewModel() {
        let viewModel = createViewModel(
            for: selectedCryptoType,
            isEthereum: false
        )
        substrateDerivationPathViewModel = viewModel

        view?.bind(substrateViewModel: viewModel)
        view?.didValidateSubstrateDerivationPath(.none)
    }

    private func applyEthereumDerivationPathViewModel() {
        let viewModel = createViewModel(
            for: .ecdsa,
            isEthereum: true,
            processor: EthereumDerivationPathProcessor(),
            maxLength: AccountCreatePresenter.maxEthereumDerivationPathLength
        )
        ethereumDerivationPathViewModel = viewModel

        view?.bind(ethereumViewModel: viewModel)
        view?.didValidateEthereumDerivationPath(.none)
    }

    private func createViewModel(
        for cryptoType: CryptoType,
        isEthereum: Bool,
        processor: TextProcessing? = nil,
        maxLength: Int? = nil
    ) -> InputViewModel {
        let predicate: NSPredicate?
        let placeholder: String

        if isEthereum {
            predicate = nil
            placeholder = DerivationPathConstants.defaultEthereum
        } else {
            switch cryptoType {
            case .sr25519:
                predicate = NSPredicate.deriviationPathHardSoftPassword
                placeholder = DerivationPathConstants.hardSoftPasswordPlaceholder
            case .ed25519, .ecdsa:
                predicate = NSPredicate.deriviationPathHardPassword
                placeholder = DerivationPathConstants.hardPasswordPlaceholder
            }
        }

        let inputHandling = InputHandler(
            maxLength: maxLength ?? Int.max,
            predicate: predicate,
            processor: processor
        )
        return InputViewModel(inputHandler: inputHandling, placeholder: placeholder)
    }

    private func presentDerivationPathError(_ cryptoType: CryptoType) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        // TODO: Check correctness
        switch cryptoType.utilsType {
        case .sr25519:
            _ = wireframe.present(
                error: AccountCreationError.invalidDerivationHardSoftPassword,
                from: view,
                locale: locale
            )
        case .ed25519, .ecdsa:
            _ = wireframe.present(
                error: AccountCreationError.invalidDerivationHardPassword,
                from: view,
                locale: locale
            )
        }
    }
}

extension AccountCreatePresenter: AccountCreatePresenterProtocol {
    func setup() {
        interactor.setup()

        applySubstrateCryptoTypeViewModel()
        applyEthereumCryptoTypeViewModel()
        applySubstrateDerivationPathViewModel()
        applyEthereumDerivationPathViewModel()
    }

    func activateInfo() {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        let message = R.string.localizable.accountCreationInfo(preferredLanguages: locale.rLanguages)
        let title = R.string.localizable.commonInfo(preferredLanguages: locale.rLanguages)
        wireframe.present(
            message: message,
            title: title,
            closeAction: R.string.localizable.commonClose(preferredLanguages: locale.rLanguages),
            from: view
        )
    }

    func validateSubstrate() {
        guard let viewModel = substrateDerivationPathViewModel else {
            return
        }

        if viewModel.inputHandler.completed {
            view?.didValidateSubstrateDerivationPath(.valid)
        } else {
            view?.didValidateSubstrateDerivationPath(.invalid)
            presentDerivationPathError(selectedCryptoType)
        }
    }

    func validateEthereum() {
        guard let viewModel = ethereumDerivationPathViewModel else {
            return
        }

        if viewModel.inputHandler.completed {
            view?.didValidateEthereumDerivationPath(.valid)
        } else {
            view?.didValidateEthereumDerivationPath(.invalid)
            presentDerivationPathError(.ecdsa)
        }
    }

    func selectSubstrateCryptoType() {
        wireframe.presentCryptoTypeSelection(
            from: view,
            availableTypes: CryptoType.allCases,
            selectedType: selectedCryptoType,
            delegate: self,
            context: nil
        )
    }

    func proceed() {
        guard
            let mnemonic = mnemonic,
            let substrateViewModel = substrateDerivationPathViewModel,
            let ethereumViewModel = ethereumDerivationPathViewModel
        else {
            return
        }

        guard substrateViewModel.inputHandler.completed else {
            view?.didValidateSubstrateDerivationPath(.invalid)
            presentDerivationPathError(selectedCryptoType)
            return
        }

        guard ethereumViewModel.inputHandler.completed else {
            view?.didValidateEthereumDerivationPath(.invalid)
            presentDerivationPathError(.ecdsa)
            return
        }

        let request = MetaAccountCreationRequest(
            username: usernameSetup.username,
            substrateDerivationPath: substrateViewModel.inputHandler.value,
            substrateCryptoType: selectedCryptoType,
            ethereumDerivationPath: ethereumViewModel.inputHandler.value
        )

        wireframe.confirm(
            from: view,
            request: request,
            mnemonic: mnemonic
        )
    }
}

extension AccountCreatePresenter: AccountCreateInteractorOutputProtocol {
    func didReceive(mnemonic: [String]) {
        view?.set(mnemonic: mnemonic)
        self.mnemonic = mnemonic
    }

    func didReceiveMnemonicGeneration(error: Error) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        guard !wireframe.present(error: error, from: view, locale: locale) else {
            return
        }

        _ = wireframe.present(
            error: CommonError.undefined,
            from: view,
            locale: locale
        )
    }
}

extension AccountCreatePresenter: ModalPickerViewControllerDelegate {
    func modalPickerDidSelectModelAtIndex(_ index: Int, context _: AnyObject?) {
        selectedCryptoType = CryptoType.allCases[index]

        applySubstrateCryptoTypeViewModel()
        applySubstrateDerivationPathViewModel()

        view?.didCompleteCryptoTypeSelection()
    }

    func modalPickerDidCancel(context _: AnyObject?) {
        view?.didCompleteCryptoTypeSelection()
    }
}

extension AccountCreatePresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            applySubstrateCryptoTypeViewModel()
            applyEthereumCryptoTypeViewModel()
        }
    }
}
