import Foundation

final class ChangeTargetsRecommendationWireframe: RecommendedValidatorListWireframe {
    let state: ExistingBonding

    init(state: ExistingBonding) {
        self.state = state
    }

    override func proceed(
        from view: RecommendedValidatorListViewProtocol?,
        targets: [SelectedValidatorInfo],
        maxTargets: Int
    ) {
        let nomination = PreparedNomination(
            bonding: state,
            targets: targets,
            maxTargets: maxTargets
        )

        guard let confirmView = SelectValidatorsConfirmViewFactory.createChangeTargetsView(for: nomination) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            confirmView.controller,
            animated: true
        )
    }
}