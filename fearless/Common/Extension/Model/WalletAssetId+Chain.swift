import Foundation
import IrohaCrypto

extension WalletAssetId {
    var chain: Chain? {
        switch self {
        case .xor:
            return .sora
        case .dot:
            return .polkadot
        case .kusama:
            return .kusama
        case .westend:
            return .westend
        case .usd:
            return nil
        }
    }
}
