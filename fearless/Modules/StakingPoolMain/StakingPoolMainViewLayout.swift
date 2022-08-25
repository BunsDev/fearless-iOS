import UIKit
import SoraFoundation

final class StakingPoolMainViewLayout: UIView {
    private enum Constants {
        static let verticalSpacing: CGFloat = 0.0
        static let bottomInset: CGFloat = 8.0
        static let contentInset = UIEdgeInsets(
            top: UIConstants.bigOffset,
            left: 0,
            bottom: UIConstants.bigOffset,
            right: 0
        )
        static let birdButtonSize = CGSize(width: 40, height: 40)
        static let networkInfoHeight: CGFloat = 292
        static let nominatorStateViewHeight: CGFloat = 232
    }

    let contentView: ScrollableContainerView = {
        let view = ScrollableContainerView()
        view.stackView.isLayoutMarginsRelativeArrangement = true
        view.stackView.layoutMargins = .zero
        return view
    }()

    let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = R.image.backgroundImage()
        return imageView
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .h1Title
        label.textColor = .white
        return label
    }()

    let walletSelectionButton: UIButton = {
        let button = UIButton()
        button.setImage(R.image.iconBirdGreen(), for: .normal)
        return button
    }()

    let assetSelectionContainerView = UIView()
    let assetSelectionView: DetailsTriangularedView = {
        let view = UIFactory.default.createChainAssetSelectionView()
        view.borderWidth = 0.0
        return view
    }()

    let rewardCalculatorView = StakingRewardCalculatorView()

    let networkInfoView = NetworkInfoView()

    let nominatorStateView = NominatorStateView()

    var locale = Locale.current {
        didSet {
            applyLocalization()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        applyLocalization()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyLocalization() {
        titleLabel.text = R.string.localizable.stakingTitle(preferredLanguages: locale.rLanguages)
        networkInfoView.titleControl.titleLabel.text = R.string.localizable.poolStakingTitle(preferredLanguages: locale.rLanguages)
        networkInfoView.descriptionLabel.text = R.string.localizable.poolStakingMainDescriptionTitle(preferredLanguages: locale.rLanguages)
    }

    private func setupLayout() {
        addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(titleLabel)
        addSubview(walletSelectionButton)

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(walletSelectionButton.snp.bottom).offset(UIConstants.defaultOffset)
        }

        assetSelectionContainerView.translatesAutoresizingMaskIntoConstraints = false

        let backgroundView = TriangularedBlurView()
        assetSelectionContainerView.addSubview(backgroundView)
        assetSelectionContainerView.addSubview(assetSelectionView)

        applyConstraints(for: assetSelectionContainerView, innerView: assetSelectionView)

        contentView.stackView.addArrangedSubview(assetSelectionContainerView)

        assetSelectionView.snp.makeConstraints { make in
            make.height.equalTo(48.0)
        }

        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(assetSelectionView)
        }

        assetSelectionContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }

        contentView.stackView.addArrangedSubview(networkInfoView)
        contentView.stackView.addArrangedSubview(rewardCalculatorView)
        contentView.stackView.addArrangedSubview(nominatorStateView)

        networkInfoView.collectionView.snp.makeConstraints { make in
            make.height.equalTo(0)
        }

        rewardCalculatorView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(walletSelectionButton.snp.centerY)
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
        }

        walletSelectionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.size.equalTo(Constants.birdButtonSize)
            make.leading.equalTo(titleLabel.snp.trailing).offset(UIConstants.bigOffset)
        }

        networkInfoView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.height.equalTo(Constants.networkInfoHeight)
        }

        nominatorStateView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UIConstants.bigOffset)
            make.trailing.equalToSuperview().inset(UIConstants.bigOffset)
            make.height.equalTo(Constants.nominatorStateViewHeight)
        }

        contentView.stackView.setCustomSpacing(UIConstants.bigOffset, after: networkInfoView)
    }

    private func applyConstraints(for containerView: UIView, innerView: UIView) {
        innerView.translatesAutoresizingMaskIntoConstraints = false
        innerView.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor,
            constant: UIConstants.horizontalInset
        ).isActive = true
        innerView.trailingAnchor.constraint(
            equalTo: containerView.trailingAnchor,
            constant: -UIConstants.horizontalInset
        ).isActive = true
        innerView.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: Constants.verticalSpacing
        ).isActive = true

        containerView.bottomAnchor.constraint(
            equalTo: innerView.bottomAnchor,
            constant: Constants.bottomInset
        ).isActive = true
    }

    func bind(chainAsset: ChainAsset) {
        if let iconUrl = chainAsset.chain.icon {
            let assetIconViewModel: ImageViewModelProtocol? = RemoteImageViewModel(url: iconUrl)
            assetIconViewModel?.cancel(on: assetSelectionView.iconView)

            let iconSize = 2 * assetSelectionView.iconRadius
            assetIconViewModel?.loadImage(
                on: assetSelectionView.iconView,
                targetSize: CGSize(width: iconSize, height: iconSize),
                animated: false
            )
        }

        assetSelectionView.title = chainAsset.asset.name
        assetSelectionView.iconImage = nil
    }

    func bind(balanceViewModel: BalanceViewModelProtocol) {
        assetSelectionView.subtitle = balanceViewModel.amount
    }

    func bind(estimationViewModel: StakingEstimationViewModel) {
        rewardCalculatorView.bind(viewModel: estimationViewModel)
    }

    func bind(viewModels: [LocalizableResource<NetworkInfoContentViewModel>]) {
        networkInfoView.bind(viewModels: viewModels)
    }

    func bind(nominatorStateViewModel: LocalizableResource<NominationViewModelProtocol>?) {
        nominatorStateView.isHidden = nominatorStateViewModel == nil
        rewardCalculatorView.isHidden = nominatorStateViewModel != nil

        if let nominatorStateViewModel = nominatorStateViewModel {
            nominatorStateView.bind(viewModel: nominatorStateViewModel)
        }
    }
}