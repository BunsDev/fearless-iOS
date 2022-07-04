import Foundation
import FearlessUtils
import SoraKeystore
import SoraFoundation

final class SelectValidatorsStartViewFactory: SelectValidatorsStartViewFactoryProtocol {
    static func createInitiatedBondingView(
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        flow: SelectValidatorsStartFlow
    ) -> SelectValidatorsStartViewProtocol? {
        let wireframe = InitBondingSelectValidatorsStartWireframe()
        return createView(
            wallet: wallet,
            chainAsset: chainAsset,
            wireframe: wireframe,
            flow: flow
        )
    }

    static func createChangeTargetsView(
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        flow: SelectValidatorsStartFlow
    ) -> SelectValidatorsStartViewProtocol? {
        let wireframe = ChangeTargetsSelectValidatorsStartWireframe()
        return createView(
            wallet: wallet,
            chainAsset: chainAsset,
            wireframe: wireframe,
            flow: flow
        )
    }

    static func createChangeYourValidatorsView(
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        flow: SelectValidatorsStartFlow
    ) -> SelectValidatorsStartViewProtocol? {
        let wireframe = YourValidatorList.SelectionStartWireframe()
        return createView(
            wallet: wallet,
            chainAsset: chainAsset,
            wireframe: wireframe,
            flow: flow
        )
    }

    private static func createView(
        wallet: MetaAccountModel,
        chainAsset: ChainAsset,
        wireframe: SelectValidatorsStartWireframeProtocol,
        flow: SelectValidatorsStartFlow
    ) -> SelectValidatorsStartViewProtocol? {
        guard let container = createContainer(
            flow: flow,
            chainAsset: chainAsset
        ) else {
            return nil
        }

        let interactor = SelectValidatorsStartInteractor(
            strategy: container.strategy
        )

        let presenter = SelectValidatorsStartPresenter(
            interactor: interactor,
            wireframe: wireframe,
            logger: Logger.shared,
            chainAsset: chainAsset,
            wallet: wallet,
            viewModelState: container.viewModelState,
            viewModelFactory: container.viewModelFactory
        )

        let view = SelectValidatorsStartViewController(
            presenter: presenter,
            phase: flow.phase,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        view.localizationManager = LocalizationManager.shared

        return view
    }

    // swiftlint:disable function_body_length
    private static func createContainer(
        flow: SelectValidatorsStartFlow,
        chainAsset: ChainAsset
    ) -> SelectValidatorsStartDependencyContainer? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let substrateStorageFacade = SubstrateDataStorageFacade.shared

        guard
            let connection = chainRegistry.getConnection(for: chainAsset.chain.chainId),
            let runtimeService = chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId) else {
            return nil
        }

        let stakingSettings = StakingAssetSettings(
            storageFacade: substrateStorageFacade,
            settings: SettingsManager.shared,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        stakingSettings.setup()

        let serviceFactory = StakingServiceFactory(
            chainRegisty: ChainRegistryFacade.sharedRegistry,
            storageFacade: substrateStorageFacade,
            eventCenter: EventCenter.shared,
            operationManager: OperationManagerFacade.sharedManager
        )

        guard
            let settings = stakingSettings.value,
            let eraValidatorService = try? serviceFactory.createEraValidatorService(
                for: settings.chain
            ) else {
            return nil
        }

        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: OperationManagerFacade.sharedManager
        )

        let subqueryRewardOperationFactory = SubqueryRewardOperationFactory(url: chainAsset.chain.externalApi?.staking?.url)
        let collatorOperationFactory = ParachainCollatorOperationFactory(
            asset: chainAsset.asset,
            chain: chainAsset.chain,
            storageRequestFactory: storageRequestFactory,
            runtimeService: runtimeService,
            engine: connection,
            identityOperationFactory: IdentityOperationFactory(requestFactory: storageRequestFactory),
            subqueryOperationFactory: subqueryRewardOperationFactory
        )

        guard let rewardService = try? serviceFactory.createRewardCalculatorService(
            for: chainAsset,
            assetPrecision: settings.assetDisplayInfo.assetPrecision,
            validatorService: eraValidatorService,
            collatorOperationFactory: collatorOperationFactory
        ) else {
            return nil
        }

        eraValidatorService.setup()
        rewardService.setup()

        let operationManager = OperationManagerFacade.sharedManager
        let storageOperationFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: operationManager
        )
        let identityOperationFactory = IdentityOperationFactory(requestFactory: storageOperationFactory)

        switch flow {
        case let .relaychainExisting(bonding):
            let operationFactory = RelaychainValidatorOperationFactory(
                asset: chainAsset.asset,
                chain: chainAsset.chain,
                eraValidatorService: eraValidatorService,
                rewardService: rewardService,
                storageRequestFactory: storageOperationFactory,
                runtimeService: runtimeService,
                engine: connection,
                identityOperationFactory: identityOperationFactory
            )

            let viewModelState = SelectValidatorsStartRelaychainExistingViewModelState(
                bonding: bonding,
                initialTargets: bonding.selectedTargets,
                existingStashAddress: bonding.stashAddress
            )

            let strategy = SelectValidatorsStartRelaychainStrategy(
                operationFactory: operationFactory,
                operationManager: operationManager,
                runtimeService: runtimeService,
                output: viewModelState
            )

            let viewModelFactory = SelectValidatorsStartRelaychainViewModelFactory()
            return SelectValidatorsStartDependencyContainer(viewModelState: viewModelState, strategy: strategy, viewModelFactory: viewModelFactory)
        case let .relaychainInitiated(bonding):
            let operationFactory = RelaychainValidatorOperationFactory(
                asset: chainAsset.asset,
                chain: chainAsset.chain,
                eraValidatorService: eraValidatorService,
                rewardService: rewardService,
                storageRequestFactory: storageOperationFactory,
                runtimeService: runtimeService,
                engine: connection,
                identityOperationFactory: identityOperationFactory
            )

            let viewModelState = SelectValidatorsStartRelaychainInitiatedViewModelState(
                bonding: bonding,
                initialTargets: nil,
                existingStashAddress: nil
            )

            let strategy = SelectValidatorsStartRelaychainStrategy(
                operationFactory: operationFactory,
                operationManager: operationManager,
                runtimeService: runtimeService,
                output: viewModelState
            )

            let viewModelFactory = SelectValidatorsStartRelaychainViewModelFactory()
            return SelectValidatorsStartDependencyContainer(viewModelState: viewModelState, strategy: strategy, viewModelFactory: viewModelFactory)
        case let .parachain(bonding):
            let subqueryOperationFactory = SubqueryRewardOperationFactory(
                url: chainAsset.chain.externalApi?.staking?.url
            )

            let operationFactory = ParachainCollatorOperationFactory(
                asset: chainAsset.asset,
                chain: chainAsset.chain,
                storageRequestFactory: storageOperationFactory,
                runtimeService: runtimeService,
                engine: connection,
                identityOperationFactory: identityOperationFactory,
                subqueryOperationFactory: subqueryOperationFactory
            )

            let viewModelState = SelectValidatorsStartParachainViewModelState(bonding: bonding, chainAsset: chainAsset)

            let strategy = SelectValidatorsStartParachainStrategy(
                operationFactory: operationFactory,
                operationManager: operationManager,
                runtimeService: runtimeService,
                output: viewModelState
            )

            let viewModelFactory = SelectValidatorsStartParachainViewModelFactory()
            return SelectValidatorsStartDependencyContainer(
                viewModelState: viewModelState,
                strategy: strategy,
                viewModelFactory: viewModelFactory
            )
        }
    }
}
