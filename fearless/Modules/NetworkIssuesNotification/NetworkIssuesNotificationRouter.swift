import Foundation
import UIKit

final class NetworkIssuesNotificationRouter: NetworkIssuesNotificationRouterInput {
    func dismiss(view: ControllerBackedProtocol?) {
        view?.controller.dismiss(animated: true)
    }

    func presentAccountOptions(
        from view: ControllerBackedProtocol?,
        locale: Locale?,
        options: [MissingAccountOption],
        uniqueChainModel: UniqueChainModel,
        skipBlock: @escaping (ChainModel) -> Void
    ) {
        let cancelTitle = R.string.localizable
            .commonCancel(preferredLanguages: locale?.rLanguages)

        let actions: [AlertPresentableAction] = options.map { option in
            switch option {
            case .create:
                let title = R.string.localizable.createNewAccount(preferredLanguages: locale?.rLanguages)
                return AlertPresentableAction(title: title) { [weak self] in
                    self?.showCreate(uniqueChainModel: uniqueChainModel, from: view)
                }
            case .import:
                let title = R.string.localizable.alreadyHaveAccount(preferredLanguages: locale?.rLanguages)
                return AlertPresentableAction(title: title) { [weak self] in
                    self?.showImport(uniqueChainModel: uniqueChainModel, from: view)
                }
            case .skip:
                let title = R.string.localizable.missingAccountSkip(preferredLanguages: locale?.rLanguages)
                return AlertPresentableAction(title: title) {
                    skipBlock(uniqueChainModel.chain)
                }
            }
        }

        let title = R.string.localizable.importSourcePickerTitle(preferredLanguages: locale?.rLanguages)
        let alertViewModel = AlertPresentableViewModel(
            title: title,
            message: nil,
            actions: actions,
            closeAction: cancelTitle
        )

        present(
            viewModel: alertViewModel,
            style: .actionSheet,
            from: view
        )
    }

    func presentNodeSelection(
        from view: ControllerBackedProtocol?,
        chain: ChainModel
    ) {
        guard let controller = NodeSelectionViewFactory.createView(chain: chain)?.controller else {
            return
        }

        view?.controller.present(controller, animated: true)
    }

    // MARK: - Private methods

    private func showCreate(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?) {
        guard let controller = UsernameSetupViewFactory.createViewForOnboarding(
            flow: .chain(model: uniqueChainModel)
        )?.controller else {
            return
        }

        view?.controller.navigationController?.pushViewController(controller, animated: true)
    }

    private func showImport(uniqueChainModel: UniqueChainModel, from view: ControllerBackedProtocol?) {
        guard let importController = AccountImportViewFactory.createViewForOnboarding(
            .chain(model: uniqueChainModel)
        )?.controller else {
            return
        }

        view?.controller.navigationController?.pushViewController(importController, animated: true)
    }
}
