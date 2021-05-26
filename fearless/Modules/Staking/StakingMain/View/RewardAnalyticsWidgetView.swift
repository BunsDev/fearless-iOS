import UIKit
import SoraUI

final class RewardAnalyticsWidgetView: UIView {
    private let backgroundView: UIView = TriangularedBlurView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.textColor = R.color.colorWhite()
        return label
    }()

    private let arrowView: UIView = UIImageView(image: R.image.iconSmallArrow())

    private let periodLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.textColor = R.color.colorWhite()?.withAlphaComponent(0.64)
        return label
    }()

    private let tokenAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.textColor = R.color.colorWhite()
        return label
    }()

    private let usdAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .p2Paragraph
        label.textColor = R.color.colorGray()
        return label
    }()

    private let payableIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = R.color.colorAccent()
        return view
    }()

    private let payableTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .p3Paragraph
        label.textColor = R.color.colorWhite()
        return label
    }()

    private let receivedIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = R.color.colorGray()
        return view
    }()

    private let receivedTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .p3Paragraph
        label.textColor = R.color.colorWhite()
        return label
    }()

    var locale = Locale.current {
        didSet {
            if locale != oldValue {
                applyLocalization()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyLocalization()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyLocalization() {
        titleLabel.text = "Reward analytics"
        usdAmountLabel.text = "$15.22"
        tokenAmountLabel.text = "0.03805 KSM"
        periodLabel.text = "May 12—19"
        payableTitleLabel.text = "Payable"
        receivedTitleLabel.text = "Received"
    }

    private func setupLayout() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let chartView = UIView()
        chartView.backgroundColor = .red
        let separatorView = UIView.createSeparator(color: R.color.colorWhite()?.withAlphaComponent(0.24))

        let stackView: UIView = .vStack(
            spacing: 8,
            [
                .hStack([titleLabel, UIView(), arrowView]),
                separatorView,
                .hStack(
                    alignment: .center,
                    [
                        periodLabel,
                        UIView(),
                        .vStack(
                            alignment: .trailing,
                            [tokenAmountLabel, usdAmountLabel]
                        )
                    ]
                ),
                chartView,
                .hStack(
                    alignment: .center,
                    spacing: 16,
                    [
                        .hStack(alignment: .center, spacing: 8, [payableIndicatorView, payableTitleLabel]),
                        .hStack(alignment: .center, spacing: 8, [receivedIndicatorView, receivedTitleLabel]),
                        UIView()
                    ]
                )
            ]
        )

        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIConstants.horizontalInset) }

        arrowView.snp.makeConstraints { $0.size.equalTo(24) }
        separatorView.snp.makeConstraints { $0.height.equalTo(UIConstants.separatorHeight) }
        chartView.snp.makeConstraints { $0.height.equalTo(100) }
        payableIndicatorView.snp.makeConstraints { $0.size.equalTo(8) }
        receivedIndicatorView.snp.makeConstraints { $0.size.equalTo(8) }
    }
}