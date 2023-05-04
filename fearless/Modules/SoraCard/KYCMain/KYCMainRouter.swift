import Foundation

final class KYCMainRouter: KYCMainRouterInput {
    func showSwap(from view: ControllerBackedProtocol?, wallet: MetaAccountModel, chainAsset: ChainAsset) {
        guard let module = PolkaswapAdjustmentAssembly.configureModule(swapChainAsset: chainAsset, swapVariant: .desiredOutput, wallet: wallet) else {
            return
        }
        let navigationController = FearlessNavigationController(rootViewController: module.view.controller)

        view?.controller.navigationController?.present(
            navigationController,
            animated: true
        )
    }

    func showBuyXor(from view: ControllerBackedProtocol?, wallet: MetaAccountModel, chainAsset: ChainAsset) {
        guard let module = SCXOneAssembly.configureModule(wallet: wallet, chainAsset: chainAsset) else {
            return
        }
        let navigationController = FearlessNavigationController(rootViewController: module.view.controller)

        view?.controller.navigationController?.present(
            navigationController,
            animated: true
        )
    }

    func showTermsAndConditions(from view: ControllerBackedProtocol?) {
        guard let module = TermsAndConditionsAssembly.configureModule() else {
            return
        }
        let navigationController = FearlessNavigationController(rootViewController: module.view.controller)

        view?.controller.present(navigationController, animated: true)
    }

    func showGetPrepared(from view: ControllerBackedProtocol?, data: SCKYCUserDataModel) {
        guard let module = PreparationAssembly.configureModule(data: data) else {
            return
        }
        let navigationController = FearlessNavigationController(rootViewController: module.view.controller)

        view?.controller.present(navigationController, animated: true)
    }

    func showStatus(from view: ControllerBackedProtocol?) {
        guard let module = VerificationStatusAssembly.configureModule() else {
            return
        }
        view?.controller.navigationController?.pushViewController(
            module.view.controller,
            animated: true
        )
    }

    func showSelectNetwork(
        from view: ControllerBackedProtocol?,
        wallet: MetaAccountModel,
        chainModels: [ChainModel]?,
        delegate: SelectNetworkDelegate?
    ) {
        guard
            let module = SelectNetworkAssembly.configureModule(
                wallet: wallet,
                selectedChainId: nil,
                chainModels: chainModels,
                includingAllNetworks: false,
                searchTextsViewModel: nil,
                delegate: delegate
            )
        else {
            return
        }

        view?.controller.present(module.view.controller, animated: true)
    }

    func dismiss(view: ControllerBackedProtocol?) {
        view?.controller.dismiss(animated: true)
    }
}
