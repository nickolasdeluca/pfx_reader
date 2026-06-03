#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pfx_reader.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pfx_reader'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin to read PKCS#12 certificate fields and sign data.'
  s.description      = <<-DESC
Flutter plugin to read PKCS#12 (.pfx/.p12) certificate fields and sign data
using the embedded private key. Supports Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/nickolasdeluca/pfx_reader'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nickolas Deluca' => 'nickolasdeluca@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'pfx_reader/Sources/pfx_reader/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'pfx_reader_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
