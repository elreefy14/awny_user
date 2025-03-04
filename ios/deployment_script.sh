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

# Clean up any previous builds
echo "Cleaning previous builds..."
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
fi
if [ -f "ios/Podfile.lock" ]; then
    rm ios/Podfile.lock
fi

# Update minimum iOS deployment target to 14.0 in project.pbxproj
echo "Updating deployment target in Xcode project..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9]\{1,2\}\.[0-9]\{1,2\};/IPHONEOS_DEPLOYMENT_TARGET = 14.0;/g' "$PBXPROJ_PATH"

# Update Podfile configurations
echo "Updating Podfile configurations..."
if [ -f "$PODFILE_PATH" ]; then
    # Backup Podfile
    cp "$PODFILE_PATH" "${PODFILE_PATH}.backup"
    
    # Update or add platform version
    if grep -q "platform :ios" "$PODFILE_PATH"; then
        sed -i '' 's/platform :ios, .*/platform :ios, '\''14.0'\''/' "$PODFILE_PATH"
    else
        sed -i '' '1i\
platform :ios, '\''14.0'\''\
' "$PODFILE_PATH"
    fi
    
    # Update post_install hook
    if grep -q "post_install" "$PODFILE_PATH"; then
        # Update existing post_install
        awk '
        /post_install/ {
            print $0
            while(getline) {
                if ($0 ~ /end/) {
                    print "    target.build_configurations.each do |config|"
                    print "      config.build_settings['\''IPHONEOS_DEPLOYMENT_TARGET'\''] = '\''14.0'\''"
                    print "      config.build_settings['\''GCC_PREPROCESSOR_DEFINITIONS'\''] ||= ['\''$(inherited)'\'', '\''PERMISSION_NOTIFICATIONS=1'\'']"
                    if ($0 ~ /end/) { print $0 }
                    break
                }
                print $0
            }
        }
        !/post_install/ { print $0 }
        ' "${PODFILE_PATH}.backup" > "$PODFILE_PATH"
    else
        # Add new post_install
        cat >> "$PODFILE_PATH" << EOL

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_NOTIFICATIONS=1']
    end
  end
end
EOL
    fi
    
    # Clean up backup
    rm "${PODFILE_PATH}.backup"
    
    echo "Updated iOS deployment target in Podfile to 14.0"
fi

# Update ImageNotification target if it exists
if grep -q "target 'ImageNotification'" "$PODFILE_PATH"; then
    echo "Configuring ImageNotification target..."
    sed -i '' '/target '\''ImageNotification'\'' do/,/end/ s/inherit! :search_paths/inherit! :search_paths\n    pod '\''FirebaseMessaging'\''\n    pod '\''firebase_core'\''/' "$PODFILE_PATH"
fi

# Disable iPad support (keep iPhone only)
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

# Install pods if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing pods..."
    cd ios && pod install && cd ..
fi

echo "iOS prebuild configuration completed successfully!" 