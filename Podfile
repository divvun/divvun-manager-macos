# Uncomment the next line to define a global platform for your project
platform :osx, '10.12'
#use_frameworks!
use_modular_headers!

target 'PahkatUpdateAgent' do
  pod 'RxSwift', '~> 5.1'
  pod "PahkatClient", :git => "https://github.com/divvun/pahkat-client-sdk-swift", :submodules => true
end

target 'PahkatAdminService' do
  pod 'RxSwift', '~> 5.1'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '4.1.1'
  pod "PahkatClient", :git => "https://github.com/divvun/pahkat-client-sdk-swift", :submodules => true
  pod 'XCGLogger'
end

target 'Pahkat' do
  # Pods for Pahkat
  pod 'RxSwift', '~> 5.1'
  pod 'RxCocoa', '~> 5.1'
  pod 'RxFeedback', '~> 3.0'
  pod 'BTree', '~> 4.1'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '4.1.1'
  pod 'XCGLogger'
  pod "PahkatClient", :git => "https://github.com/divvun/pahkat-client-sdk-swift", :submodules => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name =~ /-macOS$/
      target.build_configurations.each do |config|
        #config.build_settings['DYLIB_INSTALL_NAME_BASE'] = target.product_name
        #config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      end
    end
  end
end
