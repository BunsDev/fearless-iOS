import UIKit
import RobinHood
import FearlessUtils

final class StakingRewardPayoutsInteractor {
    weak var presenter: StakingRewardPayoutsInteractorOutputProtocol!

    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    let stakingLocalSubscriptionFactory: StakingLocalSubscriptionFactoryProtocol
    private let payoutService: PayoutRewardsServiceProtocol
    private let asset: AssetModel
    private let chain: ChainModel
    private let eraCountdownOperationFactory: EraCountdownOperationFactoryProtocol
    private let operationManager: OperationManagerProtocol
    private let runtimeService: RuntimeCodingServiceProtocol
    private let logger: LoggerProtocol?
    let connection: JSONRPCEngine

    private var priceProvider: AnySingleValueProvider<PriceData>?
    private var activeEraProvider: AnyDataProvider<DecodedActiveEra>?
    private var payoutOperationsWrapper: CompoundOperationWrapper<PayoutsInfo>?

    deinit {
        let wrapper = payoutOperationsWrapper
        payoutOperationsWrapper = nil
        wrapper?.cancel()
    }

    init(
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        stakingLocalSubscriptionFactory: StakingLocalSubscriptionFactoryProtocol,
        payoutService: PayoutRewardsServiceProtocol,
        asset: AssetModel,
        chain: ChainModel,
        eraCountdownOperationFactory: EraCountdownOperationFactoryProtocol,
        operationManager: OperationManagerProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        logger: LoggerProtocol? = nil,
        connection: JSONRPCEngine
    ) {
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.stakingLocalSubscriptionFactory = stakingLocalSubscriptionFactory
        self.payoutService = payoutService
        self.asset = asset
        self.chain = chain
        self.eraCountdownOperationFactory = eraCountdownOperationFactory
        self.operationManager = operationManager
        self.runtimeService = runtimeService
        self.logger = logger
        self.connection = connection
    }

    private func fetchEraCompletionTime() {
        let operationWrapper = eraCountdownOperationFactory.fetchCountdownOperationWrapper(
            for: connection,
            runtimeService: runtimeService
        )

        operationWrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let result = try operationWrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter.didReceive(eraCountdownResult: .success(result))
                } catch {
                    self?.presenter.didReceive(eraCountdownResult: .failure(error))
                }
            }
        }
        operationManager.enqueue(operations: operationWrapper.allOperations, in: .transient)
    }
}

extension StakingRewardPayoutsInteractor: StakingRewardPayoutsInteractorInputProtocol {
    func setup() {
        if let priceId = asset.priceId {
            priceProvider = subscribeToPrice(for: priceId)
        }

        activeEraProvider = subscribeActiveEra(for: chain.chainId)

        fetchEraCompletionTime()
        reload()
    }

    func reload() {
        guard payoutOperationsWrapper == nil else {
            return
        }

        let wrapper = payoutService.fetchPayoutsOperationWrapper()
        wrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    guard let currentWrapper = self?.payoutOperationsWrapper else {
                        return
                    }

                    self?.payoutOperationsWrapper = nil

                    let payoutsInfo = try currentWrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter?.didReceive(result: .success(payoutsInfo))
                } catch {
                    if let serviceError = error as? PayoutRewardsServiceError {
                        self?.presenter.didReceive(result: .failure(serviceError))
                    } else {
                        self?.presenter.didReceive(result: .failure(.unknown))
                    }
                }
            }
        }

        operationManager.enqueue(operations: wrapper.allOperations, in: .transient)

        payoutOperationsWrapper = wrapper
    }
}

extension StakingRewardPayoutsInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, priceId _: AssetModel.PriceId) {
        presenter.didReceive(priceResult: result)
    }
}

extension StakingRewardPayoutsInteractor: StakingLocalStorageSubscriber, StakingLocalSubscriptionHandler {
    func handleActiveEra(result: Result<ActiveEraInfo?, Error>, chainId _: ChainModel.Id) {
        switch result {
        case .success:
            reload()
            fetchEraCompletionTime()
        case let .failure(error):
            logger?.error(error.localizedDescription)
        }
    }
}
