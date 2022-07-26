import Foundation
import SoraFoundation
import FearlessUtils

final class RecommendedValidatorListViewFactory: RecommendedValidatorListViewFactoryProtocol {
    static func createView(
        flow: RecommendedValidatorListFlow,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel
    ) -> RecommendedValidatorListViewProtocol? {
        guard let container = createContainer(flow: flow, chainAsset: chainAsset) else {
            return nil
        }

        let wireframe = RecommendedValidatorListWireframe()
        let view = RecommendedValidatorListViewController(nib: R.nib.recommendedValidatorListViewController)

        let presenter = RecommendedValidatorListPresenter(
            viewModelFactory: container.viewModelFactory,
            viewModelState: container.viewModelState,
            logger: Logger.shared,
            chainAsset: chainAsset,
            wallet: wallet
        )

        view.presenter = presenter
        presenter.view = view
        presenter.wireframe = wireframe

        view.localizationManager = LocalizationManager.shared

        return view
    }

    static func createContainer(
        flow: RecommendedValidatorListFlow,
        chainAsset: ChainAsset
    ) -> RecommendedValidatorListDependencyContainer? {
        switch flow {
        case let .relaychainInitiated(validators, maxTargets, bonding):
            let viewModelState = RecommendedValidatorListRelaychainInitiatedViewModelState(
                bonding: bonding,
                validators: validators,
                maxTargets: maxTargets
            )
            let strategy = RecommendedValidatorListRelaychainStrategy()
            let viewModelFactory = RecommendedValidatorListRelaychainViewModelFactory(
                iconGenerator: UniversalIconGenerator(chain: chainAsset.chain)
            )
            return RecommendedValidatorListDependencyContainer(
                viewModelState: viewModelState,
                strategy: strategy,
                viewModelFactory: viewModelFactory
            )
        case let .relaychainExisting(validators, maxTargets, bonding):
            let viewModelState = RecommendedValidatorListRelaychainExistingViewModelState(
                bonding: bonding,
                validators: validators,
                maxTargets: maxTargets
            )
            let strategy = RecommendedValidatorListRelaychainStrategy()
            let viewModelFactory = RecommendedValidatorListRelaychainViewModelFactory(
                iconGenerator: UniversalIconGenerator(chain: chainAsset.chain)
            )
            return RecommendedValidatorListDependencyContainer(
                viewModelState: viewModelState,
                strategy: strategy,
                viewModelFactory: viewModelFactory
            )
        case let .parachain(collators, maxTargets, bonding):
            let viewModelState = RecommendedValidatorListParachainViewModelState(
                collators: collators,
                bonding: bonding,
                maxTargets: maxTargets
            )
            let strategy = RecommendedValidatorListParachainStrategy()
            let viewModelFactory = RecommendedValidatorListParachainViewModelFactory(
                iconGenerator: UniversalIconGenerator(chain: chainAsset.chain)
            )
            return RecommendedValidatorListDependencyContainer(
                viewModelState: viewModelState,
                strategy: strategy,
                viewModelFactory: viewModelFactory
            )
        }
    }
}
