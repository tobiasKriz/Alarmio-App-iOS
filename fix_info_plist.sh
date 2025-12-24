#!/bin/bash

# Create a unified Info.plist file
cat << 'EOF' > /Users/tobias/Desktop/TestBLE2/TestBLE2/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
	</dict>
	<key>UILaunchScreen</key>
	<dict/>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>armv7</string>
	</array>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>This app needs Bluetooth access to connect to your ESP32 device for controlling LED blinks.</string>
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>This app needs Bluetooth access to connect to your ESP32 device for controlling LED blinks.</string>
</dict>
</plist>
EOF

# Remove the Info-Custom.plist file to avoid confusion
rm -f /Users/tobias/Desktop/TestBLE2/TestBLE2/Info-Custom.plist

# Create a temporary project settings file to update the INFOPLIST_FILE setting
TEMP_XCCONFIG=$(mktemp)
cat << 'EOF' > $TEMP_XCCONFIG
INFOPLIST_FILE = TestBLE2/Info.plist
EOF

echo "Created unified Info.plist and temporary xcconfig file"
echo "Now you should build the project with this configuration:"
echo "xcodebuild -project TestBLE2.xcodeproj -xcconfig $TEMP_XCCONFIG"
echo ""
echo "After building successfully, open Xcode and update the INFOPLIST_FILE setting"
echo "in your project build settings to point to TestBLE2/Info.plist"