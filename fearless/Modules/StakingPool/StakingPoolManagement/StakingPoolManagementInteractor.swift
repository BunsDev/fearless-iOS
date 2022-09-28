import UIKit
import RobinHood

final class StakingPoolManagementInteractor {
    // MARK: - Private properties

    private weak var output: StakingPoolManagementInteractorOutput?
    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    private var stakingPoolOperationFactory: StakingPoolOperationFactoryProtocol
    private var chainAsset: ChainAsset
    private var wallet: MetaAccountModel
    private var eraValidatorService: EraValidatorServiceProtocol
    private let operationManager: OperationManagerProtocol
    private let chainRegistry: ChainRegistryProtocol
    private var eraCountdownOperationFactory: EraCountdownOperationFactoryProtocol
    private(set) var stakingLocalSubscriptionFactory: RelaychainStakingLocalSubscriptionFactoryProtocol
    private let accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapter
    private let stakingDurationOperationFactory: StakingDurationOperationFactoryProtocol
    private let runtimeService: RuntimeCodingServiceProtocol

    private var priceProvider: AnySingleValueProvider<PriceData>?
    private var poolMemberProvider: AnyDataProvider<DecodedPoolMember>?

    init(
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        stakingPoolOperationFactory: StakingPoolOperationFactoryProtocol,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        eraValidatorService: EraValidatorServiceProtocol,
        operationManager: OperationManagerProtocol,
        chainRegistry: ChainRegistryProtocol,
        eraCountdownOperationFactory: EraCountdownOperationFactoryProtocol,
        stakingLocalSubscriptionFactory: RelaychainStakingLocalSubscriptionFactoryProtocol,
        accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapter,
        stakingDurationOperationFactory: StakingDurationOperationFactoryProtocol,
        runtimeService: RuntimeCodingServiceProtocol
    ) {
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.stakingPoolOperationFactory = stakingPoolOperationFactory
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.eraValidatorService = eraValidatorService
        self.operationManager = operationManager
        self.chainRegistry = chainRegistry
        self.eraCountdownOperationFactory = eraCountdownOperationFactory
        self.stakingLocalSubscriptionFactory = stakingLocalSubscriptionFactory
        self.accountInfoSubscriptionAdapter = accountInfoSubscriptionAdapter
        self.stakingDurationOperationFactory = stakingDurationOperationFactory
        self.runtimeService = runtimeService
    }

    private func provideEraStakersInfo() {
        let operation = eraValidatorService.fetchInfoOperation()

        operation.completionBlock = {
            DispatchQueue.main.async { [weak self] in
                do {
                    let info = try operation.extractNoCancellableResultData()
                    self?.output?.didReceive(eraStakersInfo: info)
                    self?.fetchEraCompletionTime()
                } catch {
                    self?.output?.didReceive(eraStakersInfoError: error)
                }
            }
        }

        operationManager.enqueue(operations: [operation], in: .transient)
    }

    private func fetchEraCompletionTime() {
        let chainId = chainAsset.chain.chainId

        guard let runtimeService = chainRegistry.getRuntimeProvider(for: chainId) else {
            output?.didReceive(eraCountdownResult: .failure(ChainRegistryError.runtimeMetadaUnavailable))
            return
        }

        guard let connection = chainRegistry.getConnection(for: chainId) else {
            output?.didReceive(eraCountdownResult: .failure(ChainRegistryError.connectionUnavailable))
            return
        }

        let operationWrapper = eraCountdownOperationFactory.fetchCountdownOperationWrapper(
            for: connection,
            runtimeService: runtimeService
        )

        operationWrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let result = try operationWrapper.targetOperation.extractNoCancellableResultData()
                    self?.output?.didReceive(eraCountdownResult: .success(result))
                } catch {
                    self?.output?.didReceive(eraCountdownResult: .failure(error))
                }
            }
        }
        operationManager.enqueue(operations: operationWrapper.allOperations, in: .transient)
    }

    private func fetchPoolInfo(poolId: String) {
        let fetchPoolInfoOperation = stakingPoolOperationFactory.fetchBondedPoolOperation(poolId: poolId)
        fetchPoolInfoOperation.targetOperation.completionBlock = { [weak self] in
            do {
                let stakingPool = try fetchPoolInfoOperation.targetOperation.extractNoCancellableResultData()

                DispatchQueue.main.async {
                    self?.output?.didReceive(stakingPool: stakingPool)
                }
            } catch {}
        }

        operationManager.enqueue(operations: fetchPoolInfoOperation.allOperations, in: .transient)
    }

    private func fetchStakingDuration() {
        let durationOperation = stakingDurationOperationFactory.createDurationOperation(from: runtimeService)

        durationOperation.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let stakingDuration = try durationOperation.targetOperation.extractNoCancellableResultData()
                    self?.output?.didReceive(stakingDuration: stakingDuration)
                } catch {
                    self?.output?.didReceive(error: error)
                }
            }
        }

        operationManager.enqueue(operations: durationOperation.allOperations, in: .transient)
    }

    private func fetchPoolRewards(poolId: String) {
        let stakeInfoOperation = stakingPoolOperationFactory.fetchPoolRewardsOperation(poolId: poolId)

        stakeInfoOperation.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let poolRewards = try stakeInfoOperation.targetOperation.extractNoCancellableResultData()
                    self?.output?.didReceive(poolRewards: poolRewards)
                } catch {
                    self?.output?.didReceive(poolRewardsError: error)
                }
            }
        }

        operationManager.enqueue(operations: stakeInfoOperation.allOperations, in: .transient)
    }
}

// MARK: - StakingPoolManagementInteractorInput

extension StakingPoolManagementInteractor: StakingPoolManagementInteractorInput {
    func setup(with output: StakingPoolManagementInteractorOutput) {
        self.output = output

        if let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            poolMemberProvider = subscribeToPoolMembers(for: accountId, chainAsset: chainAsset)
        }

        if let priceId = chainAsset.asset.priceId {
            priceProvider = subscribeToPrice(for: priceId)
        }

        if let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            accountInfoSubscriptionAdapter.subscribe(
                chainAsset: chainAsset,
                accountId: accountId,
                handler: self
            )
        }

        provideEraStakersInfo()
        fetchStakingDuration()
    }
}

extension StakingPoolManagementInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, priceId: AssetModel.PriceId) {
        guard chainAsset.asset.priceId == priceId else {
            return
        }

        switch result {
        case let .success(priceData):
            output?.didReceive(priceData: priceData)
        case let .failure(error):
            output?.didReceive(priceError: error)
        }
    }
}

extension StakingPoolManagementInteractor: RelaychainStakingLocalStorageSubscriber, RelaychainStakingLocalSubscriptionHandler {
    func handlePoolMember(
        result: Result<StakingPoolMember?, Error>,
        accountId _: AccountId,
        chainId _: ChainModel.Id
    ) {
        switch result {
        case let .success(poolMember):
            if let poolId = poolMember?.poolId.value {
                fetchPoolInfo(poolId: poolId.description)
                fetchPoolRewards(poolId: poolId.description)
            }

            DispatchQueue.main.async { [weak self] in
                self?.output?.didReceive(stakeInfo: poolMember)
            }
        case let .failure(error):
            DispatchQueue.main.async { [weak self] in
                self?.output?.didReceive(stakeInfoError: error)
            }
        }
    }
}

extension StakingPoolManagementInteractor: AccountInfoSubscriptionAdapterHandler {
    func handleAccountInfo(result: Result<AccountInfo?, Error>, accountId _: AccountId, chainAsset _: ChainAsset) {
        output?.didReceiveAccountInfo(result: result)
    }
}