#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hentai_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hentai_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    # First argument is relative path to the `rust` folder, second is name of rust library
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust hentai_flutter',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    # Let XCode know that the static library referenced in -force_load below is
    # created by this build step.
    :output_files => ["${BUILT_PRODUCTS_DIR}/libhentai_flutter.a"],
  }

  # unrar-ng ships C++ objects inside the Rust staticlib. force_load must reach the
  # Runner (user) target under CocoaPods static linkage; -lc++ resolves std:: symbols.
  # See flutter_rust_bridge#1610 / #3173.
  rust_lib_ldflags = '$(inherited) -force_load "${BUILT_PRODUCTS_DIR}/libhentai_flutter.a" -lc++ -lc++abi'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Flutter.framework does not contain a i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_LDFLAGS' => rust_lib_ldflags,
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => rust_lib_ldflags,
  }
end
