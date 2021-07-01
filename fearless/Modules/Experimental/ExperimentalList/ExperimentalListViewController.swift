import UIKit
import SoraFoundation

final class ExperimentalListViewController: UIViewController, ViewHolder {
    typealias RootViewType = ExperimentalListViewLayout

    let presenter: ExperimentalListPresenterProtocol

    private(set) var options: [String] = []

    init(presenter: ExperimentalListPresenterProtocol, localizationManager: LocalizationManagerProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = ExperimentalListViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        setupLocalization()
        presenter.setup()
    }

    private func configure() {
        rootView.tableView.registerClassForCell(SingleTitleTableViewCell.self)
        rootView.tableView.dataSource = self
        rootView.tableView.delegate = self

        rootView.tableView.tableFooterView = UIView()
    }

    private func setupLocalization() {
        title = R.string.localizable.experimentalTitle(preferredLanguages: selectedLocale.rLanguages)
    }
}

extension ExperimentalListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithType(SingleTitleTableViewCell.self)!
        cell.bind(title: options[indexPath.row])
        return cell
    }
}

extension ExperimentalListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        presenter.selectOption(at: indexPath.row)
    }
}

extension ExperimentalListViewController: ExperimentalListViewProtocol {
    func didReceive(options: [String]) {
        self.options = options

        rootView.tableView.reloadData()
    }
}

extension ExperimentalListViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}
