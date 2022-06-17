import Foundation
import RobinHood
import FearlessUtils

protocol StakingBondMoreParachainStrategyOutput: AnyObject {
    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>)
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>)
    func didSetup()

    func extrinsicServiceUpdated()
}

final class StakingBondMoreParachainStrategy {
    private var balanceProvider: AnyDataProvider<DecodedAccountInfo>?

    let accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol

    private weak var output: StakingBondMoreParachainStrategyOutput?
    private let chainAsset: ChainAsset
    private let wallet: MetaAccountModel
    private let connection: JSONRPCEngine
    private var extrinsicService: ExtrinsicServiceProtocol
    private let feeProxy: ExtrinsicFeeProxyProtocol
    private let runtimeService: RuntimeCodingServiceProtocol
    private let operationManager: OperationManagerProtocol

    private lazy var callFactory = SubstrateCallFactory()

    init(
        accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol,
        output: StakingBondMoreParachainStrategyOutput?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        connection: JSONRPCEngine,
        extrinsicService: ExtrinsicServiceProtocol,
        feeProxy: ExtrinsicFeeProxyProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        operationManager: OperationManagerProtocol
    ) {
        self.accountInfoSubscriptionAdapter = accountInfoSubscriptionAdapter
        self.output = output
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.connection = connection
        self.extrinsicService = extrinsicService
        self.feeProxy = feeProxy
        self.runtimeService = runtimeService
        self.operationManager = operationManager

        self.feeProxy.delegate = self
    }
}

extension StakingBondMoreParachainStrategy: StakingBondMoreStrategy {
    func estimateFee(builderClosure: ExtrinsicBuilderClosure?, reuseIdentifier: String?) {
        guard let reuseIdentifier = reuseIdentifier, let builderClosure = builderClosure else {
            return
        }

        feeProxy.estimateFee(using: extrinsicService, reuseIdentifier: reuseIdentifier, setupBy: builderClosure)
    }

    func setup() {
        if let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            accountInfoSubscriptionAdapter.subscribe(
                chain: chainAsset.chain,
                accountId: accountId,
                handler: self
            )
        }

        output?.didSetup()
    }
}

extension StakingBondMoreParachainStrategy: AnyProviderAutoCleaning {}

extension StakingBondMoreParachainStrategy: ExtrinsicFeeProxyDelegate {
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>, for _: ExtrinsicFeeId) {
        output?.didReceiveFee(result: result)
    }
}

extension StakingBondMoreParachainStrategy: AccountInfoSubscriptionAdapterHandler {
    func handleAccountInfo(result: Result<AccountInfo?, Error>, accountId _: AccountId, chainId _: ChainModel.Id) {
        output?.didReceiveAccountInfo(result: result)
    }
}
