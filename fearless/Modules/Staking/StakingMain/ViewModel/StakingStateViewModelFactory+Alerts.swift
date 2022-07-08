import Foundation
import SoraFoundation
import BigInt

extension StakingStateViewModelFactory {
    func stakingAlertsForNominatorState(_ state: NominatorState) -> [StakingAlert] {
        [
            findInactiveAlert(state: state),
            findRedeemUnbondedAlert(commonData: state.commonData, ledgerInfo: state.ledgerInfo),
            findWaitingNextEraAlert(nominationStatus: state.status)
        ].compactMap { $0 }
    }

    func stakingAlertsForValidatorState(_ state: ValidatorState) -> [StakingAlert] {
        [
            findRedeemUnbondedAlert(commonData: state.commonData, ledgerInfo: state.ledgerInfo)
        ].compactMap { $0 }
    }

    func stakingAlertsForBondedState(_ state: BondedState) -> [StakingAlert] {
        [
            findMinNominatorBondAlert(state: state),
            .bondedSetValidators,
            findRedeemUnbondedAlert(commonData: state.commonData, ledgerInfo: state.ledgerInfo)
        ].compactMap { $0 }
    }

    func stakingAlertsNoStashState(_: NoStashState) -> [StakingAlert] {
        []
    }

    func stakingAlertParachainState(_ state: ParachainState) -> [StakingAlert] {
        findCollatorLeavingAlert(state: state) + findLowStakeAlert(state: state) + findRedeemAlert(state: state)
    }

    private func findRedeemUnbondedAlert(
        commonData: StakingStateCommonData,
        ledgerInfo: StakingLedger
    ) -> StakingAlert? {
        guard
            let era = commonData.eraStakersInfo?.activeEra,
            let precision = commonData.chainAsset?.assetDisplayInfo.assetPrecision,
            let redeemable = Decimal.fromSubstrateAmount(
                ledgerInfo.redeemable(inEra: era),
                precision: precision
            ),
            redeemable > 0,
            let redeemableAmount = balanceViewModelFactory?.amountFromValue(redeemable)
        else { return nil }

        let localizedString = LocalizableResource<String> { locale in
            redeemableAmount.value(for: locale)
        }
        return .redeemUnbonded(localizedString)
    }

    private func findMinNominatorBondAlert(state: BondedState) -> StakingAlert? {
        let commonData = state.commonData
        let ledgerInfo = state.ledgerInfo

        guard let minStake = commonData.minStake else {
            return nil
        }

        guard ledgerInfo.active < minStake else {
            return nil
        }

        guard
            let chainAsset = commonData.chainAsset,
            let minActiveDecimal = Decimal.fromSubstrateAmount(
                minStake,
                precision: chainAsset.assetDisplayInfo.assetPrecision
            ),
            let minActiveAmount = balanceViewModelFactory?.amountFromValue(minActiveDecimal)
        else {
            return nil
        }

        let localizedString = LocalizableResource<String> { locale in
            R.string.localizable.stakingInactiveCurrentMinimalStake(
                minActiveAmount.value(for: locale),
                preferredLanguages: locale.rLanguages
            )
        }

        return .nominatorLowStake(localizedString)
    }

    private func findInactiveAlert(state: NominatorState) -> StakingAlert? {
        guard case .inactive = state.status else { return nil }

        let commonData = state.commonData
        let ledgerInfo = state.ledgerInfo

        guard let minStake = commonData.minStake else {
            return nil
        }

        if ledgerInfo.active < minStake {
            guard
                let chainAsset = commonData.chainAsset,
                let minActiveDecimal = Decimal.fromSubstrateAmount(
                    minStake,
                    precision: chainAsset.assetDisplayInfo.assetPrecision
                ),
                let minActiveAmount = balanceViewModelFactory?.amountFromValue(minActiveDecimal)
            else {
                return nil
            }

            let localizedString = LocalizableResource<String> { locale in
                R.string.localizable.stakingInactiveCurrentMinimalStake(
                    minActiveAmount.value(for: locale),
                    preferredLanguages: locale.rLanguages
                )
            }
            return .nominatorLowStake(localizedString)
        } else if state.allValidatorsWithoutReward {
            return .nominatorAllOversubscribed
        } else {
            return .nominatorChangeValidators
        }
    }

    private func findWaitingNextEraAlert(nominationStatus: NominationViewStatus) -> StakingAlert? {
        if case .waiting = nominationStatus {
            return .waitingNextEra
        }
        return nil
    }

//    Parachain

    private func findCollatorLeavingAlert(state: ParachainState) -> [StakingAlert] {
        let delegations = state.delegationInfos
        if let delegations = delegations {
            return delegations.compactMap { delegation in
                if case .leaving = delegation.collator.metadata?.status, let name = delegation.collator.identity?.name {
                    return .collatorLeaving(collatorName: name, delegation: delegation)
                }
                return nil
            }
        }
        return []
    }

    private func findLowStakeAlert(state: ParachainState) -> [StakingAlert] {
        guard let chainAsset = state.commonData.chainAsset,
              let accountId = try? state.commonData.address?.toAccountId(using: chainAsset.chain.chainFormat),
              let bottomDelegations = state.bottomDelegations,
              let delegationInfos = state.delegationInfos else {
            return []
        }

        let topDelegations: [AccountAddress: ParachainStakingDelegations] = [:]
        return bottomDelegations.compactMap { collatorBottomDelegations in
            if let delegation = collatorBottomDelegations.value.delegations.first(where: { $0.owner == accountId }) {
                if let minTopDelegationAmount =
                    topDelegations[collatorBottomDelegations.key]?.delegations.compactMap({ delegation in
                        delegation.amount
                    }).min() {
                    let minTopDecimal = Decimal.fromSubstrateAmount(
                        minTopDelegationAmount,
                        precision: Int16(chainAsset.asset.precision)
                    ) ?? 0.0
                    let ownAmountDecimal = Decimal.fromSubstrateAmount(
                        delegation.amount,
                        precision: Int16(chainAsset.asset.precision)
                    ) ?? 0.0
                    let difference = (minTopDecimal - ownAmountDecimal) * 1.1
                    if let collator = delegationInfos.first(where: { delegationInfo in
                        delegationInfo.collator.owner == delegation.owner
                    })?.collator {
                        return .collatorLowStake(
                            amount: difference.stringWithPointSeparator,
                            delegation: ParachainStakingDelegationInfo(
                                delegation: delegation,
                                collator: collator
                            )
                        )
                    }
                    return nil
                }
            }
            return nil
        }
    }

    private func findRedeemAlert(state: ParachainState) -> [StakingAlert] {
        let round = state.round
        if let requests = state.requests {
            return requests.filter { request in
                guard let currentEra = round?.current else {
                    return false
                }

                return request.whenExecutable <= currentEra
            }.compactMap { request in
                var amount = BigUInt.zero
                if case let .revoke(revokeAmount) = request.action {
                    amount += revokeAmount
                }

                if case let .decrease(decreaseAmount) = request.action {
                    amount += decreaseAmount
                }

                if amount > BigUInt.zero {
                    return .parachainRedeemUnbonded(delegation: (state.delegationInfos?.first)!)
                }
                return nil
            }
        }
        return []
    }
}
