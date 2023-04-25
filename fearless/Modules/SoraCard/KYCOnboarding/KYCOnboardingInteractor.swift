import UIKit
import PayWingsOAuthSDK
import PayWingsOnboardingKYC
import SoraFoundation
import AVFoundation

final class KYCOnboardingInteractor {
    // MARK: - Private properties

    private weak var output: KYCOnboardingInteractorOutput?
    private let data: SCKYCUserDataModel
    private let service: SCKYCService
    private let storage: SCStorage

    private var result = VerificationResult()

    init(service: SCKYCService, storage: SCStorage, data: SCKYCUserDataModel) {
        self.service = service
        self.storage = storage
        self.data = data

        result.delegate = self
    }

    private func getKycConfig() async {
        let sdkUserName = SoraCardCIKeys.username
        let sdkPassword = SoraCardCIKeys.password
        let sdkEndpoint = SoraCardCIKeys.endpoint

        let credentials = KycCredentials(username: sdkUserName, password: sdkPassword, endpointUrl: sdkEndpoint)

        let referenceNumber = await getReferenceNumber()
        let referenceId = data.referenceId

        let settings = KycSettings(
            referenceID: referenceId,
            referenceNumber: referenceNumber,
            language: ""
        )

        let userData = KycUserData(
            firstName: data.name,
            middleName: "",
            lastName: data.lastname,
            address1: "",
            address2: "",
            address3: "",
            zipCode: "",
            city: "",
            state: "",
            countryCode: "",
            email: data.email,
            mobileNumber: data.phoneNumber
        )

        let token = await SCStorage.shared.token()

        let config = KycConfig(
            credentials: credentials,
            settings: settings,
            userData: userData,
            userCredentials: UserCredentials(accessToken: token?.accessToken ?? "", refreshToken: token?.refreshToken)
        )
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.output?.didReceive(config: config, result: strongSelf.result)
        }
    }

    private func requestReferenceNumber() async -> String? {
        let result = await service.referenceNumber(
            phone: data.phoneNumber,
            email: data.email
        )
        switch result {
        case let .success(respons):
            data.referenceNumber = respons.referenceNumber
            data.referenceId = respons.referenceID
            return data.referenceNumber
        case let .failure(error):
            DispatchQueue.main.async { [weak self] in
                self?.output?.didReceive(error: error)
            }
            return nil
        }
    }

    private func getReferenceNumber() async -> String? {
        let result = await service.referenceNumber(
            phone: data.phoneNumber,
            email: data.email
        )

        switch result {
        case let .success(respons):
            data.referenceNumber = respons.referenceNumber
            data.referenceId = respons.referenceID
            return data.referenceNumber
        case let .failure(error):
            print(error) // TODO: Update UI
            return nil
        }
    }

    func set(kycId: String?) {
        guard let kycId = kycId else {
            return
        }

        data.kycId = kycId
        storage.add(kycId: kycId)
    }
}

// MARK: - KYCOnboardingInteractorInput

extension KYCOnboardingInteractor: KYCOnboardingInteractorInput {
    func startKYC() {
        Task.init {
            await self.getKycConfig()
        }
    }

    func setup(with output: KYCOnboardingInteractorOutput) {
        self.output = output
    }
}

extension KYCOnboardingInteractor: VerificationResultDelegate {
    func success(result: PayWingsOnboardingKYC.SuccessEvent) {
        set(kycId: result.KycID)

        DispatchQueue.main.async { [weak self] in
            self?.output?.didReceive(result: result)
        }
    }

    func error(result: PayWingsOnboardingKYC.ErrorEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.output?.didReceive(kycError: result)
        }
    }
}