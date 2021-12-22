import Foundation
import SoraFoundation
import SoraKeystore
import FearlessUtils
import RobinHood

final class StakingPayoutConfirmationViewFactory: StakingPayoutConfirmationViewFactoryProtocol {
    static func createView(
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel,
        payouts: [PayoutInfo]
    ) -> StakingPayoutConfirmationViewProtocol? {
        let balanceViewModelFactory = BalanceViewModelFactory(
            targetAssetInfo: asset.displayInfo,
            limit: StakingConstants.maxAmount
        )

        let payoutConfirmViewModelFactory = StakingPayoutConfirmViewModelFactory(
            asset: asset,
            balanceViewModelFactory: balanceViewModelFactory
        )

        let wireframe = StakingPayoutConfirmationWireframe()

        let dataValidationFactory = StakingDataValidatingFactory(
            presentable: wireframe,
            balanceFactory: balanceViewModelFactory
        )

        let presenter = StakingPayoutConfirmationPresenter(
            balanceViewModelFactory: balanceViewModelFactory,
            payoutConfirmViewModelFactory: payoutConfirmViewModelFactory,
            dataValidatingFactory: dataValidationFactory,
            chain: chain,
            asset: asset,
            logger: Logger.shared
        )

        let view = StakingPayoutConfirmationViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        guard let interactor = createInteractor(
            chain: chain,
            asset: asset,
            selectedAccount: selectedAccount,
            payouts: payouts
        ) else {
            return nil
        }

        dataValidationFactory.view = view
        presenter.view = view
        presenter.interactor = interactor
        presenter.wireframe = wireframe
        interactor.presenter = presenter

        return view
    }

    private static func createInteractor(
        chain: ChainModel,
        asset: AssetModel,
        selectedAccount: MetaAccountModel,
        payouts: [PayoutInfo]
    ) -> StakingPayoutConfirmationInteractor? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry

        guard
            let connection = chainRegistry.getConnection(for: chain.chainId),
            let runtimeService = chainRegistry.getRuntimeProvider(for: chain.chainId),
            let accountResponse = selectedAccount.fetch(for: chain.accountRequest()) else {
            return nil
        }

        let operationManager = OperationManagerFacade.sharedManager

        let extrinsicService = ExtrinsicService(
            accountId: accountResponse.accountId,
            chainFormat: chain.chainFormat,
            cryptoType: accountResponse.cryptoType,
            runtimeRegistry: runtimeService,
            engine: connection,
            operationManager: operationManager
        )

        let extrinsicOperationFactory = ExtrinsicOperationFactory(
            accountId: accountResponse.accountId,
            chainFormat: chain.chainFormat,
            cryptoType: accountResponse.cryptoType,
            runtimeRegistry: runtimeService,
            engine: connection
        )

        let substrateStorageFacade = SubstrateDataStorageFacade.shared
        let logger = Logger.shared

        let priceLocalSubscriptionFactory = PriceProviderFactory(storageFacade: substrateStorageFacade)
        let stakingLocalSubscriptionFactory = StakingLocalSubscriptionFactory(
            chainRegistry: chainRegistry,
            storageFacade: substrateStorageFacade,
            operationManager: operationManager,
            logger: Logger.shared
        )
        let walletLocalSubscriptionFactory = WalletLocalSubscriptionFactory(
            chainRegistry: chainRegistry,
            storageFacade: substrateStorageFacade,
            operationManager: operationManager,
            logger: logger
        )

        let keystore = Keychain()
        let signingWrapper = SigningWrapper(
            keystore: keystore,
            metaId: selectedAccount.metaId,
            accountResponse: accountResponse
        )

        return StakingPayoutConfirmationInteractor(
            stakingLocalSubscriptionFactory: stakingLocalSubscriptionFactory,
            walletLocalSubscriptionFactory: walletLocalSubscriptionFactory,
            priceLocalSubscriptionFactory: priceLocalSubscriptionFactory,
            extrinsicService: extrinsicService,
            extrinsicOperationFactory: extrinsicOperationFactory,
            runtimeService: runtimeService,
            signer: signingWrapper,
            operationManager: operationManager,
            logger: logger,
            selectedAccount: selectedAccount,
            payouts: payouts,
            chain: chain,
            asset: asset
        )
    }
}
