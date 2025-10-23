Pod::Spec.new do |s|
  s.name             = 'device_trust'
  s.version          = '1.0.0'
  s.summary          = 'Device Trust: jailbreak/root & hook/Frida heuristics (iOS/Android)'
  s.description      = <<-DESC
Heuristic device trust detection without third-party SDKs:
- iOS: Swift + Objective-C++
- Android: Kotlin + C++
Exposes a typed Flutter API via MethodChannel.
  DESC
  s.homepage         = 'https://github.com/MuhammedErdemKazanci/device_trust'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mikoloy' => 'hello@mikoloyapps.com' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.dependency       'Flutter'
  if s.respond_to?(:privacy_manifest_files=)
    s.privacy_manifest_files = 'Resources/PrivacyInfo.xcprivacy'
  else
    # Fallback for CocoaPods < 1.16: ship the privacy manifest as a resource
    s.resources = ['Resources/PrivacyInfo.xcprivacy']
  end

  # All source files (Swift + ObjC/C++)
  s.source_files = 'Classes/**/*.{swift,h,m,mm,cc,cpp}'
  
  # Specific public header (umbrella will import this)
  s.public_header_files = 'Classes/DeviceTrust/DeviceTrustNative.h'
  
  # Preserve directory structure for imports
  s.preserve_paths = 'Classes/DeviceTrust/**/*'
  
  # xcconfig for pod target
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++17'
  }

  # Module is static by default in Flutter, no special vendored libs.
end
