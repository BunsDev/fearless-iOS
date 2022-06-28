import Foundation
import RobinHood
import SoraFoundation

enum SelectValidatorsStartError: Error {
    case dataNotLoaded
    case emptyRecommendedValidators
}

extension SelectValidatorsStartError: ErrorContentConvertible {
    func toErrorContent(for locale: Locale?) -> ErrorContent {
        let title: String
        let message: String

        switch self {
        case .dataNotLoaded:
            title = R.string.localizable
                .accountImportKeystoreDecryptionErrorTitle(preferredLanguages: locale?.rLanguages)
            message = R.string.localizable
                .accountImportKeystoreDecryptionErrorMessage(preferredLanguages: locale?.rLanguages)
        case .emptyRecommendedValidators:
            title = R.string.localizable
                .commonErrorGeneralTitle(preferredLanguages: locale?.rLanguages)
            message = R.string.localizable
                .commonUndefinedErrorMessage(preferredLanguages: locale?.rLanguages)
        }

        return ErrorContent(title: title, message: message)
    }
}

enum SelectValidatorsStartFlow {
    case relaychainInitiated(state: InitiatedBonding)
    case relaychainExisting(state: ExistingBonding)
    case parachain(state: InitiatedBonding)

    var phase: SelectValidatorsStartViewController.Phase {
        switch self {
        case .relaychainInitiated:
            return .setup
        case let .relaychainExisting(state):
            return state.selectedTargets == nil ? .setup : .update
        case .parachain:
            return .setup
        }
    }
}

protocol SelectValidatorsStartModelStateListener: AnyObject {
    func modelStateDidChanged(viewModelState: SelectValidatorsStartViewModelState)
    func didReceiveError(error: Error)
}

protocol SelectValidatorsStartViewModelState: SelectValidatorsStartUserInputHandler {
    var stateListener: SelectValidatorsStartModelStateListener? { get set }

    func setStateListener(_ stateListener: SelectValidatorsStartModelStateListener?)

    var customValidatorListFlow: CustomValidatorListFlow? { get }
    var recommendedValidatorListFlow: RecommendedValidatorListFlow? { get }
}

struct SelectValidatorsStartDependencyContainer {
    let viewModelState: SelectValidatorsStartViewModelState
    let strategy: SelectValidatorsStartStrategy
    let viewModelFactory: SelectValidatorsStartViewModelFactoryProtocol
}

protocol SelectValidatorsStartViewModelFactoryProtocol {
    func buildViewModel(viewModelState: SelectValidatorsStartViewModelState) -> SelectValidatorsStartViewModel?
    func buildTextsViewModel(locale: Locale) -> SelectValidatorsStartTextsViewModel?
}

protocol SelectValidatorsStartStrategy {
    func setup()
}

protocol SelectValidatorsStartUserInputHandler {}

extension SelectValidatorsStartUserInputHandler {}
