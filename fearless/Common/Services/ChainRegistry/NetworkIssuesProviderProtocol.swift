import Foundation

protocol NetworkIssuesCenterListener: AnyObject {
    func chainsWithIssues(_ chains: [ChainModel])
}

protocol NetworkIssuesCenterProtocol {
    func addIssuesListener(
        _ listener: NetworkIssuesCenterListener,
        getExisting: Bool
    )
    func removeIssuesListener(_ listener: NetworkIssuesCenterListener)
}

final class NetworkIssuesCenter: NetworkIssuesCenterProtocol {
    static let shared = NetworkIssuesCenter(eventCenter: EventCenter.shared)

    private var issuesListeners: [WeakWrapper] = []

    private var _chainsWithIssues: Set<ChainModel> = []
    private var chainsWithIssues: Set<ChainModel> {
        get {
            _chainsWithIssues
        }
        set(newValue) {
            if newValue != _chainsWithIssues {
                _chainsWithIssues = newValue
                notify()
            }
        }
    }

    private let eventCenter: EventCenter

    private init(eventCenter: EventCenter) {
        self.eventCenter = eventCenter
        self.eventCenter.add(observer: self, dispatchIn: nil)
    }

    // MARK: - Public methods

    func addIssuesListener(
        _ listener: NetworkIssuesCenterListener,
        getExisting: Bool
    ) {
        let weakListener = WeakWrapper(target: listener)
        issuesListeners.append(weakListener)

        guard getExisting, _chainsWithIssues.isNotEmpty else { return }
        let chains = Array(_chainsWithIssues)
        (weakListener.target as? NetworkIssuesCenterListener)?.chainsWithIssues(chains)
    }

    func removeIssuesListener(_ listener: NetworkIssuesCenterListener) {
        issuesListeners = issuesListeners.filter { $0 !== listener }
    }

    // MARK: - Private methods

    private func handle(event: ChainReconnectingEvent) {
        let chain = event.chain
        let state = event.state

        switch state {
        case .notConnected:
            chainsWithIssues.insert(chain)
        case let .connecting(attempt: attempt):
            if attempt > 3 {
                chainsWithIssues.insert(chain)
            }
        case .waitingReconnection:
            break
        case .connected:
            chainsWithIssues.remove(chain)
        }
    }

    private func notify() {
        let chains = Array(_chainsWithIssues)
        issuesListeners.forEach {
            ($0.target as? NetworkIssuesCenterListener)?.chainsWithIssues(chains)
        }
    }
}

// MARK: - EventVisitorProtocol

extension NetworkIssuesCenter: EventVisitorProtocol {
    func processChainReconnecting(event: ChainReconnectingEvent) {
        handle(event: event)
    }
}
