#!/bin/bash

echo "Starting iOS prebuild configuration..."

# Path to the Xcode project file
PBXPROJ_PATH="ios/Runner.xcodeproj/project.pbxproj"
PODFILE_PATH="ios/Podfile"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Warning: This script is designed to run on macOS. Some commands might fail."
fi

# Ensure required tools are available
if ! command_exists "sed"; then
    echo "Error: sed is required but not installed."
    exit 1
fi

# Clean up previous builds
echo "Cleaning previous builds..."
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
fi
if [ -f "ios/Podfile.lock" ]; then
    rm ios/Podfile.lock
fi

# Update minimum iOS deployment target to 14.0
echo "Updating deployment target in Xcode project..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9]\{1,2\}\.[0-9]\{1,2\};/IPHONEOS_DEPLOYMENT_TARGET = 14.0;/g' "$PBXPROJ_PATH"

# Update Podfile
if [ -f "$PODFILE_PATH" ]; then
    # Backup original Podfile
    cp "$PODFILE_PATH" "${PODFILE_PATH}.backup"
    
    # Create new Podfile content
    cat > "$PODFILE_PATH" << EOL
platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

def shared_pods
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  shared_pods
end

target 'ImageNotification' do
  use_frameworks!
  use_modular_headers!
  shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_NOTIFICATIONS=1'
      ]
    end
  end
end
EOL

    echo "Updated Podfile with proper target configuration"
fi

# Disable iPad support
echo "Configuring device support..."
sed -i '' 's/TARGETED_DEVICE_FAMILY = .*/TARGETED_DEVICE_FAMILY = 1;/g' "$PBXPROJ_PATH"

# Update build settings for both targets
echo "Updating build settings..."
for target in "Runner" "ImageNotification"; do
    xcrun xcodebuild -project "ios/Runner.xcodeproj" -target "$target" -configuration Debug clean build \
        IPHONEOS_DEPLOYMENT_TARGET=14.0 \
        TARGETED_DEVICE_FAMILY=1 \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES >/dev/null 2>&1 || true
done

# Run pod install if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing pods..."
    cd ios && pod install && cd ..
fi

echo "iOS prebuild configuration completed successfully!" 