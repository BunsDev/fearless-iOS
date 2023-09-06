import UIKit
import SCard
import SoraUI
import SnapKit

final class ChainAssetListViewLayout: UIView {
    private enum Constants {
        static let tableViewContentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: UIConstants.bigOffset,
            right: 0
        )
    }

    enum ViewState {
        case normal
        case empty
    }

    var keyboardAdoptableConstraint: Constraint?

    weak var bannersView: UIView?
    private var soraCardView: UIView?

    var headerViewContainer: UIStackView = {
        UIFactory.default.createVerticalStackView(spacing: UIConstants.bigOffset)
    }()

    let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIConstants.bigOffset, right: 0)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addBanners(view: UIView) {
        bannersView = view
        headerViewContainer.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
    }

    func bindSoraCard(item: SCCardItem, isHidden: Bool) {
        let cell = SCCardCell()
        cell.set(item: item, context: nil)
        if soraCardView == nil {
            soraCardView = cell.contentView
            soraCardView?.isHidden = isHidden
            headerViewContainer.addArrangedSubview(soraCardView!)
            soraCardView?.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
            }
        }
    }

    func closeSoraCard() {
        soraCardView?.isHidden = true
    }

    private func setupLayout() {
        tableView.tableHeaderView = headerViewContainer
        headerViewContainer.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(UIConstants.bigOffset)
            make.centerX.equalToSuperview()
        }

        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
