import UIKit
import SoraFoundation

final class StakingPoolMainViewController: UIViewController, ViewHolder {
    typealias RootViewType = StakingPoolMainViewLayout

    // MARK: Private properties

    private let output: StakingPoolMainViewOutput

    // MARK: - Constructor

    init(
        output: StakingPoolMainViewOutput,
        localizationManager: LocalizationManagerProtocol?
    ) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func loadView() {
        view = StakingPoolMainViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        output.didLoad(view: self)
    }

    // MARK: - Private methods
}

// MARK: - StakingPoolMainViewInput

extension StakingPoolMainViewController: StakingPoolMainViewInput {}

// MARK: - Localizable

extension StakingPoolMainViewController: Localizable {
    func applyLocalization() {}
}