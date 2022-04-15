import Foundation
import SoraFoundation

final class ExportSeedPresenter {
    weak var view: ExportGenericViewProtocol?
    var wireframe: ExportSeedWireframeProtocol!
    var interactor: ExportSeedInteractorInputProtocol!

    let flow: ExportFlow
    let localizationManager: LocalizationManager

    private(set) var exportViewModels: [ExportStringViewModel]?

    init(flow: ExportFlow, localizationManager: LocalizationManager) {
        self.flow = flow
        self.localizationManager = localizationManager
    }

    func didTapStringExport(_ value: String?) {
        guard let value = value else {
            return
        }

        let locale = localizationManager.selectedLocale

        let title = R.string.localizable.accountExportWarningTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.accountExportWarningMessage(preferredLanguages: locale.rLanguages)

        let exportTitle = R.string.localizable.accountExportAction(preferredLanguages: locale.rLanguages)
        let exportAction = AlertPresentableAction(title: exportTitle) { [weak self] in
            self?.share(value)
        }

        let cancelTitle = R.string.localizable.commonCancel(preferredLanguages: locale.rLanguages)
        let viewModel = AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [exportAction],
            closeAction: cancelTitle
        )

        wireframe.present(viewModel: viewModel, style: .alert, from: view)
    }

    func share(_ value: String) {
        wireframe.share(source: TextSharingSource(message: value), from: view) { [weak self] completed in
            if completed {
                self?.wireframe.close(view: self?.view)
            }
        }
    }
}

extension ExportSeedPresenter: ExportGenericPresenterProtocol {
    func didLoadView() {
        let locale = localizationManager.selectedLocale

        let title = R.string.localizable.accountExportWarningTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.accountExportWarningMessage(preferredLanguages: locale.rLanguages)

        let exportTitle = R.string.localizable.commonCancel(preferredLanguages: locale.rLanguages)
        let exportAction = AlertPresentableAction(title: exportTitle) { [weak self] in
            self?.wireframe.back(view: self?.view)
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

    func setup() {
        switch flow {
        case let .single(chain, address):
            interactor.fetchExportDataForAddress(address, chain: chain)
        case let .multiple(wallet, _):
            interactor.fetchExportDataForWallet(wallet, accounts: flow.exportingAccounts)
        }
    }
}

extension ExportSeedPresenter: ExportSeedInteractorOutputProtocol {
    func didReceive(exportData: [ExportSeedData]) {
        let viewModels = exportData.compactMap { seedData in
            ExportStringViewModel(
                option: .seed,
                chain: seedData.chain,
                cryptoType: seedData.chain.isEthereumBased ? nil : seedData.cryptoType,
                derivationPath: seedData.derivationPath,
                data: seedData.seed.toHex(includePrefix: true),
                ethereumBased: seedData.chain.isEthereumBased
            )
        }

        exportViewModels = viewModels

        let multipleExportViewModel = MultiExportViewModel(viewModels: viewModels)

        view?.set(viewModel: multipleExportViewModel)
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
