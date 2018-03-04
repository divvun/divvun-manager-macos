# Uncomment the next line to define a global platform for your project
platform :osx, '10.10'
use_frameworks!

target 'agenthelper' do
  pod 'RxSwift'
end

target 'Pahkat' do
  # Pods for Pahkat
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxFeedback'
  pod 'STPrivilegedTask', git: "https://github.com/sveinbjornt/STPrivilegedTask.git"
  pod 'BTree', '~> 4.1'
  pod 'Sparkle'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '3.11.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name =~ /-macOS$/
      target.build_configurations.each do |config|
        #config.build_settings['DYLIB_INSTALL_NAME_BASE'] = target.product_name
        config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      end
    end
  end
end
