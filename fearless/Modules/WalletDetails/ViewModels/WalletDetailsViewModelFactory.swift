import UIKit
import FearlessUtils

protocol WalletDetailsViewModelFactoryProtocol {
    func buildNormalViewModel(
        flow: WalletDetailsFlow,
        chains: [ChainModel],
        locale: Locale
    ) -> WalletDetailsViewModel

    func buildExportViewModel(
        flow: WalletDetailsFlow,
        chains: [ChainModel],
        locale: Locale
    ) -> WalletExportViewModel
}

class WalletDetailsViewModelFactory {
    private func buildSection(
        flow: WalletDetailsFlow,
        chains: [ChainModel],
        title: String,
        locale: Locale
    ) -> WalletDetailsSection {
        WalletDetailsSection(
            title: title,
            viewModels: chains.compactMap { chain in
                let account = flow.wallet.fetch(for: chain.accountRequest())
                let icon = chain.icon.map { RemoteImageViewModel(url: $0) }
                let address = account?.toAddress()
                var addressImage: UIImage?
                if let address = address {
                    addressImage = try? PolkadotIconGenerator().generateFromAddress(address)
                        .imageWithFillColor(
                            R.color.colorBlack()!,
                            size: UIConstants.normalAddressIconSize,
                            contentScale: UIScreen.main.scale
                        )
                }

                return WalletDetailsCellViewModel(
                    chainImageViewModel: icon,
                    account: account,
                    chain: chain,
                    addressImage: addressImage,
                    address: address,
                    accountMissing: flow.wallet.fetch(
                        for: chain.accountRequest()
                    )?.accountId == nil,
                    actionsAvailable: flow.actionsAvailable,
                    locale: locale,
                    chainUnused: (flow.wallet.unusedChainIds ?? []).contains(chain.chainId)
                )
            }
        )
    }

    private func buildSections(
        flow: WalletDetailsFlow,
        chains: [ChainModel],
        locale: Locale
    ) -> [WalletDetailsSection] {
        let emptyAccounts = chains.filter {
            flow.wallet.fetch(for: $0.accountRequest()) == nil
                && !(flow.wallet.unusedChainIds ?? []).contains($0.chainId)
        }
        let nativeAccounts = chains.filter {
            flow.wallet.fetch(for: $0.accountRequest())?.isChainAccount == false
                || (flow.wallet.fetch(for: $0.accountRequest()) == nil
                    && (flow.wallet.unusedChainIds ?? []).contains($0.chainId))
        }

        let customAccounts = chains.filter { flow.wallet.fetch(for: $0.accountRequest())?.isChainAccount == true }

        var sections: [WalletDetailsSection] = []

        if !emptyAccounts.isEmpty {
            let customSection = buildSection(
                flow: flow,
                chains: emptyAccounts,
                title: "",
                locale: locale
            )
            sections.append(customSection)
        }

        if !customAccounts.isEmpty {
            let customSection = buildSection(
                flow: flow,
                chains: customAccounts,
                title: R.string.localizable.accountsWithChangedKey(preferredLanguages: locale.rLanguages),
                locale: locale
            )
            sections.append(customSection)
        }

        if !nativeAccounts.isEmpty {
            let nativeSection = buildSection(
                flow: flow,
                chains: nativeAccounts,
                title: R.string.localizable.accountsWithOneKey(preferredLanguages: locale.rLanguages),
                locale: locale
            )
            sections.append(nativeSection)
        }

        return sections
    }
}

extension WalletDetailsViewModelFactory: WalletDetailsViewModelFactoryProtocol {
    func buildNormalViewModel(
        flow: WalletDetailsFlow,
        chains: [ChainModel],
        locale: Locale
    ) -> WalletDetailsViewModel {
        let sections = buildSections(flow: flow, chains: chains, locale: locale)
        return WalletDetailsViewModel(
            navigationTitle: R.string.localizable.tabbarWalletTitle(preferredLanguages: locale.rLanguages),
            sections: sections
        )
    }

    func buildExportViewModel(
        flow: WalletDetailsFlow,
        chains: [ChainModel],
        locale: Locale
    ) -> WalletExportViewModel {
        let sections = buildSections(flow: flow, chains: chains, locale: locale)
        return WalletExportViewModel(
            navigationTitle: R.string.localizable.accountsForExport(preferredLanguages: locale.rLanguages),
            sections: sections
        )
    }
}
