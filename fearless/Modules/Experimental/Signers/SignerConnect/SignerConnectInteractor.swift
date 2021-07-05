import UIKit
import BeaconSDK
import IrohaCrypto
import RobinHood

final class SignerConnectInteractor {
    weak var presenter: SignerConnectInteractorOutputProtocol!

    private var client: Beacon.Client?

    let selectedAddress: AccountAddress
    let accountRepository: AnyDataProviderRepository<AccountItem>
    let operationManager: OperationManagerProtocol
    let peer: Beacon.P2PPeer
    let connectionInfo: BeaconConnectionInfo
    let logger: LoggerProtocol?

    init(
        selectedAddress: AccountAddress,
        accountRepository: AnyDataProviderRepository<AccountItem>,
        operationManager: OperationManagerProtocol,
        info: BeaconConnectionInfo,
        logger: LoggerProtocol? = nil
    ) {
        peer = Beacon.P2PPeer(
            id: info.identifier,
            name: info.name,
            publicKey: info.publicKey,
            relayServer: info.relayServer,
            version: info.name,
            icon: info.icon,
            appURL: nil
        )

        self.selectedAddress = selectedAddress
        self.accountRepository = accountRepository
        self.operationManager = operationManager
        connectionInfo = info
        self.logger = logger
    }

    deinit {
        client?.remove([.p2p(peer)], completion: { _ in })
    }

    private func connect(using client: Beacon.Client) {
        self.client = client

        logger?.debug("Did create client")

        client.connect { [weak self] result in
            switch result {
            case .success:
                self?.logger?.debug("Did connect")
                self?.addPeer()
            case let .failure(error):
                self?.logger?.error("Could not connect, got error: \(error)")
                self?.client = nil
                self?.provideConnection(result: .failure(error))
            }
        }
    }

    private func addPeer() {
        logger?.debug("Will add peer")

        client?.add([.p2p(peer)]) { [weak self] result in
            switch result {
            case .success:
                self?.logger?.debug("Did add peer")
                self?.provideConnection(result: .success(()))
                self?.startListenRequests()
            case let .failure(error):
                self?.logger?.error("Error while adding peer: \(error)")
                self?.client = nil
                self?.provideConnection(result: .failure(error))
            }
        }
    }

    private func startListenRequests() {
        logger?.debug("Will start listen requests")
        client?.listen { [weak self] result in
            self?.onBeaconRequest(result: result)
        }
    }

    private func onBeaconRequest(result: Result<Beacon.Request, Beacon.Error>) {
        switch result {
        case let .success(request):
            DispatchQueue.main.async {
                self.handle(request: request)
            }
        case let .failure(error):
            logger?.error("Error while processing incoming messages: \(error)")
        }
    }

    private func handle(request: Beacon.Request) {
        switch request {
        case let .permission(permission):
            handle(permission: permission)
        case let .broadcast(broadcast):
            handle(broadcast: broadcast)
        case let .operation(operation):
            handle(operation: operation)
        case let .signPayload(signPaload):
            handle(signPayload: signPaload)
        }
    }

    private func handle(permission: Beacon.Request.Permission) {
        logger?.debug("Permission request: \(permission)")

        guard let accountId = try? SS58AddressFactory().accountId(from: selectedAddress) else {
            logger?.error("Can't extract accountId")
            return
        }

        let response = Beacon.Response.Permission(from: permission, publicKey: accountId.toHex())

        client?.respond(with: Beacon.Response.permission(response)) { [weak self] result in
            switch result {
            case .success:
                self?.logger?.debug("Permission response submitted")
            case let .failure(error):
                self?.logger?.error("Did receive permission error: \(error)")
            }
        }
    }

    private func handle(broadcast: Beacon.Request.Broadcast) {
        logger?.info("Broadcast request: \(broadcast)")
    }

    private func handle(operation: Beacon.Request.Operation) {
        logger?.info("Operation request: \(operation)")
    }

    private func handle(signPayload: Beacon.Request.SignPayload) {
        logger?.info("Signing request: \(signPayload)")
    }

    private func provideConnection(result: Result<Void, Error>) {
        DispatchQueue.main.async { [weak self] in
            self?.presenter.didReceiveConnection(result: result)
        }
    }
}

extension SignerConnectInteractor: SignerConnectInteractorInputProtocol, AccountFetching {
    func setup() {
        presenter.didReceiveApp(metadata: connectionInfo)

        fetchAccount(
            for: selectedAddress,
            from: accountRepository,
            operationManager: operationManager
        ) { [weak self] result in
            self?.presenter.didReceive(account: result)
        }
    }

    func connect() {
        Beacon.Client.create(with: Beacon.Client.Configuration(name: "Fearless")) { [weak self] result in
            switch result {
            case let .success(client):
                self?.connect(using: client)
            case let .failure(error):
                self?.logger?.error("Could not create Beacon client, got error: \(error)")
            }
        }
    }
}
