import BigInt
import SoraFoundation

protocol AnalyticsViewModelFactoryProtocol {
    func createRewardsViewModel(
        from data: [SubqueryRewardItemData],
        priceData: PriceData?,
        period: AnalyticsPeriod
    ) -> LocalizableResource<AnalyticsRewardsViewModel>
}

final class AnalyticsViewModelFactory: AnalyticsViewModelFactoryProtocol {
    private let chain: Chain
    private let balanceViewModelFactory: BalanceViewModelFactoryProtocol

    init(
        chain: Chain,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol
    ) {
        self.chain = chain
        self.balanceViewModelFactory = balanceViewModelFactory
    }

    func createRewardsViewModel(
        from data: [SubqueryRewardItemData],
        priceData: PriceData?,
        period: AnalyticsPeriod
    ) -> LocalizableResource<AnalyticsRewardsViewModel> {
        LocalizableResource { [self] locale in
            var resultArray = [Decimal](repeating: 0.0, count: period.chartBarsCount)

            let onlyRewards = data.filter { $0.isReward }
            let filteredByPeriod = onlyRewards
                .filter { itemData in
                    itemData.timestamp >= period.timestampInterval.0 &&
                        itemData.timestamp <= period.timestampInterval.1
                }

            let groupedByPeriod = filteredByPeriod
                .reduce(resultArray) { array, value in
                    let distance = period.timestampInterval.1 - period.timestampInterval.0
                    let index = Int(Double(value.timestamp - period.timestampInterval.0) / Double(distance) * Double(period.chartBarsCount))
                    guard
                        let amountValue = BigUInt(value.amount),
                        let decimal = Decimal.fromSubstrateAmount(
                            amountValue,
                            precision: self.chain.addressType.precision
                        )
                    else { return array }
                    resultArray[index] += decimal
                    return resultArray
                }

            let chartDoubles = groupedByPeriod.map { Double(truncating: $0 as NSNumber) }
            let chartData = ChartData(amounts: chartDoubles, xAxisValues: period.xAxisValues)

            let totalReceived = groupedByPeriod.reduce(Decimal(0), +)
            let totalReceivedToken = self.balanceViewModelFactory.balanceFromPrice(
                totalReceived,
                priceData: priceData
            ).value(for: locale)

            let dateFormatter = self.weekDateFormatter(for: locale)
            let startDate = Date(timeIntervalSince1970: TimeInterval(period.timestampInterval.0))
            let endDate = Date(timeIntervalSince1970: TimeInterval(period.timestampInterval.1))

            let periodText = dateFormatter.string(from: startDate, to: endDate)
            let summaryViewModel = AnalyticsSummaryRewardViewModel(
                title: periodText,
                tokenAmount: totalReceivedToken.amount,
                usdAmount: totalReceivedToken.price,
                indicatorColor: nil
            )
            let receivedViewModel = AnalyticsSummaryRewardViewModel(
                title: "Received",
                tokenAmount: totalReceivedToken.amount,
                usdAmount: totalReceivedToken.price,
                indicatorColor: R.color.colorGray()
            )

            let payableViewModel = AnalyticsSummaryRewardViewModel(
                title: "Payable",
                tokenAmount: "0.0 KSM",
                usdAmount: nil,
                indicatorColor: R.color.colorAccent()
            )
            return AnalyticsRewardsViewModel(
                chartData: chartData,
                summaryViewModel: summaryViewModel,
                receivedViewModel: receivedViewModel,
                payableViewModel: payableViewModel
            )
        }
    }

    private func weekDateFormatter(for locale: Locale) -> DateIntervalFormatter {
        let dateFormatter = DateIntervalFormatter()
        dateFormatter.dateTemplate = "MMM d-d"
        dateFormatter.locale = locale
        return dateFormatter
    }
}