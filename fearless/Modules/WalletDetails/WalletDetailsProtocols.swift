import SoraFoundation

protocol WalletDetailsViewOutputProtocol {
    func didLoad(ui: WalletDetailsViewProtocol)
    func updateData()
    func didTapCloseButton()
    func didTapExportButton()
    func willDisappear()
    func showActions(for chain: ChainModel, account: ChainAccountResponse?)
}

protocol WalletDetailsViewProtocol: ControllerBackedProtocol {
    func didReceive(state: WalletDetailsViewState)
    func setInput(viewModel: InputViewModelProtocol)
}

protocol WalletDetailsInteractorInputProtocol: AnyObject {
    func setup()
    func update(walletName: String)
    func getAvailableExportOptions(for chainAccount: ChainAccountInfo)
    func markUnused(chain: ChainModel)
}

protocol WalletDetailsInteractorOutputProtocol: AnyObject {
    func didReceive(chains: [ChainModel])
    func didReceiveExportOptions(options: [ExportOption], for chainAccount: ChainAccountInfo)
    func didReceive(error: Error)
    func didReceive(updatedFlow: WalletDetailsFlow)
}

protocol WalletDetailsWireframeProtocol: ErrorPresentable,
    AlertPresentable,
    ModalAlertPresenting,
    AuthorizationPresentable {
    func close(_ view: WalletDetailsViewProtocol)
    func presentActions(
        from view: ControllerBackedProtocol?,
        items: [ChainAction],
        callback: @escaping ModalPickerSelectionCallback
    )

    func showExport(
        flow: ExportFlow,
        options: [ExportOption],
        locale: Locale?,
        from view: ControllerBackedProtocol?
    )

    func presentNodeSelection(
        from view: ControllerBackedProtocol?,
        chain: ChainModel
    )
    func present(
        from view: ControllerBackedProtocol,
        url: URL
    )

    func showUniqueChainSourceSelection(
        from view: ControllerBackedProtocol?,
        items: [ReplaceChainOption],
        callback: @escaping ModalPickerSelectionCallback
    )

    func showCreate(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?)
    func showImport(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?)

    func presentAccountOptions(
        from view: ControllerBackedProtocol?,
        locale: Locale?,
        options: [MissingAccountOption],
        uniqueChainModel: UniqueChainModel,
        skipBlock: @escaping (ChainModel) -> Void
    )
}
