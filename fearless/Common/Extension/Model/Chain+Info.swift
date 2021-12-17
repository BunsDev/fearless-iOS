import Foundation
import FearlessUtils

extension Chain {
    var genesisHash: String {
        switch self {
        case .polkadot: return "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3"
        case .kusama: return "b0a8d493285c2df73290dfb7e61f870f17b41801197a149ca93654499ea3dafe"
        case .westend: return "e143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e"
        case .rococo: return "1ab7fbd1d7c3532386268ec23fe4ff69f5bb6b3e3697947df3a2ec2786424de3"
        }
    }

    var erasPerDay: Int {
        switch self {
        case .polkadot: return 1
        case .kusama, .westend, .rococo: return 4
        }
    }

    func polkascanExtrinsicURL(_ hash: String) -> URL? {
        switch self {
        case .polkadot:
            return URL(string: "https://polkascan.io/polkadot/extrinsic/\(hash)")
        case .kusama:
            return URL(string: "https://polkascan.io/kusama/extrinsic/\(hash)")
        default:
            return nil
        }
    }

    func polkascanAddressURL(_ address: String) -> URL? {
        switch self {
        case .polkadot:
            return URL(string: "https://polkascan.io/polkadot/account/\(address)")
        case .kusama:
            return URL(string: "https://polkascan.io/kusama/account/\(address)")
        default:
            return nil
        }
    }

    func polkascanEventURL(_ eventId: String) -> URL? {
        switch self {
        case .polkadot:
            return URL(string: "https://polkascan.io/polkadot/event/\(eventId)")
        case .kusama:
            return URL(string: "https://polkascan.io/kusama/event/\(eventId)")
        default:
            return nil
        }
    }

    func subscanExtrinsicURL(_ hash: String) -> URL? {
        switch self {
        case .polkadot:
            return URL(string: "https://polkadot.subscan.io/extrinsic/\(hash)")
        case .kusama:
            return URL(string: "https://kusama.subscan.io/extrinsic/\(hash)")
        case .westend:
            return URL(string: "https://westend.subscan.io/extrinsic/\(hash)")
        default:
            return nil
        }
    }

    func subscanAddressURL(_ address: String) -> URL? {
        switch self {
        case .polkadot:
            return URL(string: "https://polkadot.subscan.io/account/\(address)")
        case .kusama:
            return URL(string: "https://kusama.subscan.io/account/\(address)")
        case .westend:
            return URL(string: "https://westend.subscan.io/account/\(address)")
        default:
            return nil
        }
    }

    // MARK: - Local types

    func preparedDefaultTypeDefPath() -> String? {
        R.file.runtimeEmptyJson.path()
    }

    func preparedNetworkTypeDefPath() -> String? {
        R.file.runtimeEmptyJson.path()
    }

    // MARK: - Remote types

    private var remoteRegistryBranch: String {
        "v14-metadata-ios-support"
//        "master"
    }

    // swiftlint:disable line_length
    private func remoteRegistryUrl(for file: String) -> URL? {
        let urlString = "https://raw.githubusercontent.com/soramitsu/fearless-utils/\(remoteRegistryBranch)/scalecodec/type_registry"
        let url = URL(string: urlString)
        return url?.appendingPathComponent(file)
    }

    func typeDefDefaultFileURL() -> URL? {
        remoteRegistryUrl(for: "default_v14.json")
    }

    func typeDefNetworkFileURL() -> URL? {
        let suffix = "_v14" // always apply for 1.x

        switch self {
        case .westend: return remoteRegistryUrl(for: "westend\(suffix).json")
        case .kusama: return remoteRegistryUrl(for: "kusama\(suffix).json")
        case .polkadot: return remoteRegistryUrl(for: "polkadot\(suffix).json")
        case .rococo: return remoteRegistryUrl(for: "rococo\(suffix).json")
        }
    }
    
    // MARK: - Crowdloans

    func crowdloanDisplayInfoURL() -> URL {
        let base = URL(string: "https://raw.githubusercontent.com/soramitsu/fearless-utils/master/crowdloan/")!

        switch self {
        case .westend: return base.appendingPathComponent("westend.json")
        case .kusama: return base.appendingPathComponent("kusama.json")
        case .polkadot: return base.appendingPathComponent("polkadot.json")
        case .rococo: return base.appendingPathComponent("rococo.json")
        }
    }
    // swiftlint:enable line_length
}
