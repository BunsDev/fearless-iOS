import Foundation
import SoraFoundation

final class AccountExportPasswordPresenter {
    weak var view: AccountExportPasswordViewProtocol?
    var wireframe: AccountExportPasswordWireframeProtocol!
    var interactor: AccountExportPasswordInteractorInputProtocol!

    private let passwordInputViewModel = {
        InputViewModel(inputHandler: InputHandler(predicate: NSPredicate.notEmpty))
    }()

    private let confirmationViewModel = {
        InputViewModel(inputHandler: InputHandler(predicate: NSPredicate.notEmpty))
    }()

    let localizationManager: LocalizationManagerProtocol

    let flow: ExportFlow

    init(flow: ExportFlow, localizationManager: LocalizationManagerProtocol) {
        self.flow = flow
        self.localizationManager = localizationManager
    }
}

extension AccountExportPasswordPresenter: AccountExportPasswordPresenterProtocol {
    func setup() {
        view?.setPasswordInputViewModel(passwordInputViewModel)
        view?.setPasswordConfirmationViewModel(confirmationViewModel)

        let locale = localizationManager.selectedLocale

        let title = R.string.localizable.accountExportWarningTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.accountExportWarningMessage(preferredLanguages: locale.rLanguages)

        let exportTitle = R.string.localizable.commonCancel(preferredLanguages: locale.rLanguages)
        let exportAction = AlertPresentableAction(title: exportTitle) { [weak self] in
            self?.wireframe.back(from: self?.view)
        }

        let cancelTitle = R.string.localizable.commonProceed(preferredLanguages: locale.rLanguages)
        let cancelAction = AlertPresentableAction(title: cancelTitle) {}
        let viewModel = AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [exportAction, cancelAction],
            closeAction: nil
        )

        wireframe.present(viewModel: viewModel, style: .alert, from: view)
    }

    func proceed() {
        let password = passwordInputViewModel.inputHandler.normalizedValue

        guard password == confirmationViewModel.inputHandler.normalizedValue else {
            view?.set(error: .passwordMismatch)
            return
        }

        switch flow {
        case let .single(chain, address, wallet):
            interactor.exportAccount(
                address: address,
                password: password,
                chain: chain,
                wallet: wallet
            )
        case let .multiple(wallet, _):
            interactor.exportWallet(
                wallet: wallet,
                accounts: flow.exportingAccounts,
                password: password
            )
        }
    }
}

extension AccountExportPasswordPresenter: AccountExportPasswordInteractorOutputProtocol {
    func didExport(jsons: [RestoreJson]) {
        wireframe.showJSONExport(jsons, flow: flow, from: view)
    }

    func didReceive(error: Error) {
        if !wireframe.present(error: error, from: view, locale: localizationManager.selectedLocale) {
            _ = wireframe.present(
                error: CommonError.undefined,
                from: view,
                locale: localizationManager.selectedLocale
            )
        }
    }
}
