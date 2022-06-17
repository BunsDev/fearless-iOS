import Foundation
import RobinHood
import FearlessUtils
import SoraKeystore

protocol StakingBondMoreConfirmationParachainStrategyOutput: AnyObject {
    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>)
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>)
    func didSubmitBonding(result: Result<String, Error>)
}

final class StakingBondMoreConfirmationParachainStrategy {
    let accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol

    private weak var output: StakingBondMoreConfirmationParachainStrategyOutput?
    private let chainAsset: ChainAsset
    private let wallet: MetaAccountModel
    private var extrinsicService: ExtrinsicServiceProtocol
    private let feeProxy: ExtrinsicFeeProxyProtocol
    private let runtimeService: RuntimeCodingServiceProtocol
    private let operationManager: OperationManagerProtocol
    private let connection: JSONRPCEngine
    private let keystore: KeystoreProtocol

    private var balanceProvider: AnyDataProvider<DecodedAccountInfo>?
    private var signingWrapper: SigningWrapperProtocol

    private lazy var callFactory = SubstrateCallFactory()

    init(
        accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        extrinsicService: ExtrinsicServiceProtocol,
        feeProxy: ExtrinsicFeeProxyProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        operationManager: OperationManagerProtocol,
        connection: JSONRPCEngine,
        keystore: KeystoreProtocol,
        signingWrapper: SigningWrapperProtocol,
        output: StakingBondMoreConfirmationParachainStrategyOutput?
    ) {
        self.accountInfoSubscriptionAdapter = accountInfoSubscriptionAdapter
        self.chainAsset = chainAsset
        self.wallet = wallet
        self.extrinsicService = extrinsicService
        self.feeProxy = feeProxy
        self.runtimeService = runtimeService
        self.operationManager = operationManager
        self.connection = connection
        self.keystore = keystore
        self.signingWrapper = signingWrapper
        self.output = output

        self.feeProxy.delegate = self
    }
}

extension StakingBondMoreConfirmationParachainStrategy: StakingBondMoreConfirmationStrategy {
    func setup() {
        if let accountId = wallet.fetch(for: chainAsset.chain.accountRequest())?.accountId {
            accountInfoSubscriptionAdapter.subscribe(chain: chainAsset.chain, accountId: accountId, handler: self)
        }

        feeProxy.delegate = self
    }

    func estimateFee(builderClosure: ExtrinsicBuilderClosure?, reuseIdentifier: String?) {
        guard let builderClosure = builderClosure,
              let reuseIdentifier = reuseIdentifier else {
            return
        }

        feeProxy.estimateFee(using: extrinsicService, reuseIdentifier: reuseIdentifier, setupBy: builderClosure)
    }

    func submit(builderClosure: ExtrinsicBuilderClosure?) {
        guard let builderClosure = builderClosure else {
            return
        }

        extrinsicService.submit(
            builderClosure,
            signer: signingWrapper,
            runningIn: .main,
            completion: { [weak self] result in
                self?.output?.didSubmitBonding(result: result)
            }
        )
    }
}

extension StakingBondMoreConfirmationParachainStrategy: AccountInfoSubscriptionAdapterHandler {
    func handleAccountInfo(result: Result<AccountInfo?, Error>, accountId _: AccountId, chainId _: ChainModel.Id) {
        output?.didReceiveAccountInfo(result: result)
    }
}

extension StakingBondMoreConfirmationParachainStrategy: AnyProviderAutoCleaning {}

extension StakingBondMoreConfirmationParachainStrategy: ExtrinsicFeeProxyDelegate {
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>, for _: ExtrinsicFeeId) {
        output?.didReceiveFee(result: result)
    }
}