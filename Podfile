platform :ios, '12.0'

abstract_target 'fearlessAll' do
  use_frameworks!

  pod 'FearlessUtils', :git => 'https://github.com/soramitsu/fearless-utils-iOS.git', :commit => 'baf43c6b10a6988c93a2dd07cbe12dafde94ffcb'
  pod 'SwiftLint'
  pod 'R.swift', :inhibit_warnings => true
  pod 'SoraKeystore', :git => 'https://github.com/soramitsu/keystore-iOS.git', :tag => '1.0.1'
  pod 'SoraUI', '~> 1.10.3'
  pod 'IrohaCrypto'
  pod 'RobinHood', '~> 2.6.2'
  pod 'CommonWallet/Core'
  pod 'SoraFoundation', '~> 1.0.0'
  pod 'SwiftyBeaver'
  pod 'Starscream', :git => 'https://github.com/soramitsu/fearless-starscream.git', :commit => '0540f13ffc1c5d930e76047f58175d34582ade5f'
  pod 'ReachabilitySwift'
  pod 'SnapKit', '~> 5.0.0'
  pod 'SwiftFormat/CLI', '~> 0.47.13'
  pod 'Sourcery', '~> 1.4'
  pod 'Kingfisher', :inhibit_warnings => true
  pod 'SVGKit'
  pod 'keccak.c'
  pod 'Charts', '~> 4.1.0'

  target 'fearlessTests' do
    inherit! :search_paths

    pod 'Cuckoo'
    pod 'FearlessUtils', :git => 'https://github.com/soramitsu/fearless-utils-iOS.git', :commit => 'baf43c6b10a6988c93a2dd07cbe12dafde94ffcb'
    pod 'SoraFoundation', '~> 1.0.0'
    pod 'R.swift', :inhibit_warnings => true
    pod 'FireMock', :inhibit_warnings => true
    pod 'SoraKeystore', :git => 'https://github.com/soramitsu/keystore-iOS.git', :tag => '1.0.1'
    pod 'IrohaCrypto'
    pod 'RobinHood', '~> 2.6.2'
    pod 'CommonWallet/Core'
    pod 'Sourcery', '~> 1.4'
    pod 'keccak.c'

  end

  target 'fearlessIntegrationTests'

  target 'fearless'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
