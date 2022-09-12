import Foundation
import BigInt
import SoraFoundation
import CommonWallet

final class WalletSendPresenter {
    weak var view: WalletSendViewProtocol?
    let wireframe: WalletSendWireframeProtocol
    let interactor: WalletSendInteractorInputProtocol
    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let dataValidatingFactory: BaseDataValidatingFactoryProtocol
    let logger: LoggerProtocol?
    let chainAsset: ChainAsset
    let receiverAddress: String
    let transferFinishBlock: WalletTransferFinishBlock?

    private weak var moduleOutput: WalletSendModuleOutput?

    private var totalBalanceValue: BigUInt?
    private var balance: Decimal?
    private var priceData: PriceData?
    private var tip: Decimal?
    private var fee: Decimal?
    private var blockDuration: BlockTime?
    private var minimumBalance: BigUInt?
    private var inputResult: AmountInputResult?
    private var balanceMinusFee: Decimal { (balance ?? 0) - (fee ?? 0) }

    private var amountViewModel: AmountInputViewModelProtocol?

    init(
        interactor: WalletSendInteractorInputProtocol,
        wireframe: WalletSendWireframeProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        dataValidatingFactory: BaseDataValidatingFactoryProtocol,
        localizationManager: LocalizationManagerProtocol,
        logger: LoggerProtocol? = nil,
        chainAsset: ChainAsset,
        receiverAddress: String,
        transferFinishBlock: WalletTransferFinishBlock?
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.balanceViewModelFactory = balanceViewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.logger = logger
        self.chainAsset = chainAsset
        self.receiverAddress = receiverAddress
        self.transferFinishBlock = transferFinishBlock
        self.localizationManager = localizationManager
    }

    private func provideViewModel() {
        let viewModel = WalletSendViewModel(
            assetBalanceViewModel: provideAssetVewModel(),
            tipRequired: chainAsset.chain.isTipRequired,
            tipViewModel: provideTipViewModel(),
            feeViewModel: provideFeeViewModel(),
            amountInputViewModel: provideInputViewModel()
        )

        DispatchQueue.main.async {
            self.view?.didReceive(state: .loaded(viewModel))
        }
    }

    private func provideAssetVewModel() -> AssetBalanceViewModelProtocol? {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee) ?? 0.0

        return balanceViewModelFactory.createAssetBalanceViewModel(
            inputAmount,
            balance: balance,
            priceData: priceData
        ).value(for: selectedLocale)
    }

    private func provideTipViewModel() -> BalanceViewModelProtocol? {
        tip
            .map { balanceViewModelFactory.balanceFromPrice($0, priceData: priceData) }?
            .value(for: selectedLocale)
    }

    private func provideFeeViewModel() -> BalanceViewModelProtocol? {
        fee
            .map { balanceViewModelFactory.balanceFromPrice($0, priceData: priceData) }?
            .value(for: selectedLocale)
    }

    private func provideInputViewModel() -> AmountInputViewModelProtocol? {
        guard let amountViewModel = amountViewModel else {
            let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee)

            let viewModel = balanceViewModelFactory.createBalanceInputViewModel(inputAmount)
                .value(for: selectedLocale)
            amountViewModel = viewModel
            return viewModel
        }

        return amountViewModel
    }

    private func provideInputViewModelIfRate() {
        guard case .rate = inputResult else {
            return
        }

        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee)

        let inputViewModel = balanceViewModelFactory.createBalanceInputViewModel(inputAmount)
            .value(for: selectedLocale)
        amountViewModel = inputViewModel

        let viewModel = WalletSendViewModel(
            assetBalanceViewModel: provideAssetVewModel(),
            tipRequired: chainAsset.chain.isTipRequired,
            tipViewModel: provideTipViewModel(),
            feeViewModel: provideFeeViewModel(),
            amountInputViewModel: inputViewModel
        )

        view?.didReceive(state: .loaded(viewModel))
    }

    private func refreshFee() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee) ?? 0
        guard let amount = inputAmount.toSubstrateAmount(
            precision: Int16(chainAsset.asset.precision)
        ) else {
            return
        }

        view?.didStartFeeCalculation()

        let tip = self.tip?.toSubstrateAmount(precision: Int16(chainAsset.asset.precision))
        interactor.estimateFee(for: amount, tip: tip)
    }
}

extension WalletSendPresenter: WalletSendPresenterProtocol {
    func setup() {
        interactor.setup()

        provideViewModel()

        if !chainAsset.chain.isTipRequired {
            // To not distract users with two different fees one by one, let's wait for tip, and then refresh fee
            refreshFee()
        }
    }

    func selectAmountPercentage(_ percentage: Float) {
        amountViewModel = nil
        inputResult = .rate(Decimal(Double(percentage)))

        refreshFee()
        provideViewModel()
    }

    func updateAmount(_ newValue: Decimal) {
        inputResult = .absolute(newValue)

        refreshFee()
        provideViewModel()
    }

    func didTapBackButton() {
        wireframe.close(view: view)
    }

    func didTapContinueButton() {
        let sendAmountDecimal = inputResult?.absoluteValue(from: balanceMinusFee)
        let sendAmountValue = sendAmountDecimal?.toSubstrateAmount(precision: Int16(chainAsset.asset.precision))
        let spendingValue = (sendAmountValue ?? 0) +
            (fee?.toSubstrateAmount(precision: Int16(chainAsset.asset.precision)) ?? 0)

        DataValidationRunner(validators: [
            dataValidatingFactory.has(fee: fee, locale: selectedLocale, onError: { [weak self] in
                self?.refreshFee()
            }),

            dataValidatingFactory.canPayFeeAndAmount(
                balance: balance,
                fee: fee,
                spendingAmount: sendAmountDecimal,
                locale: selectedLocale
            ),

            dataValidatingFactory.exsitentialDepositIsNotViolated(
                spendingAmount: spendingValue,
                totalAmount: totalBalanceValue,
                minimumBalance: minimumBalance,
                locale: selectedLocale,
                chainAsset: chainAsset
            )

        ]).runValidation { [weak self] in
            guard let strongSelf = self, let amount = sendAmountDecimal else { return }
            strongSelf.wireframe.presentConfirm(
                from: strongSelf.view,
                chainAsset: strongSelf.chainAsset,
                receiverAddress: strongSelf.receiverAddress,
                amount: amount,
                tip: strongSelf.tip,
                transferFinishBlock: strongSelf.transferFinishBlock
            )
        }
    }
}

extension WalletSendPresenter: WalletSendInteractorOutputProtocol {
    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>) {
        switch result {
        case let .success(accountInfo):
            totalBalanceValue = accountInfo?.data.total ?? 0

            balance = accountInfo.map {
                Decimal.fromSubstrateAmount($0.data.available, precision: Int16(chainAsset.asset.precision))
            } ?? 0.0

            provideViewModel()
        case let .failure(error):
            logger?.error("Did receive account info error: \(error)")
        }
    }

    func didReceiveBlockDuration(result: Result<BlockTime, Error>) {
        switch result {
        case let .success(blockDuration):
            self.blockDuration = blockDuration

            provideViewModel()
        case let .failure(error):
            logger?.error("Did receive block duration error: \(error)")
        }
    }

    func didReceiveMinimumBalance(result: Result<BigUInt, Error>) {
        switch result {
        case let .success(minimumBalance):
            self.minimumBalance = minimumBalance

            provideViewModel()
        case let .failure(error):
            logger?.error("Did receive minimum balance error: \(error)")
        }
    }

    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData

            provideViewModel()
        case let .failure(error):
            logger?.error("Did receive price error: \(error)")
        }
    }

    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>) {
        view?.didStopFeeCalculation()
        switch result {
        case let .success(dispatchInfo):
            fee = BigUInt(dispatchInfo.fee).map {
                Decimal.fromSubstrateAmount($0, precision: Int16(chainAsset.asset.precision))
            } ?? nil

            provideViewModel()
            provideInputViewModelIfRate()
        case let .failure(error):
            logger?.error("Did receive fee error: \(error)")
        }
    }

    func didReceiveTip(result: Result<BigUInt, Error>) {
        view?.didStopTipCalculation()
        switch result {
        case let .success(tip):
            self.tip = Decimal.fromSubstrateAmount(tip, precision: Int16(chainAsset.asset.precision))

            provideViewModel()
            provideInputViewModelIfRate()
            refreshFee()
        case let .failure(error):
            logger?.error("Did receive tip error: \(error)")

            // Even though no tip received, let's refresh fee, because we didn't load it at start
            refreshFee()
        }
    }
}

extension WalletSendPresenter: Localizable {
    func applyLocalization() {}
}
