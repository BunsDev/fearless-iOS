import UIKit
import SoraFoundation

final class StakingPayoutConfirmationViewController: UIViewController, ViewHolder {
    typealias RootViewType = StakingPayoutConfirmationViewLayout

    let presenter: StakingPayoutConfirmationPresenterProtocol

    private var feeViewModel: LocalizableResource<BalanceViewModelProtocol>?

    init(
        presenter: StakingPayoutConfirmationPresenterProtocol,
        localizationManager: LocalizationManagerProtocol?
    ) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = StakingPayoutConfirmationViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyLocalization()
        setupTable()
        presenter.setup()
    }

    private func setupTable() {
        rootView.tableView.registerClassesForCell([
            StakingRewardDetailsLabelTableCell.self,
            StakingRewardDetailsRewardTableCell.self,
            AccountInfoTableViewCell.self
        ])
        rootView.tableView.delegate = self
        rootView.tableView.dataSource = self
    }

    private func applyFeeViewModel() {
        let locale = localizationManager?.selectedLocale ?? Locale.current
        if let viewModel = feeViewModel?.value(for: locale) {
//            activityIndicatorView.stopAnimating()
//            feeDetailsLabel.isHidden = false

            let amountAttributedString = NSMutableAttributedString(
                string: viewModel.amount + "  ",
                attributes: [
                    .foregroundColor: R.color.colorWhite()!,
                    .font: UIFont.p1Paragraph
                ]
            )

            if let price = viewModel.price {
                let priceAttributedString = NSAttributedString(
                    string: price,
                    attributes: [
                        .foregroundColor: R.color.colorGray()!,
                        .font: UIFont.p1Paragraph
                    ]
                )
                amountAttributedString.append(priceAttributedString)
            }

//            feeDetailsLabel.attributedText = amountAttributedString
        } else {
//            feeDetailsLabel.isHidden = true
//            activityIndicatorView.startAnimating()
        }
    }
}

extension StakingPayoutConfirmationViewController: StakingPayoutConfirmationViewProtocol {
    func didReceive(feeViewModel: LocalizableResource<BalanceViewModelProtocol>?) {
        self.feeViewModel = feeViewModel
        applyFeeViewModel()
        let locale = localizationManager?.selectedLocale ?? Locale.current
        setupTranformViewLocalization(locale)
    }
}

extension StakingPayoutConfirmationViewController: Localizable {
    private func setupLocalization() {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        setupTitleLocalization(locale)
        setupTranformViewLocalization(locale)
    }

    private func setupTitleLocalization(_ locale: Locale) {
        title = R.string.localizable.stakingConfirmTitle(preferredLanguages: locale.rLanguages)
    }

    private func setupTranformViewLocalization(_ locale: Locale) {
        guard let feeViewModel = feeViewModel?.value(for: locale) else { return }

        let feeString = feeViewModel.amount + "  " + (feeViewModel.price ?? "")

        let viewModel = TransferConfirmAccessoryViewModel(
            title: R.string.localizable.commonNetworkFee(preferredLanguages: locale.rLanguages),
            icon: nil,
            action: R.string.localizable.stakingConfirmTitle(preferredLanguages: locale.rLanguages),
            numberOfLines: 1,
            amount: feeString,
            shouldAllowAction: true
        )
        rootView.transferConfirmView.bind(viewModel: viewModel)
    }

    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
            rootView.tableView.reloadData()
            view.setNeedsLayout()
        }
    }
}

extension StakingPayoutConfirmationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // TODO: FLW-677
    }
}

extension StakingPayoutConfirmationViewController: UITableViewDataSource {
    // TODO: delete stub data
    var stubCellData: [RewardDetailsRow] {
        [
            .validatorInfo(.init(
                name: "Payout account",
                address: "🐟 ANDREY",
                icon: R.image.iconAccount()
            )),
            .validatorInfo(.init(
                name: "Validator",
                address: "✨👍✨ Day7 ✨👍✨",
                icon: R.image.iconAccount()
            )),
            .destination(.init(
                titleText: R.string.localizable.stakingRewardDestinationTitle(),
                valueText: R.string.localizable.stakingRestakeTitle()
            )),
            .era(.init(
                titleText: R.string.localizable.stakingRewardDetailsEra(),
                valueText: "#1690"
            )),
            .reward(.init(ksmAmountText: "0.00005 KSM", usdAmountText: "$0,01"))
        ]
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        stubCellData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: handle current locale
        switch stubCellData[indexPath.row] {
        case let .destination(viewModel):
            let cell = tableView.dequeueReusableCellWithType(
                StakingRewardDetailsLabelTableCell.self)!
            cell.bind(model: viewModel)
            return cell
        case let .era(eraViewModel):
            let cell = tableView.dequeueReusableCellWithType(
                StakingRewardDetailsLabelTableCell.self)!
            cell.bind(model: eraViewModel)
            return cell
        case let .reward(rewardViewModel):
            let cell = tableView.dequeueReusableCellWithType(
                StakingRewardDetailsRewardTableCell.self)!
            cell.bind(model: rewardViewModel)
            return cell
        case let .validatorInfo(model):
            let cell = tableView.dequeueReusableCellWithType(
                AccountInfoTableViewCell.self)!
            cell.bind(model: model)
            return cell
        default:
            fatalError()
        }
    }
}
