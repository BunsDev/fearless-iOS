import SoraKeystore
import SoraFoundation

final class CheckPincodeViewFactory {
    static func createView(
        moduleOutput: CheckPincodeModuleOutput
    ) -> PinSetupViewProtocol {
        let interactor = LocalAuthInteractor(
            secretManager: KeychainManager.shared,
            settingsManager: SettingsManager.shared,
            biometryAuth: BiometryAuth(),
            locale: LocalizationManager.shared.selectedLocale
        )
        let presenter = CheckPincodePresenter(
            interactor: interactor,
            moduleOutput: moduleOutput
        )

        let pinVerifyView = CheckPincodeViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )
        presenter.view = pinVerifyView

        interactor.presenter = presenter

        return pinVerifyView
    }
}