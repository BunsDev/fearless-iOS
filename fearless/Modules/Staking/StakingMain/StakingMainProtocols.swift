import Foundation
import SoraFoundation
import CommonWallet
import BigInt

protocol StakingMainViewProtocol: ControllerBackedProtocol, Localizable {
    func didReceive(viewModel: StakingMainViewModel)
    func didRecieveNetworkStakingInfo(viewModel: LocalizableResource<NetworkStakingInfoViewModelProtocol>?)
    func didReceiveStakingState(viewModel: StakingViewState)
    func expandNetworkInfoView(_ isExpanded: Bool)
    func didReceive(stakingEstimationViewModel: StakingEstimationViewModel)
}

protocol StakingMainPresenterProtocol: AnyObject {
    func setup()
    func performRefreshAction()
    func viewWillAppear()
    func performAssetSelection()
    func performMainAction()
    func performParachainMainAction(for delegation: ParachainStakingDelegationInfo)
    func performAccountAction()
    func performManageStakingAction()
    func performParachainManageStakingAction(for delegation: ParachainStakingDelegationInfo)
    func performNominationStatusAction()
    func performValidationStatusAction()
    func performDelegationStatusAction()
    func performRewardInfoAction()
    func performChangeValidatorsAction()
    func performSetupValidatorsForBondedAction()
    func performBondMoreAction()
    func performRedeemAction()
    func performAnalyticsAction()
    func updateAmount(_ newValue: Decimal)
    func selectAmountPercentage(_ percentage: Float)
    func selectStory(at index: Int)
    func networkInfoViewDidChangeExpansion(isExpanded: Bool)
}

protocol StakingMainInteractorInputProtocol: AnyObject {
    func setup()
    func refresh()
    func saveNetworkInfoViewExpansion(isExpanded: Bool)
    func save(chainAsset: ChainAsset)
    func updatePrices()
}

protocol StakingMainInteractorOutputProtocol: AnyObject {
    func didReceive(selectedAddress: String)
    func didReceive(price: PriceData?)
    func didReceive(priceError: Error)
    func didReceive(totalReward: TotalRewardItem)
    func didReceive(totalReward: Error)
    func didReceive(accountInfo: AccountInfo?)
    func didReceive(balanceError: Error)
    func didReceive(calculator: RewardCalculatorEngineProtocol)
    func didReceive(calculatorError: Error)
    func didReceive(stashItem: StashItem?)
    func didReceive(stashItemError: Error)
    func didReceive(ledgerInfo: StakingLedger?)
    func didReceive(ledgerInfoError: Error)
    func didReceive(nomination: Nomination?)
    func didReceive(nominationError: Error)
    func didReceive(validatorPrefs: ValidatorPrefs?)
    func didReceive(validatorError: Error)
    func didReceive(eraStakersInfo: EraStakersInfo)
    func didReceive(eraStakersInfoError: Error)
    func didReceive(networkStakingInfo: NetworkStakingInfo)
    func didReceive(networkStakingInfoError: Error)
    func didReceive(payee: RewardDestinationArg?)
    func didReceive(payeeError: Error)
    func didReceive(newChainAsset: ChainAsset)
    func didReceieve(subqueryRewards: Result<[SubqueryRewardItemData]?, Error>, period: AnalyticsPeriod)
    func didReceiveMinNominatorBond(result: Result<BigUInt?, Error>)
    func didReceiveCounterForNominators(result: Result<UInt32?, Error>)
    func didReceiveMaxNominatorsCount(result: Result<UInt32?, Error>)
    func didReceive(eraCountdownResult: Result<EraCountdown, Error>)

    func didReceiveMaxNominatorsPerValidator(result: Result<UInt32, Error>)

    func didReceiveControllerAccount(result: Result<ChainAccountResponse?, Error>)
    func networkInfoViewExpansion(isExpanded: Bool)

//    Parachain

    func didReceive(delegationInfos: [ParachainStakingDelegationInfo]?)
}

protocol StakingMainWireframeProtocol: AlertPresentable, ErrorPresentable, StakingErrorPresentable {
    func showSetupAmount(
        from view: StakingMainViewProtocol?,
        amount: Decimal?,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showManageStaking(
        from view: StakingMainViewProtocol?,
        items: [StakingManageOption],
        delegate: ModalPickerViewControllerDelegate?,
        context: AnyObject?
    )

    func proceedToSelectValidatorsStart(
        from view: StakingMainViewProtocol?,
        existingBonding: ExistingBonding,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showStories(
        from view: ControllerBackedProtocol?,
        startingFrom index: Int
    )

    func showRewardDetails(from view: ControllerBackedProtocol?, maxReward: Decimal, avgReward: Decimal)

    func showRewardPayoutsForNominator(
        from view: ControllerBackedProtocol?,
        stashAddress: AccountAddress,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showRewardPayoutsForValidator(
        from view: ControllerBackedProtocol?,
        stashAddress: AccountAddress,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showStakingBalance(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        flow: StakingBalanceFlow
    )

    func showNominatorValidators(
        from view: ControllerBackedProtocol?,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showRewardDestination(
        from view: ControllerBackedProtocol?,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showControllerAccount(
        from view: ControllerBackedProtocol?,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showAccountsSelection(from view: StakingMainViewProtocol?)

    func showBondMore(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        flow: StakingBondMoreFlow
    )

    func showRedeem(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        flow: StakingRedeemFlow
    )

    func showAnalytics(
        from view: ControllerBackedProtocol?,
        mode: AnalyticsContainerViewMode,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel
    )

    func showYourValidatorInfo(
        chainAsset: ChainAsset,
        selectedAccount: MetaAccountModel,
        flow: ValidatorInfoFlow,
        from view: ControllerBackedProtocol?
    )

    func showChainAssetSelection(
        from view: StakingMainViewProtocol?,
        selectedChainAssetId: ChainAssetId?,
        delegate: AssetSelectionDelegate
    )
}

protocol StakingMainViewFactoryProtocol: AnyObject {
    static func createView() -> StakingMainViewProtocol?
}
