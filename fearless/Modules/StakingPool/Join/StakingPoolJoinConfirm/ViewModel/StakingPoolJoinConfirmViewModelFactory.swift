import Foundation

protocol StakingPoolJoinConfirmViewModelFactoryProtocol {
    func buildViewModel(
        amount: Decimal,
        pool: StakingPool,
        wallet: MetaAccountModel,
        locale: Locale
    ) -> StakingPoolJoinConfirmViewModel
}

final class StakingPoolJoinConfirmViewModelFactory {
    private let chainAsset: ChainAsset
    private let assetBalanceFormatterFactory: AssetBalanceFormatterFactoryProtocol

    init(
        chainAsset: ChainAsset,
        assetBalanceFormatterFactory: AssetBalanceFormatterFactoryProtocol
    ) {
        self.chainAsset = chainAsset
        self.assetBalanceFormatterFactory = assetBalanceFormatterFactory
    }
}

extension StakingPoolJoinConfirmViewModelFactory: StakingPoolJoinConfirmViewModelFactoryProtocol {
    func buildViewModel(
        amount: Decimal,
        pool: StakingPool,
        wallet: MetaAccountModel,
        locale: Locale
    ) -> StakingPoolJoinConfirmViewModel {
        let tokenFormatter = assetBalanceFormatterFactory.createTokenFormatter(for: chainAsset.assetDisplayInfo)

        let amountString = tokenFormatter.value(for: locale).stringFromDecimal(amount) ?? ""
        let stakedString = R.string.localizable.poolStakingStartConfirmAmountTitle(
            amountString,
            preferredLanguages: locale.rLanguages
        )
        let stakedAmountAttributedString = NSMutableAttributedString(string: stakedString)
        stakedAmountAttributedString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: R.color.colorWhite(),
            range: (stakedString as NSString).range(of: amountString)
        )

        let address = wallet.fetch(for: chainAsset.chain.accountRequest())?.toAddress() ?? ""
        return StakingPoolJoinConfirmViewModel(
            amountAttributedString: stakedAmountAttributedString,
            accountNameString: wallet.name,
            accountAddressString: address,
            selectedPoolName: pool.name
        )
    }
}