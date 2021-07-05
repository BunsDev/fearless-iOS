import SoraFoundation

protocol SignerConnectViewProtocol: ControllerBackedProtocol, Localizable {
    func didReceive(viewModel: SignerConnectViewModel)
    func didReceive(status: SignerConnectStatus)
}

protocol SignerConnectPresenterProtocol: AnyObject {
    func setup()
    func presentAccountOptions()
    func changeConnectionStatus()
}

protocol SignerConnectInteractorInputProtocol: AnyObject {
    func setup()
    func connect()
}

protocol SignerConnectInteractorOutputProtocol: AnyObject {
    func didReceive(account: Result<AccountItem?, Error>)
    func didReceiveApp(metadata: BeaconConnectionInfo)
    func didReceiveConnection(result: Result<Void, Error>)
}

protocol SignerConnectWireframeProtocol: AlertPresentable, ErrorPresentable, AddressOptionsPresentable {}
