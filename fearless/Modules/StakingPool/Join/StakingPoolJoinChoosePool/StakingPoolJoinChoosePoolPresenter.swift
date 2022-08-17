import Foundation
import SoraFoundation

final class StakingPoolJoinChoosePoolPresenter {
    // MARK: Private properties

    private weak var view: StakingPoolJoinChoosePoolViewInput?
    private let router: StakingPoolJoinChoosePoolRouterInput
    private let interactor: StakingPoolJoinChoosePoolInteractorInput
    private let viewModelFactory: StakingPoolJoinChoosePoolViewModelFactoryProtocol
    private let inputAmount: Decimal
    private let chainAsset: ChainAsset
    private let wallet: MetaAccountModel

    private var selectedPoolId: String?
    private var pools: [StakingPool]?

    // MARK: - Constructors

    init(
        interactor: StakingPoolJoinChoosePoolInteractorInput,
        router: StakingPoolJoinChoosePoolRouterInput,
        localizationManager: LocalizationManagerProtocol,
        viewModelFactory: StakingPoolJoinChoosePoolViewModelFactoryProtocol,
        inputAmount: Decimal,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel
    ) {
        self.interactor = interactor
        self.router = router
        self.viewModelFactory = viewModelFactory
        self.inputAmount = inputAmount
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.localizationManager = localizationManager
    }

    // MARK: - Private methods

    private func provideViewModel() {
        let cellViewModels = viewModelFactory.buildCellViewModels(
            pools: pools,
            locale: selectedLocale,
            cellsDelegate: self,
            selectedPoolId: selectedPoolId
        )

        view?.didReceive(cellViewModels: cellViewModels)
    }
}

// MARK: - StakingPoolJoinChoosePoolViewOutput

extension StakingPoolJoinChoosePoolPresenter: StakingPoolJoinChoosePoolViewOutput {
    func didLoad(view: StakingPoolJoinChoosePoolViewInput) {
        self.view = view
        interactor.setup(with: self)

        view.didReceive(locale: selectedLocale)

        view.didStartLoading()
    }

    func didTapBackButton() {
        router.dismiss(view: view)
    }

    func didTapContinueButton() {
        guard let pool = pools?.first(where: { $0.id == selectedPoolId }) else {
            return
        }

        router.presentConfirm(
            from: view,
            chainAsset: chainAsset,
            wallet: wallet,
            inputAmount: inputAmount,
            selectedPool: pool
        )
    }
}

// MARK: - StakingPoolJoinChoosePoolInteractorOutput

extension StakingPoolJoinChoosePoolPresenter: StakingPoolJoinChoosePoolInteractorOutput {
    func didReceivePools(_ pools: [StakingPool]?) {
        self.pools = pools
        provideViewModel()

        view?.didStopLoading()
    }

    func didReceiveError(_: Error) {}
}

// MARK: - Localizable

extension StakingPoolJoinChoosePoolPresenter: Localizable {
    func applyLocalization() {
        view?.didReceive(locale: selectedLocale)
    }
}

extension StakingPoolJoinChoosePoolPresenter: StakingPoolJoinChoosePoolModuleInput {}

extension StakingPoolJoinChoosePoolPresenter: StakingPoolListTableCellModelDelegate {
    func selectPool(poolId: String) {
        selectedPoolId = poolId
        provideViewModel()
    }

    func showPoolInfo(poolId _: String) {}
}