import Foundation
import CommonWallet
import SoraFoundation

final class WalletTransactionHistoryPresenter {
    weak var view: WalletTransactionHistoryViewProtocol?
    let wireframe: WalletTransactionHistoryWireframeProtocol
    let interactor: WalletTransactionHistoryInteractorInputProtocol
    let viewModelFactory: WalletTransactionHistoryViewModelFactoryProtocol
    let chain: ChainModel
    let asset: AssetModel

    private(set) var viewModels: [WalletTransactionHistorySection] = []

    init(
        interactor: WalletTransactionHistoryInteractorInputProtocol,
        wireframe: WalletTransactionHistoryWireframeProtocol,
        viewModelFactory: WalletTransactionHistoryViewModelFactoryProtocol,
        chain: ChainModel,
        asset: AssetModel
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.viewModelFactory = viewModelFactory
        self.asset = asset
        self.chain = chain
    }
}

extension WalletTransactionHistoryPresenter: WalletTransactionHistoryPresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func loadNext() -> Bool {
        interactor.loadNext()
    }

    func didSelect(viewModel: WalletTransactionHistoryCellViewModel) {
        wireframe.showTransactionDetails(from: view, transaction: viewModel.transaction, chain: chain, asset: asset, selectedAccount: SelectedWalletSettings.shared.value)
    }
}

extension WalletTransactionHistoryPresenter: WalletTransactionHistoryInteractorOutputProtocol {
    func didReceive(
        pageData: AssetTransactionPageData,
        reload: Bool
    ) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        var viewModels = reload ? [] : self.viewModels
        let viewChanges = try? viewModelFactory.merge(
            newItems: pageData.transactions,
            into: &viewModels,
            locale: locale
        )

        guard let viewChanges = viewChanges else {
            return
        }

        self.viewModels = viewModels

        let viewModel = WalletTransactionHistoryViewModel(sections: viewModels, lastChanges: viewChanges)

        let state: WalletTransactionHistoryViewState = reload ? .reloaded(viewModel: viewModel) : .loaded(viewModel: viewModel)
        view?.didReceive(state: state)
    }
}

extension WalletTransactionHistoryPresenter: Localizable {
    func applyLocalization() {}
}