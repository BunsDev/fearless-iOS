final class ChooseRecipientRouter: ChooseRecipientRouterProtocol {
    private let flow: SendFlow
    private let transferFinishBlock: WalletTransferFinishBlock?

    init(flow: SendFlow, transferFinishBlock: WalletTransferFinishBlock?) {
        self.flow = flow
        self.transferFinishBlock = transferFinishBlock
    }

    func presentSendAmount(
        from view: ControllerBackedProtocol?,
        to receiverAddress: String,
        asset: AssetModel,
        chain: ChainModel,
        wallet: MetaAccountModel
    ) {
        guard let controller = WalletSendViewFactory.createView(
            receiverAddress: receiverAddress,
            asset: asset,
            chain: chain,
            wallet: wallet,
            transferFinishBlock: transferFinishBlock
        )?.controller else {
            return
        }
        view?.controller.navigationController?.pushViewController(controller, animated: true)
    }

    func presentScan(
        from view: ControllerBackedProtocol?,
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel,
        moduleOutput: WalletScanQRModuleOutput?
    ) {
        guard let controller = WalletScanQRViewFactory.createView(
            chain: chain,
            asset: asset,
            selectedAccount: selectedAccount,
            moduleOutput: moduleOutput
        )?.controller else {
            return
        }

        view?.controller.present(controller, animated: true, completion: nil)
    }

    func presentHistory(from _: ControllerBackedProtocol?) {
        // TODO: Contact list transition
    }

    func close(_ view: ControllerBackedProtocol?) {
        view?.controller.dismiss(animated: true)
    }
}
