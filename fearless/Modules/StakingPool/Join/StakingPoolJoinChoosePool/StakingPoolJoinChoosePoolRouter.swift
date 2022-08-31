import Foundation
import SoraFoundation

final class StakingPoolJoinChoosePoolRouter: StakingPoolJoinChoosePoolRouterInput {
    func presentConfirm(
        from view: ControllerBackedProtocol?,
        chainAsset: ChainAsset,
        wallet: MetaAccountModel,
        inputAmount: Decimal,
        selectedPool: StakingPool
    ) {
        guard let module = StakingPoolJoinConfirmAssembly.configureModule(
            chainAsset: chainAsset,
            wallet: wallet,
            inputAmount: inputAmount,
            selectedPool: selectedPool
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            module.view.controller,
            animated: true
        )
    }

    func presentOptions(
        options: [SortPickerTableViewCellModel],
        callback: ModalPickerSelectionCallback?,
        from view: ControllerBackedProtocol?
    ) {
        guard let picker = ModalPickerFactory.createPickerForSortOptions(
            options: options,
            callback: callback
        ) else {
            return
        }

        view?.controller.present(picker, animated: true)
    }
}
