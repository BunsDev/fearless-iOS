import Foundation
import BigInt

class StakingAmountParachainViewModelState: StakingAmountViewModelState {
    var amount: Decimal?
    var fee: Decimal?

    var stateListener: StakingAmountModelStateListener?
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    let wallet: MetaAccountModel
    let chainAsset: ChainAsset
    private var networkStakingInfo: NetworkStakingInfo?
    private var minStake: Decimal?
    private(set) var minimalBalance: Decimal?

    init(
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        amount: Decimal?
    ) {
        self.dataValidatingFactory = dataValidatingFactory
        self.wallet = wallet
        self.chainAsset = chainAsset
        self.amount = amount
    }

    var bonding: InitiatedBonding? {
        guard let amount = amount, let account = wallet.fetch(for: chainAsset.chain.accountRequest()) else {
            return nil
        }

        return InitiatedBonding(amount: amount, rewardDestination: .payout(account: account))
    }

    var feeExtrinsicBuilderClosure: ExtrinsicBuilderClosure {
        let closure: ExtrinsicBuilderClosure = { builder in
            guard let accountId = Data.random(of: 20) else {
                return builder
            }

            let call = SubstrateCallFactory().delegate(
                candidate: accountId,
                amount: BigUInt(stringLiteral: "9999999999999999"),
                candidateDelegationCount: 100,
                delegationCount: 100
            )

            return try builder.adding(call: call)
        }

        return closure
    }

    func validators(using locale: Locale) -> [DataValidating] {
        let minimumStake = Decimal.fromSubstrateAmount(networkStakingInfo?.baseInfo.minStakeAmongActiveNominators ?? BigUInt.zero, precision: Int16(chainAsset.asset.precision)) ?? 0

        return [dataValidatingFactory.canNominate(
            amount: amount,
            minimalBalance: minimalBalance,
            minNominatorBond: minimumStake,
            locale: locale
        ),
        dataValidatingFactory.bondAtLeastMinStaking(
            asset: chainAsset.asset,
            amount: amount,
            minNominatorBond: minStake,
            locale: locale
        )]
    }

    private func notifyListeners() {
        stateListener?.modelStateDidChanged(viewModelState: self)
    }

    func setStateListener(_ stateListener: StakingAmountModelStateListener?) {
        self.stateListener = stateListener
    }

    func updateAmount(_ newValue: Decimal) {
        amount = newValue
    }
}

extension StakingAmountParachainViewModelState: StakingAmountParachainStrategyOutput {
    func didReceive(minimalBalance: BigUInt?) {
        if let minimalBalance = minimalBalance,
           let amount = Decimal.fromSubstrateAmount(minimalBalance, precision: Int16(chainAsset.asset.precision)) {
            self.minimalBalance = amount

            notifyListeners()
        }
    }

    func didReceive(networkStakingInfo: NetworkStakingInfo) {
        self.networkStakingInfo = networkStakingInfo

        let minStakeSubstrateAmount = networkStakingInfo.calculateMinimumStake(given: networkStakingInfo.baseInfo.minStakeAmongActiveNominators)
        minStake = Decimal.fromSubstrateAmount(minStakeSubstrateAmount, precision: Int16(chainAsset.asset.precision))
    }

    func didSetup() {
        stateListener?.provideYourRewardDestinationViewModel(viewModelState: self)
    }

    func didReceive(networkStakingInfoError _: Error) {}

    func didReceive(error _: Error) {}

    func didReceive(paymentInfo: RuntimeDispatchInfo) {
        if let feeValue = BigUInt(paymentInfo.fee),
           let fee = Decimal.fromSubstrateAmount(feeValue, precision: Int16(chainAsset.asset.precision)) {
            self.fee = fee
        } else {
            fee = nil
        }

        notifyListeners()
    }
}