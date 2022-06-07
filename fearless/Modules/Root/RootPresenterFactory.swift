import UIKit
import SoraKeystore
import SoraFoundation

final class RootPresenterFactory: RootPresenterFactoryProtocol {
    static func createPresenter(with window: UIWindow) -> RootPresenterProtocol {
        let wireframe = RootWireframe()
        let settings = SettingsManager.shared
        let keychain = Keychain()
        let startViewHelper = StartViewHelper(
            keystore: keychain,
            selectedWalletSettings: SelectedWalletSettings.shared,
            userDefaultsStorage: SettingsManager.shared
        )

        let languageMigrator = SelectedLanguageMigrator(
            localizationManager: LocalizationManager.shared
        )
        let networkConnectionsMigrator = NetworkConnectionsMigrator(settings: settings)

        let dbMigrator = UserStorageMigrator(
            targetVersion: UserStorageParams.modelVersion,
            storeURL: UserStorageParams.storageURL,
            modelDirectory: UserStorageParams.modelDirectory,
            keystore: keychain,
            settings: settings,
            fileManager: FileManager.default
        )

        let presenter = RootPresenter(
            localizationManager: LocalizationManager.shared,
            startViewHelper: startViewHelper
        )

        let interactor = RootInteractor(
            settings: SelectedWalletSettings.shared,
            applicationConfig: ApplicationConfig.shared,
            eventCenter: EventCenter.shared,
            migrators: [languageMigrator, networkConnectionsMigrator, dbMigrator],
            logger: Logger.shared
        )

        let view = RootViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.window = window
        presenter.wireframe = wireframe
        presenter.interactor = interactor
        presenter.view = view

        interactor.presenter = presenter

        return presenter
    }
}
