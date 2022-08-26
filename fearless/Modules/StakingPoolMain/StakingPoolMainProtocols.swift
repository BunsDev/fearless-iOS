import Foundation
import SoraFoundation

typealias StakingPoolMainModuleCreationResult = (view: StakingPoolMainViewInput, input: StakingPoolMainModuleInput)

protocol StakingPoolMainViewInput: ControllerBackedProtocol {
    func didReceiveBalanceViewModel(_ balanceViewModel: BalanceViewModelProtocol)
    func didReceiveChainAsset(_ chainAsset: ChainAsset)
    func didReceiveEstimationViewModel(_ viewModel: StakingEstimationViewModel)
    func didReceiveNetworkInfoViewModels(_ viewModels: [LocalizableResource<NetworkInfoContentViewModel>])
    func didReceiveNominatorStateViewModel(_ viewModel: LocalizableResource<NominationViewModelProtocol>?)
}

protocol StakingPoolMainViewOutput: AnyObject {
    func didLoad(view: StakingPoolMainViewInput)
    func didTapSelectAsset()
    func didTapStartStaking()
    func performRewardInfoAction()
    func updateAmount(_ newValue: Decimal)
    func selectAmountPercentage(_ percentage: Float)
    func networkInfoViewDidChangeExpansion(isExpanded: Bool)
}

protocol StakingPoolMainInteractorInput: AnyObject {
    func setup(with output: StakingPoolMainInteractorOutput)
    func updateWithChainAsset(_ chainAsset: ChainAsset)
    func save(chainAsset: ChainAsset)
    func saveNetworkInfoViewExpansion(isExpanded: Bool)
}

protocol StakingPoolMainInteractorOutput: AnyObject {
    func didReceive(accountInfo: AccountInfo?)
    func didReceive(balanceError: Error)
    func didReceive(chainAsset: ChainAsset)
    func didReceive(rewardCalculatorEngine: RewardCalculatorEngineProtocol?)
    func didReceive(priceData: PriceData?)
    func didReceive(priceError: Error)
    func didReceive(wallet: MetaAccountModel)
    func didReceive(networkInfo: StakingPoolNetworkInfo)
    func didReceive(networkInfoError: Error)
    func didReceive(stakeInfo: StakingPoolMember?)
    func didReceive(stakeInfoError: Error)
    func didReceive(era: EraIndex)
    func didReceive(eraStakersInfo: EraStakersInfo)
    func didReceive(eraCountdownResult: Result<EraCountdown, Error>)
    func didReceive(eraStakersInfoError: Error)
}

protocol StakingPoolMainRouterInput: AnyObject {
    func showChainAssetSelection(
        from view: StakingPoolMainViewInput?,
        type: AssetSelectionStakingType,
        delegate: AssetSelectionDelegate
    )

    func showRewardDetails(
        from view: ControllerBackedProtocol?,
        maxReward: (title: String, amount: Decimal),
        avgReward: (title: String, amount: Decimal)
    )

    func showSetupAmount(
        from view: ControllerBackedProtocol?,
        amount _: Decimal?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel
    )
}

protocol StakingPoolMainModuleInput: AnyObject {}

protocol StakingPoolMainModuleOutput: AnyObject {}
