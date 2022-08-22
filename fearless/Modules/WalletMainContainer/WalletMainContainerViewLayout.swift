import UIKit

protocol WalletMainContainerViewDelegate: AnyObject {
    func switchWalletDidTap()
    func scanQRDidTap()
    func searchDidTap()
    func selectNetworkDidTap()
    func didSelect(_ segmentIndex: Int)
    func balanceDidTap()
}

final class WalletMainContainerViewLayout: UIView {
    private enum Constants {
        static let walletIconSize: CGFloat = 40.0
        static let accessoryButtonSize: CGFloat = 32.0
    }

    weak var delegate: WalletMainContainerViewDelegate?

    var locale: Locale = .current {
        didSet {
            applyLocalization()
        }
    }

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = R.image.backgroundImage()
        return imageView
    }()

    private let contentView: UIStackView = {
        let view = UIFactory.default.createVerticalStackView()
        view.alignment = .center
        return view
    }()

    // MARK: - Navigation view properties

    private let navigationContainerView = UIView()

    private let switchWalletButton: UIButton = {
        let button = UIButton()
        button.setImage(R.image.iconFearlessRounded(), for: .normal)
        return button
    }()

    private let walletNameTitle: UILabel = {
        let label = UILabel()
        label.font = .h4Title
        return label
    }()

    private let selectNetworkButton: SelectedNetworkButton = {
        let button = SelectedNetworkButton()
        button.titleLabel?.font = .p1Paragraph
        return button
    }()

    private let scanQRButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = R.color.colorWhite8()
        button.setImage(R.image.iconScanQr(), for: .normal)
        button.layer.cornerRadius = Constants.accessoryButtonSize / 2
        button.clipsToBounds = true
        return button
    }()

    private let searchButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = R.color.colorWhite8()
        button.setImage(R.image.iconSearchWhite(), for: .normal)
        button.layer.cornerRadius = Constants.accessoryButtonSize / 2
        button.clipsToBounds = true
        return button
    }()

    // MARK: - Wallet balance view

    private let walletBalanceVStackView = UIFactory.default.createVerticalStackView(spacing: 4)
    let walletBalanceViewContainer = UIView()

    // MARK: - Address label

    private let addressCopyableLabel: CopyableLabelView = {
        let label = CopyableLabelView()
        return label
    }()

    // MARK: - FWSegmentedControl

    private let segmentedControl: FWSegmentedControl = {
        let segment = FWSegmentedControl()
        let items = ["Currencies", "NFTs"]
        segment.setSegmentItems(items)
        return segment
    }()

    // MARK: - UIPageViewController

    private let pageViewControllerContainer = UIView()

    let pageViewController: UIPageViewController = {
        let pageController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        return pageController
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupLayout()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func bind(viewModel: WalletMainContainerViewModel) {
        walletNameTitle.text = viewModel.walletName
        selectNetworkButton.setTitle(viewModel.selectedChainName, for: .normal)
        if let address = viewModel.address {
            addressCopyableLabel.isHidden = false
            addressCopyableLabel.bind(title: address)
        } else {
            addressCopyableLabel.isHidden = true
        }
    }

    // MARK: - Private setup methods

    private func setup() {
        segmentedControl.delegate = self
    }

    private func setupActions() {
        switchWalletButton.addTarget(self, action: #selector(handleSwitchWalletTap), for: .touchUpInside)
        scanQRButton.addTarget(self, action: #selector(handleScanQRTap), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(handleSearchTap), for: .touchUpInside)
        selectNetworkButton.addTarget(self, action: #selector(handleSelectNetworkTap), for: .touchUpInside)

        let walletBalanceTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBalanceDidTap))
        walletBalanceViewContainer.addGestureRecognizer(walletBalanceTapGesture)
    }

    private func applyLocalization() {
        let localizedItems = [
            R.string.localizable.сurrenciesStubText(preferredLanguages: locale.rLanguages),
            "NFTs"
        ]
        segmentedControl.setSegmentItems(localizedItems)
    }

    // MARK: - Actions

    @objc private func handleSwitchWalletTap() {
        delegate?.switchWalletDidTap()
    }

    @objc private func handleScanQRTap() {
        delegate?.scanQRDidTap()
    }

    @objc private func handleSearchTap() {
        delegate?.searchDidTap()
    }

    @objc private func handleSelectNetworkTap() {
        delegate?.selectNetworkDidTap()
    }

    @objc private func handleBalanceDidTap() {
        delegate?.balanceDidTap()
    }

    // MARK: - Private layout methods

    private func setupLayout() {
        addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(5)
            make.leading.trailing.equalToSuperview()
        }

        setupNavigationViewLayout()
        setupWalletBalanceLayout()
        setupSegmentedLayout()
        setupListLayout()
    }

    private func setupNavigationViewLayout() {
        navigationContainerView.addSubview(switchWalletButton)
        switchWalletButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.size.equalTo(Constants.walletIconSize)
        }

        let walletInfoVStackView = UIFactory.default.createVerticalStackView(spacing: 6)
        walletInfoVStackView.alignment = .center
        walletInfoVStackView.distribution = .fill

        navigationContainerView.addSubview(walletInfoVStackView)
        walletInfoVStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualTo(switchWalletButton.snp.trailing).priority(.low)
        }

        walletInfoVStackView.addArrangedSubview(walletNameTitle)
        walletInfoVStackView.addArrangedSubview(selectNetworkButton)
        selectNetworkButton.snp.makeConstraints { make in
            make.height.equalTo(22)
        }

        let accessoryButtonHStackView = UIFactory.default.createHorizontalStackView(spacing: 8)
        navigationContainerView.addSubview(accessoryButtonHStackView)
        accessoryButtonHStackView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(walletInfoVStackView.snp.trailing).priority(.low)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        [scanQRButton, searchButton].forEach { button in
            accessoryButtonHStackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.size.equalTo(Constants.accessoryButtonSize)
            }
        }

        contentView.addArrangedSubview(navigationContainerView)
        navigationContainerView.snp.makeConstraints { make in
            make.width.equalTo(contentView.snp.width).offset(-2.0 * UIConstants.horizontalInset)
        }
    }

    private func setupWalletBalanceLayout() {
        addressCopyableLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addressCopyableLabel.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(135)
            make.height.equalTo(24)
        }

        walletBalanceViewContainer.snp.makeConstraints { make in
            make.height.equalTo(58)
        }

        walletBalanceVStackView.distribution = .fill
        walletBalanceVStackView.addArrangedSubview(walletBalanceViewContainer)
        walletBalanceVStackView.addArrangedSubview(addressCopyableLabel)

        contentView.setCustomSpacing(32, after: navigationContainerView)
        contentView.addArrangedSubview(walletBalanceVStackView)

        walletBalanceVStackView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(80)
        }
    }

    private func setupSegmentedLayout() {
        contentView.setCustomSpacing(32, after: walletBalanceVStackView)
        let segmentContainer = UIView()
        contentView.addArrangedSubview(segmentContainer)
        segmentContainer.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.width.equalTo(contentView.snp.width).offset(-2.0 * UIConstants.horizontalInset)
            make.edges.equalToSuperview()
        }
    }

    private func setupListLayout() {
        addSubview(pageViewControllerContainer)
        pageViewControllerContainer.addSubview(pageViewController.view)
        pageViewControllerContainer.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension WalletMainContainerViewLayout: FWSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        delegate?.didSelect(segmentIndex)
    }
}
