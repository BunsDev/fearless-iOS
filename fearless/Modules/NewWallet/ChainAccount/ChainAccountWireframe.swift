import Foundation
import UIKit

final class ChainAccountWireframe: ChainAccountWireframeProtocol {
    func close(view: ControllerBackedProtocol?) {
        view?.controller.navigationController?.popViewController(animated: true)
    }

    func presentSendFlow(
        from view: ControllerBackedProtocol?,
        asset: AssetModel,
        chain: ChainModel,
        selectedMetaAccount: MetaAccountModel,
        transferFinishBlock: WalletTransferFinishBlock?
    ) {
        let searchView = SearchPeopleViewFactory.createView(
            chain: chain,
            asset: asset,
            selectedMetaAccount: selectedMetaAccount,
            transferFinishBlock: transferFinishBlock
        )

        guard let controller = searchView?.controller else {
            return
        }

        let navigationController = UINavigationController(rootViewController: controller)

        view?.controller.present(navigationController, animated: true)
    }

    func presentReceiveFlow(
        from view: ControllerBackedProtocol?,
        asset: AssetModel,
        chain: ChainModel,
        selectedMetaAccount: MetaAccountModel
    ) {
        let receiveView = ReceiveAssetViewFactory.createView(
            account: selectedMetaAccount,
            chain: chain,
            asset: asset
        )

        guard let controller = receiveView?.controller else {
            return
        }

        let navigationController = UINavigationController(rootViewController: controller)
        view?.controller.present(navigationController, animated: true)
    }

    func presentBuyFlow(
        from view: ControllerBackedProtocol?,
        items: [PurchaseAction],
        delegate: ModalPickerViewControllerDelegate
    ) {
        let buyView = ModalPickerFactory.createPickerForList(
            items,
            delegate: delegate,
            context: nil
        )

        guard let buyView = buyView else {
            return
        }

        view?.controller.navigationController?.present(buyView, animated: true)
    }

    func presentChainActionsFlow(
        from view: ControllerBackedProtocol?,
        items: [ChainAction],
        callback: @escaping ModalPickerSelectionCallback
    ) {
        let actionsView = ModalPickerFactory.createPickerForList(
            items,
            callback: callback,
            context: nil
        )

        guard let actionsView = actionsView else {
            return
        }

        view?.controller.navigationController?.present(actionsView, animated: true)
    }

    func presentPurchaseWebView(
        from view: ControllerBackedProtocol?,
        action: PurchaseAction
    ) {
        let webView = PurchaseViewFactory.createView(
            for: action
        )
        view?.controller.dismiss(animated: true, completion: {
            if let webViewController = webView?.controller {
                view?.controller.present(webViewController, animated: true, completion: nil)
            }
        })
    }

    func presentLockedInfo(
        from view: ControllerBackedProtocol?,
        balanceContext: BalanceContext,
        info: AssetBalanceDisplayInfo,
        currency: Currency
    ) {
        let assetBalanceDisplayInfo = AssetBalanceDisplayInfo.forCurrency(currency)
        let priceFormatter = AssetBalanceFormatterFactory().createTokenFormatter(for: assetBalanceDisplayInfo)
        let balanceLocksController = ModalInfoFactory.createFromBalanceContext(
            balanceContext,
            amountFormatter: AssetBalanceFormatterFactory().createDisplayFormatter(for: info),
            priceFormatter: priceFormatter,
            precision: info.assetPrecision
        )
        view?.controller.present(balanceLocksController, animated: true)
    }

    func presentNodeSelection(
        from view: ControllerBackedProtocol?,
        chain: ChainModel
    ) {
        guard let controller = NodeSelectionViewFactory.createView(chain: chain)?.controller else {
            return
        }

        view?.controller.present(controller, animated: true)
    }

    func showExport(
        for address: String,
        chain: ChainModel,
        options: [ExportOption],
        locale: Locale?,
        from view: ControllerBackedProtocol?
    ) {
        performExportPresentation(
            for: address,
            chain: chain,
            options: options,
            locale: locale,
            from: view
        )
    }

    func showUniqueChainSourceSelection(
        from view: ControllerBackedProtocol?,
        items: [ReplaceChainOption],
        callback: @escaping ModalPickerSelectionCallback
    ) {
        let actionsView = ModalPickerFactory.createPickerForList(
            items,
            callback: callback,
            context: nil
        )

        guard let actionsView = actionsView else {
            return
        }

        view?.controller.navigationController?.present(actionsView, animated: true)
    }

    func showCreate(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?) {
        guard let createController = AccountCreateViewFactory.createViewForOnboarding(
            model: UsernameSetupModel(username: uniqueChainModel.meta.name),
            flow: .chain(model: uniqueChainModel)
        )?.controller else {
            return
        }
        createController.hidesBottomBarWhenPushed = true
        view?.controller.navigationController?.pushViewController(createController, animated: true)
    }

    func showImport(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?) {
        guard let importController = AccountImportViewFactory.createViewForOnboarding(
            .chain(model: uniqueChainModel)
        )?.controller else {
            return
        }
        importController.hidesBottomBarWhenPushed = true
        view?.controller.navigationController?.pushViewController(importController, animated: true)
    }
}

private extension ChainAccountWireframe {
    func performExportPresentation(
        for address: String,
        chain: ChainModel,
        options: [ExportOption],
        locale: Locale?,
        from view: ControllerBackedProtocol?
    ) {
        let cancelTitle = R.string.localizable
            .commonCancel(preferredLanguages: locale?.rLanguages)

        let actions: [AlertPresentableAction] = options.map { option in
            switch option {
            case .mnemonic:
                let title = R.string.localizable.importMnemonic(preferredLanguages: locale?.rLanguages)
                return AlertPresentableAction(title: title) { [weak self] in
                    self?.authorize(
                        animated: true,
                        cancellable: true,
                        from: view
                    ) { [weak self] success in
                        if success {
                            self?.showMnemonicExport(for: address, chain: chain, from: view)
                        }
                    }
                }
            case .keystore:
                let title = R.string.localizable.importRecoveryJson(preferredLanguages: locale?.rLanguages)
                return AlertPresentableAction(title: title) { [weak self] in
                    self?.authorize(
                        animated: true,
                        cancellable: true,
                        from: view
                    ) { [weak self] success in
                        if success {
                            self?.showKeystoreExport(for: address, chain: chain, from: view)
                        }
                    }
                }
            case .seed:
                let title = R.string.localizable.importRawSeed(preferredLanguages: locale?.rLanguages)
                return AlertPresentableAction(title: title) { [weak self] in
                    self?.authorize(
                        animated: true,
                        cancellable: true,
                        from: view
                    ) { [weak self] success in
                        if success {
                            self?.showSeedExport(for: address, chain: chain, from: view)
                        }
                    }
                }
            }
        }

        let title = R.string.localizable.importSourcePickerTitle(preferredLanguages: locale?.rLanguages)
        let alertViewModel = AlertPresentableViewModel(
            title: title,
            message: nil,
            actions: actions,
            closeAction: cancelTitle
        )

        present(
            viewModel: alertViewModel,
            style: .actionSheet,
            from: view
        )
    }

    func showMnemonicExport(
        for address: String,
        chain: ChainModel,
        from view: ControllerBackedProtocol?
    ) {
        guard let mnemonicView = ExportMnemonicViewFactory.createViewForAddress(
            flow: .single(chain: chain, address: address)
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            mnemonicView.controller,
            animated: true
        )
    }

    func showKeystoreExport(
        for address: String,
        chain: ChainModel,
        from view: ControllerBackedProtocol?
    ) {
        guard let passwordView = AccountExportPasswordViewFactory.createView(
            flow: .single(chain: chain, address: address)
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            passwordView.controller,
            animated: true
        )
    }

    func showSeedExport(for address: String, chain: ChainModel, from view: ControllerBackedProtocol?) {
        guard let seedView = ExportSeedViewFactory.createViewForAddress(flow: .single(chain: chain, address: address)) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            seedView.controller,
            animated: true
        )
    }
}
