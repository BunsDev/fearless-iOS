import Foundation
import SoraFoundation
import BigInt
import SoraKeystore

protocol NetworkInfoViewModelFactoryProtocol {
    func createMainViewModel(
        from address: AccountAddress,
        chainAsset: ChainAsset,
        balance: Decimal
    ) -> StakingMainViewModel

    func createNetworkStakingInfoViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        minNominatorBond: BigUInt?,
        priceData: PriceData?
    ) -> LocalizableResource<NetworkStakingInfoViewModelProtocol>
}

final class NetworkInfoViewModelFactory {
    private var chainAsset: ChainAsset?
    private var balanceViewModelFactory: BalanceViewModelFactoryProtocol?

    private func getBalanceViewModelFactory(for chainAsset: ChainAsset) -> BalanceViewModelFactoryProtocol {
        if let factory = balanceViewModelFactory, self.chainAsset == chainAsset {
            return factory
        }

        let factory = BalanceViewModelFactory(targetAssetInfo: chainAsset.assetDisplayInfo)

        self.chainAsset = chainAsset
        balanceViewModelFactory = factory

        return factory
    }

    private func createStakeViewModel(
        stake: BigUInt,
        chainAsset: ChainAsset,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol> {
        let balanceViewModelFactory = getBalanceViewModelFactory(for: chainAsset)

        let stakedAmount = Decimal.fromSubstrateAmount(
            stake,
            precision: Int16(chainAsset.asset.precision)
        ) ?? 0.0

        let stakedPair = balanceViewModelFactory.balanceFromPrice(
            stakedAmount,
            priceData: priceData
        )

        return LocalizableResource { locale in
            stakedPair.value(for: locale)
        }
    }

    private func createTotalStakeViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol>? {
        guard let totalStake = networkStakingInfo.relaychainInfo?.totalStake else {
            return nil
        }

        return createStakeViewModel(
            stake: totalStake,
            chainAsset: chainAsset,
            priceData: priceData
        )
    }

    private func createMinimalStakeViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        minNominatorBond: BigUInt?,
        priceData: PriceData?
    ) -> LocalizableResource<BalanceViewModelProtocol> {
        createStakeViewModel(
            stake: networkStakingInfo.calculateMinimumStake(given: minNominatorBond),
            chainAsset: chainAsset,
            priceData: priceData
        )
    }

    private func createActiveNominatorsViewModel(
        with networkStakingInfo: NetworkStakingInfo
    ) -> LocalizableResource<String>? {
        guard let activeNominatorsCount = networkStakingInfo.relaychainInfo?.activeNominatorsCount else {
            return nil
        }

        return LocalizableResource { locale -> String in
            let quantityFormatter = NumberFormatter.quantity.localizableResource().value(for: locale)

            return quantityFormatter
                .string(from: activeNominatorsCount as NSNumber) ?? ""
        }
    }

    private func createLockUpPeriodViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        constantErasPerDay: UInt32
    ) -> LocalizableResource<String>? {
        var erasPerDay: UInt32

        switch networkStakingInfo {
        case let .relaychain(_, relaychainInfo):
            erasPerDay = UInt32(relaychainInfo.stakingDuration.era.intervalsInDay)
        case .parachain:
            erasPerDay = constantErasPerDay
        }

        let lockUpPeriod = networkStakingInfo.baseInfo.lockUpPeriod
        let lockUpPeriodInDays = erasPerDay > 0 ? lockUpPeriod / erasPerDay : 0

        return LocalizableResource { locale in
            R.string.localizable.commonDaysFormat(
                format: Int(lockUpPeriodInDays),
                preferredLanguages: locale.rLanguages
            )
        }
    }
}

extension NetworkInfoViewModelFactory: NetworkInfoViewModelFactoryProtocol {
    func createMainViewModel(
        from address: AccountAddress,
        chainAsset: ChainAsset,
        balance: Decimal
    ) -> StakingMainViewModel {
        let balanceViewModel = getBalanceViewModelFactory(for: chainAsset).amountFromValue(balance)

        let imageViewModel = chainAsset.assetDisplayInfo.icon.map {
            RemoteImageViewModel(url: $0)
        }

        return StakingMainViewModel(
            address: address,
            chainName: chainAsset.chain.name,
            assetName: chainAsset.chain.name,
            assetIcon: imageViewModel,
            balanceViewModel: balanceViewModel
        )
    }

    func createNetworkStakingInfoViewModel(
        with networkStakingInfo: NetworkStakingInfo,
        chainAsset: ChainAsset,
        minNominatorBond: BigUInt?,
        priceData: PriceData?
    ) -> LocalizableResource<NetworkStakingInfoViewModelProtocol> {
        let localizedTotalStake = createTotalStakeViewModel(
            with: networkStakingInfo,
            chainAsset: chainAsset,
            priceData: priceData
        )

        let localizedMinimalStake = createMinimalStakeViewModel(
            with: networkStakingInfo,
            chainAsset: chainAsset,
            minNominatorBond: minNominatorBond,
            priceData: priceData
        )

        let nominatorsCount = createActiveNominatorsViewModel(with: networkStakingInfo)

        let localizedLockUpPeriod = createLockUpPeriodViewModel(
            with: networkStakingInfo,
            constantErasPerDay: chainAsset.chain.erasPerDay
        )

        return LocalizableResource { locale in
            NetworkStakingInfoViewModel(
                totalStake: localizedTotalStake?.value(for: locale),
                minimalStake: localizedMinimalStake.value(for: locale),
                activeNominators: nominatorsCount?.value(for: locale),
                lockUpPeriod: localizedLockUpPeriod?.value(for: locale)
            )
        }
    }
}
