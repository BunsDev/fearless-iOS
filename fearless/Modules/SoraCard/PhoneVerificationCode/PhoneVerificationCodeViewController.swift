import UIKit
import SoraFoundation

final class PhoneVerificationCodeViewController: UIViewController, ViewHolder {
    typealias RootViewType = PhoneVerificationCodeViewLayout

    // MARK: Private properties

    private let output: PhoneVerificationCodeViewOutput
    private var timer: Timer?
    private var remainingTime = 60
    private var otpLength: Int

    // MARK: - Constructor

    init(
        output: PhoneVerificationCodeViewOutput,
        otpLength: Int,
        localizationManager: LocalizationManagerProtocol?
    ) {
        self.output = output
        self.otpLength = otpLength
        super.init(nibName: nil, bundle: nil)
        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func loadView() {
        view = PhoneVerificationCodeViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        output.didLoad(view: self)
        applyLocalization()
        configure()

        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateTimer),
            userInfo: nil,
            repeats: true
        )
        timer?.fire()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        rootView.resetTextFieldState()
    }

    // MARK: - Private methods

    private func didTriggerCodeMatch(code: String) {
        rootView.bind(state: .sent)
        output.send(code: code)
    }

    private func configure() {
        rootView.sendButton.addTarget(self, action: #selector(sendButtonClicked), for: .touchUpInside)
        rootView.navigationBar.backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        rootView.closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        rootView.codeInputField.sora.addHandler(for: .editingChanged) { [weak self] in
            if let code = self?.rootView.codeInputField.textField.text, code.count == self?.otpLength {
                self?.didTriggerCodeMatch(code: code)
            } else {
                self?.rootView.bind(state: .editing)
            }
        }
    }

    @objc private func updateTimer() {
        if remainingTime != 0 {
            remainingTime -= 1
            rootView.set(timerState: .inProgress(timeRemaining: timeFormatted(remainingTime)))
        } else {
            rootView.set(timerState: .finished)
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
        }
    }

    private func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    @objc private func sendButtonClicked() {
        guard let code = rootView.codeInputField.textField.text, !code.isEmpty else { return }

        output.didTapResendButton()

        remainingTime = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateTimer),
            userInfo: nil,
            repeats: true
        )
        timer?.fire()
    }

    @objc private func backButtonClicked() {
        output.didTapBackButton()
    }

    @objc private func closeButtonClicked() {
        output.didTapCloseButton()
    }
}

// MARK: - PhoneVerificationCodeViewInput

extension PhoneVerificationCodeViewController: PhoneVerificationCodeViewInput {
    func set(phone: String) {
        rootView.set(phone: phone)
    }

    func didReceive(state: SCKYCPhoneCodeState) {
        rootView.bind(state: state)
    }
}

// MARK: - Localizable

extension PhoneVerificationCodeViewController: Localizable {
    func applyLocalization() {
        rootView.locale = selectedLocale
    }
}

extension PhoneVerificationCodeViewController: HiddableBarWhenPushed {}