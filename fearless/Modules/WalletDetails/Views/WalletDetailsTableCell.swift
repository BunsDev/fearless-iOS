import UIKit

class WalletDetailsTableCell: UITableViewCell {
    enum LayoutConstants {
        static let cellHeight: CGFloat = 48
        static let chainImageSize = CGSize(width: 27, height: 27)
        static let addressImageSize: CGFloat = 16
    }

    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill
        stackView.spacing = UIConstants.defaultOffset
        return stackView
    }()

    private var chainImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        return stackView
    }()

    private var chainLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.textColor = R.color.colorWhite()
        return label
    }()

    private var addressStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill
        stackView.spacing = UIConstants.defaultOffset
        return stackView
    }()

    private var addressImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var addressLabel: UILabel = {
        let label = UILabel()
        label.font = .p2Paragraph
        label.textColor = R.color.colorStrokeGray()
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configure()
        setupLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        chainImageView.kf.cancelDownloadTask()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(to viewModel: WalletDetailsCellViewModel) {
        viewModel.chainImageViewModel?.cancel(on: chainImageView)
        viewModel.chainImageViewModel?.loadImage(
            on: chainImageView,
            targetSize: LayoutConstants.chainImageSize,
            animated: false
        )

        chainLabel.text = viewModel.chainName
        addressLabel.text = viewModel.address
        if let addressImage = viewModel.addressImage {
            addressImageView.isHidden = false
            addressImageView.image = addressImage
        } else {
            addressImageView.isHidden = true
        }
    }
}

private extension WalletDetailsTableCell {
    func configure() {
        backgroundColor = .clear

        separatorInset = UIEdgeInsets(
            top: 0.0,
            left: UIConstants.horizontalInset,
            bottom: 0.0,
            right: UIConstants.horizontalInset
        )

        selectionStyle = .none
    }

    func setupLayout() {
        contentView.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }

        mainStackView.addArrangedSubview(chainImageView)
        chainImageView.snp.makeConstraints { make in
            make.size.equalTo(LayoutConstants.chainImageSize)
        }

        mainStackView.addArrangedSubview(infoStackView)

        infoStackView.addArrangedSubview(chainLabel)
        infoStackView.addArrangedSubview(addressStackView)
        addressStackView.snp.makeConstraints { make in
            make.width.equalTo(infoStackView)
        }

        addressStackView.addArrangedSubview(addressImageView)
        addressImageView.snp.makeConstraints { make in
            make.size.equalTo(LayoutConstants.addressImageSize)
        }
        addressStackView.addArrangedSubview(addressLabel)
    }
}
