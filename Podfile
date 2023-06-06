platform :ios, '13.0'

# Uncomment for CI
source 'https://github.com/soramitsu/SSFSpecs.git'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'fearlessAll' do
  use_frameworks!

  pod 'SwiftLint'
  pod 'R.swift', '6.1.0', :inhibit_warnings => true
  pod 'SoraKeystore', :git => 'https://github.com/soramitsu/keystore-iOS.git', :tag => '1.0.1'
  pod 'SoraUI', '~> 1.10.3'
  pod 'IrohaCrypto'
  pod 'RobinHood', '~> 2.6.7'
  pod 'CommonWallet/Core'
  pod 'SoraFoundation', '~> 1.0.0'
  pod 'SwiftyBeaver'
  pod 'Starscream', :git => 'https://github.com/soramitsu/fearless-starscream.git' , :tag => '4.0.8'
  pod 'ReachabilitySwift'
  pod 'SnapKit', '~> 5.0.0'
  pod 'SwiftFormat/CLI', '~> 0.47.13'
  pod 'Sourcery', '~> 1.4'
  pod 'Kingfisher', :inhibit_warnings => true
  pod 'SVGKit'
  pod 'keccak.c'
  pod 'Charts', '~> 4.1.0'
  pod 'XNetworking', :podspec => 'https://raw.githubusercontent.com/soramitsu/x-networking/0.0.37/AppCommonNetworking/XNetworking/XNetworking.podspec'

  pod 'SSFXCM'
  pod 'SSFExtrinsicKit'
  pod 'SSFCrypto'
  pod 'SSFSigner'
  pod 'SSFModels'
  pod 'SSFEraKit'
  pod 'SSFLogger'
  pod 'SSFRuntimeCodingService'
  pod 'SSFStorageQueryKit'
  pod 'SSFChainConnection'
  pod 'SSFNetwork'
  pod 'SSFUtils'
  pod 'SSFChainRegistry'
  
  # Development pods
#  pod 'SSFXCM', :path => '../soramitsu-shared-features-ios/SSFXCM'
#  pod 'SSFExtrinsicKit', :path => '../soramitsu-shared-features-ios/SSFExtrinsicKit'
#  pod 'SSFCrypto', :path => '../soramitsu-shared-features-ios/SSFCrypto'
#  pod 'SSFSigner', :path => '../soramitsu-shared-features-ios/SSFSigner'
#  pod 'SSFModels', :path => '../soramitsu-shared-features-ios/SSFModels'
#  pod 'SSFEraKit', :path => '../soramitsu-shared-features-ios/SSFEraKit'
#  pod 'SSFLogger', :path => '../soramitsu-shared-features-ios/SSFLogger'
#  pod 'SSFRuntimeCodingService', :path => '../soramitsu-shared-features-ios/SSFRuntimeCodingService'
#  pod 'SSFStorageQueryKit', :path => '../soramitsu-shared-features-ios/SSFStorageQueryKit'
#  pod 'SSFChainConnection', :path => '../soramitsu-shared-features-ios/SSFChainConnection'
#  pod 'SSFNetwork', :path => '../soramitsu-shared-features-ios/SSFNetwork'
#  pod 'SSFUtils', :path => '../soramitsu-shared-features-ios/SSFUtils'
#  pod 'SSFChainRegistry', :path => '../soramitsu-shared-features-ios/SSFChainRegistry'
#  pod 'SSFHelpers', :path => '../soramitsu-shared-features-ios/SSFHelpers'

  target 'fearlessTests' do
    inherit! :search_paths

    pod 'Cuckoo'
    pod 'SoraFoundation', '~> 1.0.0'
    pod 'R.swift', '6.1.0', :inhibit_warnings => true
    pod 'FireMock', :inhibit_warnings => true
    pod 'SoraKeystore', :git => 'https://github.com/soramitsu/keystore-iOS.git', :tag => '1.0.1'
    pod 'IrohaCrypto'
    pod 'RobinHood', '~> 2.6.7'
    pod 'CommonWallet/Core'
    pod 'Sourcery', '~> 1.4'
    pod 'keccak.c'

  end

  target 'fearlessIntegrationTests'

  target 'fearless'

end
