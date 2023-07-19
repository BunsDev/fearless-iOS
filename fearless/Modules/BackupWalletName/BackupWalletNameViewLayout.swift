import UIKit

final class BackupWalletNameViewLayout: UIView {
    let navigationBar: BaseNavigationBar = {
        let view = BaseNavigationBar()
        view.backgroundColor = R.color.colorBlack19()
        return view
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .p0Paragraph
        label.textColor = R.color.colorStrokeGray()!
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    let nameTextField: CommonInputView = {
        let inputView = CommonInputView()
        inputView.backgroundView.fillColor = R.color.colorSemiBlack()!
        inputView.backgroundView.highlightedFillColor = R.color.colorSemiBlack()!
        inputView.backgroundView.strokeColor = R.color.colorWhite8()!
        inputView.backgroundView.highlightedStrokeColor = R.color.colorPink()!
        inputView.backgroundView.strokeWidth = 0.5
        inputView.backgroundView.shadowOpacity = 0
        inputView.animatedInputField.placeholderColor = R.color.colorLightGray()!
        inputView.defaultSetup()
        return inputView
    }()

    let bottomDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .p2Paragraph
        label.textColor = R.color.colorStrokeGray()!
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    let continueButton: TriangularedButton = {
        let button = TriangularedButton()
        button.applyEnabledStyle()
        button.isEnabled = false
        return button
    }()

    var locale: Locale = .current {
        didSet {
            applyLocalization()
        }
    }

    let mode: WalletNameScreenMode

    init(mode: WalletNameScreenMode) {
        self.mode = mode
        super.init(frame: .zero)
        backgroundColor = R.color.colorBlack19()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupLayout() {
        addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(UIConstants.bigOffset)
            make.leading.trailing.equalToSuperview().inset(UIConstants.bigOffset)
        }

        addSubview(nameTextField)
        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(UIConstants.bigOffset)
            make.leading.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.height.equalTo(64)
        }

        addSubview(bottomDescriptionLabel)
        bottomDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(UIConstants.bigOffset)
            make.leading.trailing.equalToSuperview().inset(UIConstants.bigOffset)
        }

        addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(UIConstants.bigOffset)
            make.height.equalTo(UIConstants.actionHeight)
        }
    }

    private func applyLocalization() {
        switch mode {
        case .editing:
            navigationBar.setTitle("Change wallet name")
            descriptionLabel.text = "Example: Savings, Investments, Crowdloans, Staking. This account name will be displayed only for you and stored locally on your mobile device"
            nameTextField.title = "Wallet name"
            bottomDescriptionLabel.text = nil
            continueButton.imageWithTitleView?.title = "Save"
        case .create:
            navigationBar.setTitle("Name your new wallet")
            descriptionLabel.text = "Make a name for your new wallet, so you can easily indentify it. This is optional and will be visible only for you"
            nameTextField.title = "Wallet name"
            bottomDescriptionLabel.text = "Visible only for you and stored locally"
            continueButton.imageWithTitleView?.title = "Continue"
        }
    }
}
