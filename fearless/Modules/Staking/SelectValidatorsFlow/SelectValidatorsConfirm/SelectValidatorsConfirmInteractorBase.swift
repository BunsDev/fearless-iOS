import Foundation
import RobinHood
import BigInt

class SelectValidatorsConfirmInteractorBase: SelectValidatorsConfirmInteractorInputProtocol,
    StakingDurationFetching {
    weak var presenter: SelectValidatorsConfirmInteractorOutputProtocol!

    let chainAsset: ChainAsset
    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    let strategy: SelectValidatorsConfirmStrategy
    let balanceAccountId: AccountId
    let accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol

    private var priceProvider: AnySingleValueProvider<PriceData>?

    init(
        balanceAccountId: AccountId,
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        chainAsset: ChainAsset,
        strategy: SelectValidatorsConfirmStrategy,
        accountInfoSubscriptionAdapter: AccountInfoSubscriptionAdapterProtocol

    ) {
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.chainAsset = chainAsset
        self.strategy = strategy
        self.balanceAccountId = balanceAccountId
        self.accountInfoSubscriptionAdapter = accountInfoSubscriptionAdapter
    }

    // MARK: - SelectValidatorsConfirmInteractorInputProtocol

    func setup() {
        accountInfoSubscriptionAdapter.subscribe(chainAsset: chainAsset, accountId: balanceAccountId, handler: self)

        if let priceId = chainAsset.asset.priceId {
            priceProvider = subscribeToPrice(for: priceId)
        }

        strategy.setup()
    }

    func submitNomination(closure: ExtrinsicBuilderClosure?) {
        strategy.submitNomination(closure: closure)
    }

    func estimateFee(closure: ExtrinsicBuilderClosure?) {
        strategy.estimateFee(closure: closure)
    }
}

extension SelectValidatorsConfirmInteractorBase: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, priceId _: AssetModel.PriceId) {
        presenter.didReceivePrice(result: result)
    }
}

extension SelectValidatorsConfirmInteractorBase: AccountInfoSubscriptionAdapterHandler {
    func handleAccountInfo(result: Result<AccountInfo?, Error>, accountId _: AccountId, chainAsset _: ChainAsset) {
        presenter.didReceiveAccountInfo(result: result)
    }
}
