import Foundation
import SoraFoundation

// swiftlint:disable function_parameter_count function_body_length
protocol ChainAssetListViewModelFactoryProtocol {
    func buildViewModel(
        displayType: AssetListDisplayType,
        selectedMetaAccount: MetaAccountModel,
        chainAssets: [ChainAsset],
        locale: Locale,
        accountInfos: [ChainAssetKey: AccountInfo?],
        prices: PriceDataUpdated,
        chainsWithIssues: [ChainModel.Id]
    ) -> ChainAssetListViewModel
}

final class ChainAssetListViewModelFactory: ChainAssetListViewModelFactoryProtocol {
    private let assetBalanceFormatterFactory: AssetBalanceFormatterFactoryProtocol

    init(assetBalanceFormatterFactory: AssetBalanceFormatterFactoryProtocol) {
        self.assetBalanceFormatterFactory = assetBalanceFormatterFactory
    }

    func buildViewModel(
        displayType: AssetListDisplayType,
        selectedMetaAccount: MetaAccountModel,
        chainAssets: [ChainAsset],
        locale: Locale,
        accountInfos: [ChainAssetKey: AccountInfo?],
        prices: PriceDataUpdated,
        chainsWithIssues: [ChainModel.Id]
    ) -> ChainAssetListViewModel {
        var fiatBalanceByChainAsset: [ChainAsset: Decimal] = [:]

        chainAssets.forEach { chainAsset in
            guard let accountId = selectedMetaAccount.fetch(for: chainAsset.chain.accountRequest())?.accountId else {
                return
            }
            let accountInfo = accountInfos[chainAsset.uniqueKey(accountId: accountId)] ?? nil

            let priceData = prices.pricesData.first(where: { $0.priceId == chainAsset.asset.priceId })
            fiatBalanceByChainAsset[chainAsset] = getFiatBalance(
                for: chainAsset,
                accountInfo: accountInfo,
                priceData: priceData
            )
        }

        let chainAssetCellModels: [ChainAccountBalanceCellViewModel] = chainAssets.compactMap { chainAsset in
            let priceId = chainAsset.asset.priceId ?? chainAsset.asset.id
            let priceData = prices.pricesData.first(where: { $0.priceId == priceId })

            return buildChainAccountBalanceCellViewModel(
                chainAssets: chainAssets,
                chainAsset: chainAsset,
                priceData: priceData,
                priceDataUpdated: prices.updated,
                accountInfos: accountInfos,
                locale: locale,
                currency: selectedMetaAccount.selectedCurrency,
                selectedMetaAccount: selectedMetaAccount,
                chainsWithIssues: chainsWithIssues
            )
        }

        var activeSectionCellModels: [ChainAccountBalanceCellViewModel] = []
        var hiddenSectionCellModels: [ChainAccountBalanceCellViewModel] = []

        if let assetIdsEnabled = selectedMetaAccount.assetIdsEnabled {
            let cellModelsDivide = chainAssetCellModels.divide(predicate: { [assetIdsEnabled] cellModel in
                assetIdsEnabled.contains { assetId in
                    assetId == cellModel.chainAsset.uniqueKey(accountId: selectedMetaAccount.substrateAccountId)
                }
            })
            activeSectionCellModels = cellModelsDivide.slice
            hiddenSectionCellModels = cellModelsDivide.remainder
        } else {
            activeSectionCellModels = chainAssetCellModels
        }

        switch displayType {
        case .chain:
            break
        case .assetChains:
            activeSectionCellModels = activeSectionCellModels.uniq(predicate: { $0.chainAsset.asset.name })
            hiddenSectionCellModels = hiddenSectionCellModels.uniq(predicate: { $0.chainAsset.asset.name })
        }

        let activeSection = ChainAssetListTableSection(
            title: nil,
            expandable: false
        )

        let hiddenSection = ChainAssetListTableSection(
            title: R.string.localizable.hiddenAssets(preferredLanguages: locale.rLanguages),
            expandable: true
        )

        let enabledAccountsInfosKeys = accountInfos.keys.filter { key in
            chainAssets.contains { chainAsset in
                guard
                    let accountId = selectedMetaAccount.fetch(
                        for: chainAsset.chain.accountRequest()
                    )?.accountId else {
                    return false
                }
                let chainAssetKey = chainAsset.uniqueKey(accountId: accountId)
                return key == chainAssetKey
            }
        }

        let isColdBoot = enabledAccountsInfosKeys.count != fiatBalanceByChainAsset.count
        return ChainAssetListViewModel(
            sections: [
                activeSection, hiddenSection
            ],
            cellsForSections: [
                activeSection: activeSectionCellModels,
                hiddenSection: hiddenSectionCellModels
            ],
            isColdBoot: isColdBoot
        )
    }
}

private extension ChainAssetListViewModelFactory {
    func tokenFormatter(
        for currency: Currency,
        locale: Locale
    ) -> TokenFormatter {
        let displayInfo = AssetBalanceDisplayInfo.forCurrency(currency)
        let tokenFormatter = assetBalanceFormatterFactory.createTokenFormatter(for: displayInfo)
        let tokenFormatterValue = tokenFormatter.value(for: locale)
        return tokenFormatterValue
    }

    func buildChainAccountBalanceCellViewModel(
        chainAssets: [ChainAsset],
        chainAsset: ChainAsset,
        priceData: PriceData?,
        priceDataUpdated: Bool,
        accountInfos: [ChainAssetKey: AccountInfo?],
        locale: Locale,
        currency: Currency,
        selectedMetaAccount: MetaAccountModel,
        chainsWithIssues: [ChainModel.Id]
    ) -> ChainAccountBalanceCellViewModel? {
        var icon = (chainAsset.asset.icon ?? chainAsset.chain.icon).map { buildRemoteImageViewModel(url: $0) }
        var title = chainAsset.chain.name

        if chainAsset.chain.parentId == chainAsset.asset.chainId,
           let chain = chainAssets.first(where: { $0.chain.chainId == chainAsset.asset.chainId })?.chain {
            title = chain.name
            icon = chain.icon.map { buildRemoteImageViewModel(url: $0) }
        }

        var accountInfo: AccountInfo?
        if let accountId = selectedMetaAccount.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            let key = chainAsset.uniqueKey(accountId: accountId)
            accountInfo = accountInfos[key] ?? nil
        }

        let priceAttributedString = getPriceAttributedString(
            priceData: priceData,
            locale: locale,
            currency: currency
        )
        let options = buildChainOptionsViewModel(chainAsset: chainAsset)

        var isColdBoot = true
        if let accountId = selectedMetaAccount.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            let key = chainAsset.uniqueKey(accountId: accountId)
            isColdBoot = !accountInfos.keys.contains(key)
        }

        let containsChainAssets = chainAssets.filter {
            $0.asset.name == chainAsset.asset.name
        }
        let isNetworkIssues = containsChainAssets.first(where: { chainsWithIssues.contains($0.chain.chainId) }) != nil

        let totalAssetBalance = getBalanceString(
            for: containsChainAssets,
            accountInfos: accountInfos,
            locale: locale,
            selectedMetaAccount: selectedMetaAccount
        )

        let totalFiatBalance = getFiatBalanceString(
            for: containsChainAssets,
            accountInfos: accountInfos,
            priceData: priceData,
            locale: locale,
            currency: currency,
            selectedMetaAccount: selectedMetaAccount
        )

        let viewModel = ChainAccountBalanceCellViewModel(
            assetContainsChainAssets: containsChainAssets,
            chainAsset: chainAsset,
            assetName: title,
            assetInfo: chainAsset.asset.displayInfo(with: chainAsset.chain.icon),
            imageViewModel: icon,
            balanceString: .init(
                value: .text(totalAssetBalance),
                isUpdated: priceDataUpdated
            ),
            priceAttributedString: .init(
                value: .attributed(priceAttributedString),
                isUpdated: priceDataUpdated
            ),
            totalAmountString: .init(
                value: .text(totalFiatBalance),
                isUpdated: priceDataUpdated
            ),
            options: options,
            isColdBoot: isColdBoot,
            priceDataWasUpdated: priceDataUpdated,
            isNetworkIssues: isNetworkIssues
        )

        if selectedMetaAccount.assetFilterOptions.contains(.hideZeroBalance),
           accountInfo == nil,
           !isColdBoot {
            return nil
        } else {
            return viewModel
        }
    }

    func getBalanceString(
        for chainAssets: [ChainAsset],
        accountInfos: [ChainAssetKey: AccountInfo?],
        locale: Locale,
        selectedMetaAccount: MetaAccountModel
    ) -> String? {
        let totalAssetBalance = chainAssets.compactMap { chainAsset -> Decimal in
            if let accountId = selectedMetaAccount.fetch(for: chainAsset.chain.accountRequest())?.accountId,
               let accountInfo = accountInfos[chainAsset.uniqueKey(accountId: accountId)] {
                return getBalance(for: chainAsset, accountInfo: accountInfo)
            }

            return Decimal.zero
        }.reduce(0, +)

        let digits = totalAssetBalance > 0 ? 4 : 0
        return totalAssetBalance.toString(locale: locale, digits: digits)
    }

    func getBalance(
        for chainAsset: ChainAsset,
        accountInfo: AccountInfo?
    ) -> Decimal {
        guard let accountInfo = accountInfo else {
            return Decimal.zero
        }

        let assetInfo = chainAsset.asset.displayInfo

        let balance = Decimal.fromSubstrateAmount(
            accountInfo.data.total,
            precision: assetInfo.assetPrecision
        ) ?? 0

        return balance
    }

    func getFiatBalanceString(
        for chainAssets: [ChainAsset],
        accountInfos: [ChainAssetKey: AccountInfo?],
        priceData: PriceData?,
        locale: Locale,
        currency: Currency,
        selectedMetaAccount: MetaAccountModel
    ) -> String? {
        let totalFiatBalance = chainAssets.compactMap { chainAsset -> Decimal? in
            if let accountId = selectedMetaAccount.fetch(for: chainAsset.chain.accountRequest())?.accountId,
               let accountInfo = accountInfos[chainAsset.uniqueKey(accountId: accountId)] {
                return getFiatBalance(
                    for: chainAsset,
                    accountInfo: accountInfo,
                    priceData: priceData
                )
            }

            return nil
        }.reduce(0, +)

        guard totalFiatBalance != .zero else { return nil }

        let balanceTokenFormatterValue = tokenFormatter(for: currency, locale: locale)
        return balanceTokenFormatterValue.stringFromDecimal(totalFiatBalance)
    }

    func getFiatBalance(
        for chainAsset: ChainAsset,
        accountInfo: AccountInfo?,
        priceData: PriceData?
    ) -> Decimal {
        let assetInfo = chainAsset.asset.displayInfo

        var balance: Decimal
        if let accountInfo = accountInfo {
            balance = Decimal.fromSubstrateAmount(
                accountInfo.data.total,
                precision: assetInfo.assetPrecision
            ) ?? 0
        } else {
            balance = Decimal.zero
        }

        guard let price = priceData?.price,
              let priceDecimal = Decimal(string: price) else {
            return Decimal.zero
        }

        let totalBalanceDecimal = priceDecimal * balance

        return totalBalanceDecimal
    }

    func getPriceAttributedString(
        priceData: PriceData?,
        locale: Locale,
        currency: Currency
    ) -> NSAttributedString? {
        let balanceTokenFormatterValue = tokenFormatter(for: currency, locale: locale)

        guard let priceData = priceData,
              let priceDecimal = Decimal(string: priceData.price) else {
            return nil
        }

        let changeString: String = priceData.fiatDayChange.map {
            let percentValue = $0 / 100
            return percentValue.percentString(locale: locale) ?? ""
        } ?? ""

        let priceString: String = balanceTokenFormatterValue.stringFromDecimal(priceDecimal) ?? ""
        let priceWithChangeString = [priceString, changeString].joined(separator: " ")
        let priceWithChangeAttributed = NSMutableAttributedString(string: priceWithChangeString)

        let color = (priceData.fiatDayChange ?? 0) > 0
            ? R.color.colorGreen()
            : R.color.colorRed()

        if let color = color {
            priceWithChangeAttributed.addAttributes(
                [NSAttributedString.Key.foregroundColor: color],
                range: NSRange(
                    location: priceString.count + 1,
                    length: changeString.count
                )
            )
        }

        return priceWithChangeAttributed
    }
}

extension ChainAssetListViewModelFactory: RemoteImageViewModelFactoryProtocol {}
extension ChainAssetListViewModelFactory: ChainOptionsViewModelFactoryProtocol {}
