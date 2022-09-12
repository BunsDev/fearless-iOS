import Foundation
import SoraFoundation
import BigInt

protocol StakingPoolManagementViewModelFactoryProtocol {
    func createStakedAmountViewModel(
        _ amount: Decimal
    ) -> LocalizableResource<NSAttributedString>

    func buildUnstakeViewModel(
        unstakePeriod: TimeInterval?
    ) -> LocalizableResource<String>?

    func buildViewModel(stakeInfo: StakingPoolMember?, era: EraIndex?) -> StakingPoolManagementViewModel

    func buildOptionsPickerViewModels(locale: Locale) -> [IconWithTitleViewModel]
}

final class StakingPoolManagementViewModelFactory {
    private let chainAsset: ChainAsset
    private lazy var formatterFactory = AssetBalanceFormatterFactory()

    init(chainAsset: ChainAsset) {
        self.chainAsset = chainAsset
    }
}

extension StakingPoolManagementViewModelFactory: StakingPoolManagementViewModelFactoryProtocol {
    func createStakedAmountViewModel(
        _ amount: Decimal
    ) -> LocalizableResource<NSAttributedString> {
        let localizableBalanceFormatter = formatterFactory.createTokenFormatter(for: chainAsset.assetDisplayInfo)

        return LocalizableResource { locale in
            let amountString = localizableBalanceFormatter.value(for: locale).stringFromDecimal(amount) ?? ""
            let stakedString = R.string.localizable.poolStakingTotalStakeAmountTitle(
                amountString,
                preferredLanguages: locale.rLanguages
            )
            let stakedAmountAttributedString = NSMutableAttributedString(string: stakedString)
            stakedAmountAttributedString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: R.color.colorWhite(),
                range: (stakedString as NSString).range(of: amountString)
            )

            return stakedAmountAttributedString
        }
    }

    func buildUnstakeViewModel(
        unstakePeriod: TimeInterval?
    ) -> LocalizableResource<String>? {
        guard let unstakePeriod = unstakePeriod else {
            return nil
        }

        return unstakePeriod.localizedReadableValue()
    }

    func buildViewModel(stakeInfo: StakingPoolMember?, era: EraIndex?) -> StakingPoolManagementViewModel {
        var unstakeButtonEnabled = false

        if let era = era, let stakeInfo = stakeInfo {
            unstakeButtonEnabled = stakeInfo.unbonding(inEra: era) != BigUInt.zero
        }

        return StakingPoolManagementViewModel(
            stakeMoreButtonEnabled: stakeInfo?.points != BigUInt.zero,
            unstakeButtonEnabled: unstakeButtonEnabled
        )
    }

    func buildOptionsPickerViewModels(locale: Locale) -> [IconWithTitleViewModel] {
        let validatorsOptionViewModel = IconWithTitleViewModel(icon: nil, title: R.string.localizable.stakingValidatorNominators(preferredLanguages: locale.rLanguages))
        let poolInfoOptionViewModel = IconWithTitleViewModel(icon: nil, title: R.string.localizable.poolCommon(preferredLanguages: locale.rLanguages))

        return [validatorsOptionViewModel, poolInfoOptionViewModel]
    }
}
