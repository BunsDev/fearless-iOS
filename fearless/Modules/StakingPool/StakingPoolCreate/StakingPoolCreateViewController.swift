import UIKit
import SoraFoundation
import CommonWallet
import SoraUI

final class StakingPoolCreateViewController: UIViewController, ViewHolder, HiddableBarWhenPushed {
    typealias RootViewType = StakingPoolCreateViewLayout

    // MARK: Private properties

    private let output: StakingPoolCreateViewOutput

    private var amountInputViewModel: AmountInputViewModelProtocol?
    private var poolNameInputViewModel: InputViewModelProtocol?

    // MARK: - Constructor

    init(
        output: StakingPoolCreateViewOutput,
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
        view = StakingPoolCreateViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        output.didLoad(view: self)

        setupBalanceAccessoryView()
        setupActions()
        rootView.poolNameInputView.animatedInputField.delegate = self
        rootView.amountView.textField.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: - Private methods

    private func setupBalanceAccessoryView() {
        let locale = localizationManager?.selectedLocale ?? Locale.current
        let accessoryView = UIFactory.default.createAmountAccessoryView(for: self, locale: locale)
        rootView.amountView.textField.inputAccessoryView = accessoryView
    }

    private func setupActions() {
        rootView.nominatorView.addTarget(
            self,
            action: #selector(handleNominationTapped),
            for: .touchUpInside
        )
        rootView.stateTogglerView.addTarget(
            self,
            action: #selector(handleStateTogglerTapped),
            for: .touchUpInside
        )
        rootView.feeView.actionButton.addTarget(
            self,
            action: #selector(handleCreateButtonTapped),
            for: .touchUpInside
        )
        rootView.navigationBar.backButton.addTarget(
            self,
            action: #selector(handleBackButtonTapped),
            for: .touchUpInside
        )
    }

    // MARK: - Private actions

    @objc private func handleNominationTapped() {
        output.nominatorDidTapped()
    }

    @objc private func handleStateTogglerTapped() {
        output.stateTogglerDidTapped()
    }

    @objc private func handleCreateButtonTapped() {
        output.createDidTapped()
    }

    @objc private func handleBackButtonTapped() {
        output.backDidTapped()
    }
}

// MARK: - StakingPoolCreateViewInput

extension StakingPoolCreateViewController: StakingPoolCreateViewInput {
    func didReceive(nameViewModel: InputViewModelProtocol) {
        poolNameInputViewModel = nameViewModel
    }

    func didReceiveViewModel(_ viewModel: StakingPoolCreateViewModel) {
        rootView.bind(viewModel: viewModel)
    }

    func didReceiveAmountInputViewModel(_ amountInputViewModel: AmountInputViewModelProtocol) {
        rootView.amountView.inputFieldText = amountInputViewModel.displayAmount
        self.amountInputViewModel = amountInputViewModel
        self.amountInputViewModel?.observable.remove(observer: self)

        self.amountInputViewModel?.observable.add(observer: self)
    }

    func didReceiveAssetBalanceViewModel(_ assetBalanceViewModel: AssetBalanceViewModelProtocol) {
        rootView.bind(assetViewModel: assetBalanceViewModel)
    }

    func didReceiveFeeViewModel(_ feeViewModel: BalanceViewModelProtocol?) {
        rootView.feeView.bindBalance(viewModel: feeViewModel)
    }
}

// MARK: - Localizable

extension StakingPoolCreateViewController: Localizable {
    func applyLocalization() {
        rootView.locale = selectedLocale
    }
}

// MARK: - AmountInputAccessoryViewDelegate

extension StakingPoolCreateViewController: AmountInputAccessoryViewDelegate {
    func didSelect(on _: AmountInputAccessoryView, percentage: Float) {
        rootView.amountView.textField.resignFirstResponder()

        output.selectAmountPercentage(percentage)
    }

    func didSelectDone(on _: AmountInputAccessoryView) {
        rootView.amountView.textField.resignFirstResponder()
    }
}

// MARK: - AmountInputViewModelObserver

extension StakingPoolCreateViewController: AmountInputViewModelObserver {
    func amountInputDidChange() {
        rootView.amountView.inputFieldText = amountInputViewModel?.displayAmount

        let amount = amountInputViewModel?.decimalAmount ?? 0.0
        output.updateAmount(amount)
    }
}

extension StakingPoolCreateViewController: UITextFieldDelegate {
    func textField(
        _: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        amountInputViewModel?.didReceiveReplacement(string, for: range) ?? false
    }
}

// MARK: - AnimatedTextFieldDelegate

extension StakingPoolCreateViewController: AnimatedTextFieldDelegate {
    func animatedTextFieldShouldReturn(_ textField: AnimatedTextField) -> Bool {
        textField.resignFirstResponder()

        return false
    }

    func animatedTextField(
        _ textField: AnimatedTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let viewModel = poolNameInputViewModel else {
            return true
        }

        let shouldApply = viewModel.inputHandler.didReceiveReplacement(string, for: range)

        if !shouldApply, textField.text != viewModel.inputHandler.value {
            textField.text = viewModel.inputHandler.value
        }

        return shouldApply
    }
}