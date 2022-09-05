import Foundation
import SoraFoundation

protocol BalanceInfoViewModelFactoryProtocol {
    func buildBalanceInfo(
        with type: BalanceInfoType,
        balances: WalletBalanceInfos,
        locale: Locale
    ) -> BalanceInfoViewModel
}

final class BalanceInfoViewModelFactory: BalanceInfoViewModelFactoryProtocol {
    let assetBalanceFormatterFactory: AssetBalanceFormatterFactoryProtocol

    init(assetBalanceFormatterFactory: AssetBalanceFormatterFactoryProtocol) {
        self.assetBalanceFormatterFactory = assetBalanceFormatterFactory
    }

    func buildBalanceInfo(
        with type: BalanceInfoType,
        balances: WalletBalanceInfos,
        locale: Locale
    ) -> BalanceInfoViewModel {
        var balanceInfoViewModel: BalanceInfoViewModel

        switch type {
        case let .wallet(metaAccount):
            guard let info = balances[metaAccount.metaId] else {
                return zeroBalanceViewModel(
                    currencySymbol: metaAccount.selectedCurrency.symbol,
                    infoButtonEnabled: false
                )
            }
            balanceInfoViewModel = buildWalletBalance(
                with: info,
                locale: locale
            )

        case let .chainAsset(metaAccount, chainAsset):
            guard let info = balances[metaAccount.metaId] else {
                return zeroBalanceViewModel(
                    currencySymbol: metaAccount.selectedCurrency.symbol,
                    infoButtonEnabled: false
                )
            }
            balanceInfoViewModel = buildChainAssetBalance(
                with: info,
                metaAccount: metaAccount,
                chainAsset: chainAsset,
                locale: locale
            )
        }

        return balanceInfoViewModel
    }

    private func buildWalletBalance(
        with balanceInfo: WalletBalanceInfo,
        locale: Locale
    ) -> BalanceInfoViewModel {
        let balanceTokenFormatterValue = tokenFormatter(
            for: balanceInfo.currency,
            locale: locale
        )

        let totalBalance = balanceTokenFormatterValue.stringFromDecimal(balanceInfo.totalFiatValue) ?? "0"
        let dayChangeAttributedString = getDayChangeAttributedString(
            currency: balanceInfo.currency,
            dayChange: balanceInfo.dayChangePercent,
            dayChangeValue: balanceInfo.dayChangeValue,
            locale: locale
        )

        return BalanceInfoViewModel(
            dayChangeAttributedString: dayChangeAttributedString,
            balanceString: totalBalance,
            infoButtonEnabled: false
        )
    }

    private func buildChainAssetBalance(
        with balanceInfo: WalletBalanceInfo,
        metaAccount: MetaAccountModel,
        chainAsset: ChainAsset,
        locale: Locale
    ) -> BalanceInfoViewModel {
        let accountRequest = chainAsset.chain.accountRequest()
        guard let accountId = metaAccount.fetch(for: accountRequest)?.accountId else {
            return zeroBalanceViewModel(
                currencySymbol: metaAccount.selectedCurrency.symbol,
                infoButtonEnabled: false
            )
        }

        let dayChangeAttributedString = getDayChangeAttributedString(
            currency: balanceInfo.currency,
            dayChange: balanceInfo.dayChangePercent,
            dayChangeValue: balanceInfo.dayChangeValue,
            locale: locale
        )

        let displayInfo = chainAsset.asset.displayInfo
        let assetFormatter = assetBalanceFormatterFactory.createTokenFormatter(for: displayInfo).value(for: locale)

        let chainAssetKey = chainAsset.uniqueKey(accountId: accountId)
        guard
            let accountInfo = balanceInfo.accountInfos[chainAssetKey] ?? nil,
            let balance = Decimal.fromSubstrateAmount(
                accountInfo.data.total,
                precision: displayInfo.assetPrecision
            ),
            let balanceString = assetFormatter.stringFromDecimal(balance)
        else {
            return zeroBalanceViewModel(
                currencySymbol: metaAccount.selectedCurrency.symbol,
                infoButtonEnabled: true
            )
        }

        return BalanceInfoViewModel(
            dayChangeAttributedString: dayChangeAttributedString,
            balanceString: balanceString,
            infoButtonEnabled: true
        )
    }

    private func zeroBalanceViewModel(
        currencySymbol: String,
        infoButtonEnabled: Bool
    ) -> BalanceInfoViewModel {
        BalanceInfoViewModel(
            dayChangeAttributedString: nil,
            balanceString: currencySymbol + "0",
            infoButtonEnabled: infoButtonEnabled
        )
    }

    private func tokenFormatter(
        for currency: Currency,
        locale: Locale
    ) -> TokenFormatter {
        let displayInfo = AssetBalanceDisplayInfo.forCurrency(currency)
        let tokenFormatter = assetBalanceFormatterFactory.createTokenFormatter(for: displayInfo)
        let tokenFormatterValue = tokenFormatter.value(for: locale)
        return tokenFormatterValue
    }

    private func getDayChangeAttributedString(
        currency: Currency,
        dayChange: Decimal,
        dayChangeValue: Decimal,
        locale: Locale
    ) -> NSAttributedString? {
        let balanceTokenFormatterValue = tokenFormatter(for: currency, locale: locale)
        let dayChangePercent = dayChange.percentString(locale: locale) ?? ""

        var dayChangeValue: String = balanceTokenFormatterValue.stringFromDecimal(abs(dayChangeValue)) ?? ""
        dayChangeValue = "(\(dayChangeValue))"
        let priceWithChangeString = [dayChangePercent, dayChangeValue].joined(separator: " ")
        let priceWithChangeAttributed = NSMutableAttributedString(string: priceWithChangeString)

        let color = dayChange > 0
            ? R.color.colorGreen()
            : R.color.colorRed()

        if let color = color, let colorLightGray = R.color.colorLightGray() {
            priceWithChangeAttributed.addAttributes(
                [NSAttributedString.Key.foregroundColor: color],
                range: NSRange(
                    location: 0,
                    length: dayChangePercent.count
                )
            )
            priceWithChangeAttributed.addAttributes(
                [NSAttributedString.Key.foregroundColor: colorLightGray],
                range: NSRange(
                    location: dayChangePercent.count + 1,
                    length: dayChangeValue.count
                )
            )
        }

        return priceWithChangeAttributed
    }
}
