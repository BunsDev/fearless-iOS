import UIKit
import SoraFoundation

final class StakingBalanceUnbondingItemView: UIView {
    private enum Constants {
        static let verticalInset: CGFloat = 11
        static let iconSize: CGFloat = 32
    }

    let transactionTypeView: UIImageView = {
        UIImageView(image: R.image.iconStakingTransactionType())
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.lineBreakMode = .byTruncatingMiddle
        label.textColor = R.color.colorWhite()
        return label
    }()

    let daysLeftLabel: UILabel = {
        let label = UILabel()
        label.font = .p2Paragraph
        return label
    }()

    let tokenAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.textColor = R.color.colorWhite()
        return label
    }()

    let usdAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .p2Paragraph
        label.textColor = R.color.colorLightGray()
        return label
    }()

    private lazy var timer = CountdownTimer()
    private lazy var timeFormatter = TotalTimeFormatter()

    override init(frame: CGRect) {
        super.init(frame: frame)
        timer.delegate = self
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(transactionTypeView)
        transactionTypeView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(UIConstants.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(Constants.iconSize)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(transactionTypeView.snp.trailing).offset(UIConstants.horizontalInset / 2)
            make.top.equalToSuperview().inset(Constants.verticalInset)
        }

        addSubview(daysLeftLabel)
        daysLeftLabel.snp.makeConstraints { make in
            make.leading.equalTo(transactionTypeView.snp.trailing).offset(UIConstants.horizontalInset / 2)
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalToSuperview().inset(Constants.verticalInset)
        }

        addSubview(tokenAmountLabel)
        tokenAmountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalToSuperview().inset(Constants.verticalInset)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(UIConstants.horizontalInset / 2)
        }

        addSubview(usdAmountLabel)
        usdAmountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(tokenAmountLabel.snp.bottom)
            make.bottom.equalToSuperview().inset(Constants.verticalInset)
        }
    }

    deinit {
        timer.stop()
    }
}

extension StakingBalanceUnbondingItemView {
    func bind(model: UnbondingItemViewModel) {
        titleLabel.text = model.addressOrName
        tokenAmountLabel.text = model.tokenAmountText
        usdAmountLabel.text = model.usdAmountText
        timer.stop()
        if let interval = model.timeInterval {
            timer.start(with: interval, runLoop: RunLoop.current, mode: .tracking)
        }
    }
}

extension StakingBalanceUnbondingItemView: CountdownTimerDelegate {
    func didStart(with interval: TimeInterval) {
        let intervalString = (try? timeFormatter.string(from: interval)) ?? ""
        daysLeftLabel.text =
            "\(R.string.localizable.stakingNextRound(preferredLanguages: Locale.current.rLanguages)): \(intervalString)"
    }

    func didCountdown(remainedInterval: TimeInterval) {
        let intervalString = (try? timeFormatter.string(from: remainedInterval)) ?? ""
        daysLeftLabel.text =
            "\(R.string.localizable.stakingNextRound(preferredLanguages: Locale.current.rLanguages)): \(intervalString)"
    }

    func didStop(with _: TimeInterval) {
        daysLeftLabel.text = ""
    }
}
