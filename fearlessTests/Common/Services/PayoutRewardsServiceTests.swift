import XCTest
import SoraKeystore
@testable import fearless

class PayoutRewardsServiceTests: XCTestCase {

    func testPayoutRewardsList() {
        let storageFacade = SubstrateStorageTestFacade()
        let operationManager = OperationManagerFacade.sharedManager
        let logger = Logger.shared

        let providerFactory = SubstrateDataProviderFactory(
            facade: storageFacade,
            operationManager: operationManager,
            logger: logger
        )

        let settings = InMemorySettingsManager()
        let chain = Chain.westend

        try! AccountCreationHelper.createAccountFromMnemonic(
            cryptoType: .sr25519,
            networkType: chain,
            keychain: InMemoryKeychain(),
            settings: settings
        )
        let selectedAccount = "5DEwU2U97RnBHCpfwHMDfJC7pqAdfWaPFib9wiZcr2ephSfT"

        WebSocketService.shared.setup()
        let connection = WebSocketService.shared.connection!
        let runtimeService = RuntimeRegistryFacade.sharedService
        runtimeService.setup()

        let service = PayoutRewardsService(
            selectedAccountAddress: selectedAccount,
            chain: chain,
            runtimeCodingService: runtimeService,
            engine: connection,
            operationManager: operationManager,
            providerFactory: providerFactory,
            subscanOperationFactory: SubscanOperationFactory()
        )

        let expectation = XCTestExpectation()
        service.fetchPayoutRewards { result in
            switch result {
            case let .success(rewards):
                XCTAssert(!rewards.isEmpty)
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 30)
    }
}
