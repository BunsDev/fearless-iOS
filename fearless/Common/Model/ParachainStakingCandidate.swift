import Foundation
import CommonWallet

struct ParachainStakingCandidateInfo: Equatable {
    let address: AccountAddress
    let owner: AccountId
    let amount: AmountDecimal
    let metadata: ParachainStakingCandidateMetadata?
    let identity: AccountIdentity?

    var oversubscribed: Bool {
        // TODO: Check this logic
        metadata?.topCapacity == .full
    }

    var hasIdentity: Bool {
        identity != nil
    }

    var stakeReturn: Decimal {
        Decimal.zero
    }
}

struct ParachainStakingCandidate: Decodable, Equatable {
    let owner: AccountId
    let amount: AmountDecimal
}