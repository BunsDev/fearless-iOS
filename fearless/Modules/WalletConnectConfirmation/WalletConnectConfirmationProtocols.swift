import SSFModels

typealias WalletConnectConfirmationModuleCreationResult = (
    view: WalletConnectConfirmationViewInput,
    input: WalletConnectConfirmationModuleInput
)

protocol WalletConnectConfirmationRouterInput: PresentDismissable, SheetAlertPresentable, ErrorPresentable {
    func showAllDone(
        chain: ChainModel,
        hashString: String?,
        view: ControllerBackedProtocol?,
        closure: @escaping () -> Void
    )
    func comlete(from view: ControllerBackedProtocol?)
    func showRawData(text: String, from view: ControllerBackedProtocol?)
}

protocol WalletConnectConfirmationModuleInput: AnyObject {}

protocol WalletConnectConfirmationModuleOutput: AnyObject {}