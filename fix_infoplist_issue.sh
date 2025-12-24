#!/bin/bash

echo "Setting up project to use BLEInfo.plist..."

# Create a temporary project configuration file
TEMP_XCCONFIG=$(mktemp)
cat << 'EOF' > $TEMP_XCCONFIG
INFOPLIST_FILE = TestBLE2/BLEInfo.plist
INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription = This app needs Bluetooth access to connect to your ESP32 device for controlling LED blinks.
INFOPLIST_KEY_NSBluetoothPeripheralUsageDescription = This app needs Bluetooth access to connect to your ESP32 device for controlling LED blinks.
EOF

echo "Created temporary build configuration at: $TEMP_XCCONFIG"
echo ""
echo "To fix the 'Multiple commands produce Info.plist' error:"
echo "1. Open your project in Xcode"
echo "2. Select your project in the Project Navigator"
echo "3. Select the TestBLE2 target"
echo "4. Go to the 'Build Settings' tab"
echo "5. Search for 'Info.plist'"
echo "6. Change the 'Info.plist File' setting to: TestBLE2/BLEInfo.plist"
echo "7. Go to the 'Build Phases' tab"
echo "8. Expand the 'Copy Bundle Resources' phase"
echo "9. If Info.plist is listed there, remove it (but keep BLEInfo.plist)"
echo ""
echo "Now you can build your project with this configuration file as a temporary solution:"
echo "xcodebuild -project TestBLE2.xcodeproj -xcconfig $TEMP_XCCONFIG -allowProvisioningUpdates -destination 'platform=iOS Simulator,name=iPhone 15' build"