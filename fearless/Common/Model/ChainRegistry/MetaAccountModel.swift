import Foundation
import RobinHood
import SSFModels

typealias MetaAccountId = String

struct MetaAccountModel: Equatable, Codable {
    let metaId: MetaAccountId
    let name: String
    let substrateAccountId: Data
    let substrateCryptoType: UInt8
    let substratePublicKey: Data
    let ethereumAddress: Data?
    let ethereumPublicKey: Data?
    let chainAccounts: Set<ChainAccountModel>
    let assetKeysOrder: [String]?
    let assetFilterOptions: [FilterOption]
    let canExportEthereumMnemonic: Bool
    let unusedChainIds: [String]?
    let selectedCurrency: Currency
    let chainIdForFilter: ChainModel.Id?
    let assetsVisibility: [AssetVisibility]
    let zeroBalanceAssetsHidden: Bool
    let isBackuped: Bool
}

extension MetaAccountModel {
    var supportEthereum: Bool {
        ethereumPublicKey != nil || chainAccounts.first(where: { $0.ethereumBased == true }) != nil
    }
}

extension MetaAccountModel: Identifiable {
    var identifier: String { metaId }
}

extension MetaAccountModel {
    func insertingChainAccount(_ newChainAccount: ChainAccountModel) -> MetaAccountModel {
        var newChainAccounts = chainAccounts.filter {
            $0.chainId != newChainAccount.chainId
        }

        newChainAccounts.insert(newChainAccount)

        return MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: newChainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingEthereumAddress(_ newEthereumAddress: Data?) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: newEthereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingEthereumPublicKey(_ newEthereumPublicKey: Data?) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: newEthereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingName(_ walletName: String) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: walletName,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingAssetKeysOrder(_ newAssetKeysOrder: [String]) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: newAssetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingUnusedChainIds(_ newUnusedChainIds: [String]) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: newUnusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingCurrency(_ currency: Currency) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: currency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingAssetsFilterOptions(_ options: [FilterOption]) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: options,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingChainIdForFilter(_ chainId: ChainModel.Id?) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainId,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingAssetsVisibility(_ newAssetsVisibility: [AssetVisibility]) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: newAssetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingZeroBalanceAssetsHidden(_ newZeroBalanceAssetsHidden: Bool) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: newZeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }

    func replacingIsBackuped(_ isBackuped: Bool) -> MetaAccountModel {
        MetaAccountModel(
            metaId: metaId,
            name: name,
            substrateAccountId: substrateAccountId,
            substrateCryptoType: substrateCryptoType,
            substratePublicKey: substratePublicKey,
            ethereumAddress: ethereumAddress,
            ethereumPublicKey: ethereumPublicKey,
            chainAccounts: chainAccounts,
            assetKeysOrder: assetKeysOrder,
            assetFilterOptions: assetFilterOptions,
            canExportEthereumMnemonic: canExportEthereumMnemonic,
            unusedChainIds: unusedChainIds,
            selectedCurrency: selectedCurrency,
            chainIdForFilter: chainIdForFilter,
            assetsVisibility: assetsVisibility,
            zeroBalanceAssetsHidden: zeroBalanceAssetsHidden,
            isBackuped: isBackuped
        )
    }
}
