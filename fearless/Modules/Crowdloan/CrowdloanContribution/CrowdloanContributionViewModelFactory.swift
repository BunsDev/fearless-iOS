import Foundation
import SoraFoundation
import CommonWallet
import FearlessUtils

protocol CrowdloanContributionViewModelFactoryProtocol {
    func createContributionSetupViewModel(
        from crowdloan: Crowdloan,
        displayInfo: CrowdloanDisplayInfo?,
        metadata: CrowdloanMetadata,
        locale: Locale,
        previousContribution: CrowdloanContribution?
    ) -> CrowdloanContributionSetupViewModel

    func createContributionConfirmViewModel(
        from crowdloan: Crowdloan,
        metadata: CrowdloanMetadata,
        confirmationData: CrowdloanContributionConfirmData,
        locale: Locale,
        previousContribution: CrowdloanContribution?
    ) throws -> CrowdloanContributeConfirmViewModel

    func createEstimatedRewardViewModel(
        inputAmount: Decimal,
        displayInfo: CrowdloanDisplayInfo,
        locale: Locale
    ) -> String?

    func createAdditionalBonusViewModel(
        inputAmount: Decimal,
        displayInfo: CrowdloanDisplayInfo,
        bonusRate: Decimal?,
        locale: Locale
    ) -> String?

    func createLearnMoreViewModel(
        from displayInfo: CrowdloanDisplayInfo,
        locale: Locale
    ) -> LearnMoreViewModel
}

final class CrowdloanContributionViewModelFactory {
    let chainDateCalculator: ChainDateCalculatorProtocol
    let amountFormatterFactory: NumberFormatterFactoryProtocol
    let asset: WalletAsset

    struct DisplayLeasingPeriod {
        let leasingPeriod: String
        let leasingEndDate: String
    }

    struct DisplayProgress {
        let absoluteProgress: String
        let percentageProgress: String
    }

    private lazy var iconGenerator = PolkadotIconGenerator()

    init(
        amountFormatterFactory: NumberFormatterFactoryProtocol,
        chainDateCalculator: ChainDateCalculatorProtocol,
        asset: WalletAsset
    ) {
        self.amountFormatterFactory = amountFormatterFactory
        self.chainDateCalculator = chainDateCalculator
        self.asset = asset
    }

    private func createDisplayLeasingPeriod(
        from crowdloan: Crowdloan,
        metadata: CrowdloanMetadata,
        locale: Locale
    ) -> DisplayLeasingPeriod {
        let leasingPeriodTitle: String
        let leasingEndDateTitle: String

        var calendar = Calendar.current
        calendar.locale = locale

        let maybeLeasingTimeInterval = chainDateCalculator.intervalTillPeriod(
            crowdloan.fundInfo.lastPeriod + 1,
            metadata: metadata,
            calendar: calendar
        )

        if let leasingTimeInterval = maybeLeasingTimeInterval {
            if leasingTimeInterval.duration.daysFromSeconds > 0 {
                leasingPeriodTitle = R.string.localizable.commonDaysFormat(
                    format: leasingTimeInterval.duration.daysFromSeconds,
                    preferredLanguages: locale.rLanguages
                )
            } else {
                let time = try? TotalTimeFormatter().string(from: leasingTimeInterval.duration)
                leasingPeriodTitle = time ?? ""
            }

            let dateFormatter = DateFormatter.shortDate.value(for: locale)
            let dateString = dateFormatter.string(from: leasingTimeInterval.tillDate)
            leasingEndDateTitle = R.string.localizable.commonTillDate(dateString, preferredLanguages: locale.rLanguages)

        } else {
            leasingPeriodTitle = ""
            leasingEndDateTitle = ""
        }

        return DisplayLeasingPeriod(leasingPeriod: leasingPeriodTitle, leasingEndDate: leasingEndDateTitle)
    }

    private func createDisplayProgress(
        from crowdloan: Crowdloan,
        metadata _: CrowdloanMetadata,
        locale: Locale
    ) -> DisplayProgress {
        let tokenFormatter = amountFormatterFactory.createTokenFormatter(for: asset).value(for: locale)
        let displayFormatter = amountFormatterFactory.createDisplayFormatter(for: asset).value(for: locale)

        let percentFormatter = NumberFormatter.percentSingle
        percentFormatter.locale = locale

        if
            let raised = Decimal.fromSubstrateAmount(crowdloan.fundInfo.raised, precision: asset.precision),
            let cap = Decimal.fromSubstrateAmount(crowdloan.fundInfo.cap, precision: asset.precision),
            let raisedString = displayFormatter.stringFromDecimal(raised),
            let totalString = tokenFormatter.stringFromDecimal(cap),
            cap > 0,
            let percentageString = percentFormatter.string(from: (raised / cap) as NSNumber) {
            let absoluteProgress = R.string.localizable.crowdloanRaisedAmount(
                raisedString,
                totalString,
                preferredLanguages: locale.rLanguages
            )

            return DisplayProgress(absoluteProgress: absoluteProgress, percentageProgress: percentageString)
        } else {
            return DisplayProgress(absoluteProgress: "", percentageProgress: "")
        }
    }

    private func createTimeLeft(
        for crowdloan: Crowdloan,
        metadata: CrowdloanMetadata,
        locale: Locale
    ) -> String {
        let remainedTime = crowdloan.remainedTime(
            at: metadata.blockNumber,
            blockDuration: metadata.blockDuration
        )

        if remainedTime.daysFromSeconds > 0 {
            return R.string.localizable.commonDaysFormat(
                format: remainedTime.daysFromSeconds,
                preferredLanguages: locale.rLanguages
            )
        } else {
            let time = try? TotalTimeFormatter().string(from: remainedTime)
            return time ?? ""
        }
    }

    private func createTitle(
        from crowdloan: Crowdloan,
        displayInfo: CrowdloanDisplayInfo?,
        locale: Locale
    ) -> String {
        if let displayInfo = displayInfo {
            return displayInfo.name + "(\(displayInfo.token))"
        } else {
            return NumberFormatter.quantity.localizableResource().value(for: locale).string(
                from: NSNumber(value: crowdloan.paraId)
            ) ?? ""
        }
    }

    private func createLearnMore(
        from displayInfo: CrowdloanDisplayInfo,
        locale: Locale
    ) -> LearnMoreViewModel {
        let iconViewModel: ImageViewModelProtocol? = URL(string: displayInfo.icon).map { RemoteImageViewModel(url: $0)
        }

        let title = R.string.localizable.crowdloanLearn(displayInfo.name, preferredLanguages: locale.rLanguages)
        return LearnMoreViewModel(iconViewModel: iconViewModel, title: title)
    }
}

extension CrowdloanContributionViewModelFactory: CrowdloanContributionViewModelFactoryProtocol {
    func createContributionSetupViewModel(
        from crowdloan: Crowdloan,
        displayInfo: CrowdloanDisplayInfo?,
        metadata: CrowdloanMetadata,
        locale: Locale,
        previousContribution: CrowdloanContribution?
    ) -> CrowdloanContributionSetupViewModel {
        let displayLeasingPeriod = createDisplayLeasingPeriod(
            from: crowdloan,
            metadata: metadata,
            locale: locale
        )

        let displayProgress = createDisplayProgress(from: crowdloan, metadata: metadata, locale: locale)

        let remainedTime = createTimeLeft(for: crowdloan, metadata: metadata, locale: locale)

        let title = createTitle(from: crowdloan, displayInfo: displayInfo, locale: locale)

        let learnMoreViewModel = displayInfo.map { createLearnMore(from: $0, locale: locale) }

        let tokenFormatter = amountFormatterFactory.createTokenFormatter(for: asset).value(for: locale)

        let contributionString: String? = {
            if
                let contributionInPlank = previousContribution?.balance,
                let contributionDecimal = Decimal.fromSubstrateAmount(contributionInPlank, precision: asset.precision) {
                return tokenFormatter.stringFromDecimal(contributionDecimal).map { value in
                    R.string.localizable.crowdloanContributionFormat(value, preferredLanguages: locale.rLanguages)
                }
            } else {
                return nil
            }
        }()

        return CrowdloanContributionSetupViewModel(
            title: title,
            leasingPeriod: displayLeasingPeriod.leasingPeriod,
            leasingCompletionDate: displayLeasingPeriod.leasingEndDate,
            raisedProgress: displayProgress.absoluteProgress,
            raisedPercentage: displayProgress.percentageProgress,
            remainedTime: remainedTime,
            learnMore: learnMoreViewModel,
            previousContribution: contributionString
        )
    }

    func createContributionConfirmViewModel(
        from crowdloan: Crowdloan,
        metadata: CrowdloanMetadata,
        confirmationData: CrowdloanContributionConfirmData,
        locale: Locale,
        previousContribution: CrowdloanContribution?
    ) throws -> CrowdloanContributeConfirmViewModel {
        let displayLeasingPeriod = createDisplayLeasingPeriod(
            from: crowdloan,
            metadata: metadata,
            locale: locale
        )

        let senderIcon = try iconGenerator.generateFromAddress(confirmationData.displayAddress.address)
        let senderName = !confirmationData.displayAddress.username.isEmpty ?
            confirmationData.displayAddress.username : confirmationData.displayAddress.address

        let formatter = amountFormatterFactory.createDisplayFormatter(for: asset).value(for: locale)

        var inputAmountString: String?
        if let contribution = confirmationData.contribution {
            inputAmountString = formatter.stringFromDecimal(contribution)
        }

        let tokenFormatter = amountFormatterFactory.createTokenFormatter(for: asset).value(for: locale)

        let contributionString: String? = {
            if
                let contributionInPlank = previousContribution?.balance,
                let contributionDecimal = Decimal.fromSubstrateAmount(contributionInPlank, precision: asset.precision) {
                return tokenFormatter.stringFromDecimal(contributionDecimal).map { value in
                    R.string.localizable.crowdloanContributionFormat(value, preferredLanguages: locale.rLanguages)
                }
            } else {
                return nil
            }
        }()

        return CrowdloanContributeConfirmViewModel(
            senderIcon: senderIcon,
            senderName: senderName,
            inputAmount: inputAmountString,
            leasingPeriod: displayLeasingPeriod.leasingPeriod,
            leasingCompletionDate: displayLeasingPeriod.leasingEndDate,
            previousContribution: contributionString
        )
    }

    func createEstimatedRewardViewModel(
        inputAmount: Decimal,
        displayInfo: CrowdloanDisplayInfo,
        locale: Locale
    ) -> String? {
        let formatter = amountFormatterFactory.createDisplayFormatter(for: nil).value(for: locale)

        return displayInfo.rewardRate
            .map { formatter.stringFromDecimal(inputAmount * $0) }?
            .map { "\($0) \(displayInfo.token)" }
    }

    func createAdditionalBonusViewModel(
        inputAmount: Decimal,
        displayInfo: CrowdloanDisplayInfo,
        bonusRate: Decimal?,
        locale: Locale
    ) -> String? {
        guard let bonusRate = bonusRate else {
            return R.string.localizable.crowdloanEmptyBonusTitle(
                preferredLanguages: locale.rLanguages
            )
        }

        guard bonusRate > 0 else { return "" }

        let formatter = amountFormatterFactory.createDisplayFormatter(for: nil).value(for: locale)

        return displayInfo.rewardRate
            .map { formatter.stringFromDecimal(inputAmount * $0 * bonusRate) }?
            .map { "\($0) \(displayInfo.token)" }
    }

    func createLearnMoreViewModel(
        from displayInfo: CrowdloanDisplayInfo,
        locale: Locale
    ) -> LearnMoreViewModel {
        createLearnMore(from: displayInfo, locale: locale)
    }
}
