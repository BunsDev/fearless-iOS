import UIKit
import SoraKeystore
import RobinHood
import IrohaCrypto
import FearlessUtils

enum ExportMnemonicInteractorError: Error {
    case missingAccount
    case missingEntropy
}

final class ExportMnemonicInteractor {
    weak var presenter: ExportMnemonicInteractorOutputProtocol!

    let keystore: KeystoreProtocol
    let repository: AnyDataProviderRepository<MetaAccountModel>
    let operationManager: OperationManagerProtocol

    init(
        keystore: KeystoreProtocol,
        repository: AnyDataProviderRepository<MetaAccountModel>,
        operationManager: OperationManagerProtocol
    ) {
        self.keystore = keystore
        self.repository = repository
        self.operationManager = operationManager
    }
}

extension ExportMnemonicInteractor: ExportMnemonicInteractorInputProtocol {
    func fetchExportDataForWallet(wallet: MetaAccountModel, accounts: [ChainAccountInfo]) {
        var models: [ExportMnemonicData] = []
        for chainAccount in accounts {
            do {
                let accountId = chainAccount.account.isChainAccount ? chainAccount.account.accountId : nil
                let entropyTag = KeystoreTagV2.entropyTagForMetaId(wallet.metaId, accountId: accountId)
                let entropy = try keystore.fetchKey(for: entropyTag)

                let mnemonic = try IRMnemonicCreator().mnemonic(fromEntropy: entropy)
                let derivationPathTag = chainAccount.chain.isEthereumBased ?
                    KeystoreTagV2.ethereumDerivationTagForMetaId(wallet.metaId, accountId: accountId) :
                    KeystoreTagV2.substrateDerivationTagForMetaId(wallet.metaId, accountId: accountId)
                let derivationPath: String? = try keystore.fetchDeriviationForAddress(derivationPathTag)

                let data = ExportMnemonicData(
                    mnemonic: mnemonic,
                    derivationPath: derivationPath,
                    cryptoType: chainAccount.account.isEthereumBased ? nil : chainAccount.account.cryptoType,
                    chain: chainAccount.chain
                )

                models.append(data)
            } catch {}
        }

        presenter.didReceive(exportDatas: models)
    }

    func fetchExportDataForAddress(_ address: String, chain: ChainModel) {
        guard let metaAccount = SelectedWalletSettings.shared.value else {
            presenter.didReceive(error: ExportMnemonicInteractorError.missingAccount)
            return
        }

        fetchChainAccount(
            chain: chain,
            address: address,
            from: repository,
            operationManager: operationManager
        ) { [weak self] result in
            switch result {
            case let .success(chainRespone):
                guard let response = chainRespone,
                      let accountId = metaAccount.fetch(for: chain.accountRequest())?.accountId else {
                    self?.presenter.didReceive(error: ExportMnemonicInteractorError.missingAccount)
                    return
                }
                self?.fetchExportData(
                    metaId: metaAccount.metaId,
                    accountId: response.isChainAccount ? accountId : nil,
                    cryptoType: response.cryptoType,
                    chain: chain
                )
            case .failure:
                self?.presenter.didReceive(error: ExportMnemonicInteractorError.missingAccount)
            }
        }
    }

    private func fetchExportData(
        metaId: String,
        accountId: AccountId?,
        cryptoType: CryptoType,
        chain: ChainModel
    ) {
        let exportOperation: BaseOperation<ExportMnemonicData> = ClosureOperation { [weak self] in
            let entropyTag = KeystoreTagV2.entropyTagForMetaId(metaId, accountId: accountId)
            guard let entropy = try self?.keystore.fetchKey(for: entropyTag) else {
                throw ExportMnemonicInteractorError.missingEntropy
            }

            let mnemonic = try IRMnemonicCreator().mnemonic(fromEntropy: entropy)
            let derivationPathTag = chain.isEthereumBased ?
                KeystoreTagV2.ethereumDerivationTagForMetaId(metaId, accountId: accountId) :
                KeystoreTagV2.substrateDerivationTagForMetaId(metaId, accountId: accountId)
            let derivationPath: String? = try self?.keystore.fetchDeriviationForAddress(derivationPathTag)

            return ExportMnemonicData(
                mnemonic: mnemonic,
                derivationPath: derivationPath,
                cryptoType: cryptoType,
                chain: chain
            )
        }

        exportOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let model = try exportOperation
                        .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

                    self?.presenter.didReceive(exportDatas: [model])
                } catch {
                    self?.presenter.didReceive(error: error)
                }
            }
        }
        operationManager.enqueue(operations: [exportOperation], in: .transient)
    }
}

extension ExportMnemonicInteractor: AccountFetching {}
