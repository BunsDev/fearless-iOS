import UIKit
import SoraFoundation
import SoraKeystore
import IrohaCrypto
import SSFUtils
import RobinHood

final class ProfileViewFactory: ProfileViewFactoryProtocol {
    static func createView() -> ProfileViewProtocol? {
        guard let selectedMetaAccount = SelectedWalletSettings.shared.value else { return nil }
        let localizationManager = LocalizationManager.shared
        let repository = AccountRepositoryFactory(storageFacade: UserDataStorageFacade.shared)
            .createManagedMetaAccountRepository(
                for: nil,
                sortDescriptors: [NSSortDescriptor.accountsByOrder]
            )
        let settings = SettingsManager.shared
        let profileViewModelFactory = ProfileViewModelFactory(
            iconGenerator: UniversalIconGenerator(),
            biometry: BiometryAuth(),
            settings: settings
        )

        let eventCenter = EventCenter.shared
        let logger = Logger.shared

        let accountRepositoryFactory = AccountRepositoryFactory(storageFacade: UserDataStorageFacade.shared)
        let accountRepository = accountRepositoryFactory.createMetaAccountRepository(for: nil, sortDescriptors: [])

        let priceLocalSubscriptionFactory = PriceProviderFactory(
            storageFacade: SubstrateDataStorageFacade.shared
        )

        let chainRepository = ChainRepositoryFactory().createRepository(
            sortDescriptors: [NSSortDescriptor.chainsByAddressPrefix]
        )

        let substrateRepositoryFactory = SubstrateRepositoryFactory(
            storageFacade: UserDataStorageFacade.shared
        )

        let accountInfoRepository = substrateRepositoryFactory.createAccountInfoStorageItemRepository()

        let substrateAccountInfoFetching = AccountInfoFetching(
            accountInfoRepository: accountInfoRepository,
            chainRegistry: ChainRegistryFacade.sharedRegistry,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        let chainAssetFetching = ChainAssetsFetching(
            chainRepository: AnyDataProviderRepository(chainRepository),
            accountInfoFetching: substrateAccountInfoFetching,
            operationQueue: OperationManagerFacade.sharedDefaultQueue,
            meta: selectedMetaAccount
        )

        let walletBalanceSubscriptionAdapter = WalletBalanceSubscriptionAdapter(
            metaAccountRepository: AnyDataProviderRepository(accountRepository),
            priceLocalSubscriptionFactory: priceLocalSubscriptionFactory,
            chainAssetFetcher: chainAssetFetching,
            operationQueue: OperationManagerFacade.sharedDefaultQueue,
            eventCenter: eventCenter,
            logger: logger
        )

        let missingAccountHelper = MissingAccountFetcher(
            chainRepository: AnyDataProviderRepository(chainRepository),
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        // TODO: Eth account info fetching
        let chainsIssuesCenter = ChainsIssuesCenter(
            wallet: selectedMetaAccount,
            networkIssuesCenter: NetworkIssuesCenter.shared,
            eventCenter: EventCenter.shared,
            missingAccountHelper: missingAccountHelper,
            accountInfoFetcher: substrateAccountInfoFetching
        )

        let interactor = ProfileInteractor(
            selectedWalletSettings: SelectedWalletSettings.shared,
            eventCenter: EventCenter.shared,
            repository: repository,
            operationQueue: OperationManagerFacade.sharedDefaultQueue,
            selectedMetaAccount: selectedMetaAccount,
            walletBalanceSubscriptionAdapter: walletBalanceSubscriptionAdapter,
            walletRepository: accountRepository,
            chainsIssuesCenter: chainsIssuesCenter
        )

        let presenter = ProfilePresenter(
            viewModelFactory: profileViewModelFactory,
            interactor: interactor,
            wireframe: ProfileWireframe(),
            logger: Logger.shared,
            settings: settings,
            eventCenter: EventCenter.shared,
            localizationManager: localizationManager
        )

        let view = ProfileViewController(
            presenter: presenter,
            iconGenerating: UniversalIconGenerator(),
            localizationManager: localizationManager
        )

        return view
    }
}
