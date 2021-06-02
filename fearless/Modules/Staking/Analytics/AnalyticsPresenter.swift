import Foundation
import BigInt

final class AnalyticsPresenter {
    weak var view: AnalyticsViewProtocol?
    let wireframe: AnalyticsWireframeProtocol
    let interactor: AnalyticsInteractorInputProtocol
    private let viewModelFactory: AnalyticsViewModelFactoryProtocol
    private var rewardsData = [SubscanRewardItemData]()
    private var selectedPeriod = AnalyticsPeriod.weekly
    private var priceData: PriceData?

    init(
        interactor: AnalyticsInteractorInputProtocol,
        wireframe: AnalyticsWireframeProtocol,
        viewModelFactory: AnalyticsViewModelFactoryProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.viewModelFactory = viewModelFactory
    }

    private func updateView() {
        let viewModel = viewModelFactory.createViewModel(
            from: rewardsData,
            priceData: priceData,
            period: selectedPeriod
        )
        view?.configure(with: viewModel)
    }
}

extension AnalyticsPresenter: AnalyticsPresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func didSelectPeriod(_ period: AnalyticsPeriod) {
        selectedPeriod = period
        updateView()
    }
}

extension AnalyticsPresenter: AnalyticsInteractorOutputProtocol {
    func didReceieve(rewardItemData: Result<[SubscanRewardItemData], Error>) {
        switch rewardItemData {
        case let .success(data):
            rewardsData = data
            updateView()
        case let .failure(error):
            // handle(error: error)
            print(error)
        }
    }

    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData
            updateView()
        case let .failure(error):
            print(error)
        }
    }
}
