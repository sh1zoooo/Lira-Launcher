#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
PREVIEW_ROOT="$ROOT/artifacts/lira-preview"
APP="$PREVIEW_ROOT/LiraPreview.app"
mkdir -p "$APP" "$PREVIEW_ROOT/screenshots"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
ARCH=$(uname -m)
xcrun --sdk iphonesimulator clang -fobjc-arc -fcommon -Wno-incomplete-implementation \
  -target "$ARCH-apple-ios15.0-simulator" -isysroot "$SDK" \
  -I Natives -I Natives/include -I Natives/external/UnzipKit -I Natives/external/AltKit \
  -F Natives/resources/Frameworks \
  scripts/lira-preview/PreviewHost.m Natives/LiraLivingWorld.m Natives/LiraHomeViewController.m \
  Natives/LiraLibraryViewController.m Natives/LiraSettingsViewController.m \
  Natives/AmeRootTabController.m Natives/AmeLaunchProgress.m \
  -framework UIKit -framework Foundation -framework QuartzCore -o "$APP/LiraPreview"
cp -R Natives/resources/LiraWorlds Natives/resources/ru.lproj "$APP/"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.lira.preview</string><key>CFBundleExecutable</key><string>LiraPreview</string><key>CFBundleName</key><string>Lira Preview</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>1.0</string><key>LSRequiresIPhoneOS</key><true/><key>UILaunchScreen</key><dict/><key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array><key>UISupportedInterfaceOrientations</key><array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
DEVICE=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for a in d["devices"].values() for x in a if "iPhone" in x["name"]))')
xcrun simctl boot "$DEVICE" || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl status_bar "$DEVICE" override --time '9:41' --batteryState charged --batteryLevel 100
xcrun simctl install "$DEVICE" "$APP"
for CASE in populated empty; do
  xcrun simctl terminate "$DEVICE" dev.lira.preview || true
  EMPTY=NO
  if [ "$CASE" = empty ]; then EMPTY=YES; fi
  xcrun simctl launch "$DEVICE" dev.lira.preview -EmptyLibrary "$EMPTY"
  CONTAINER=$(xcrun simctl get_app_container "$DEVICE" dev.lira.preview data)
  for TRY in {1..30}; do
    if [ -f "$CONTAINER/Documents/result.txt" ]; then break; fi
    sleep 1
  done
  test -f "$CONTAINER/Documents/result.txt"
  mkdir -p "$PREVIEW_ROOT/screenshots/$CASE"
  cp "$CONTAINER/Documents/"* "$PREVIEW_ROOT/screenshots/$CASE/"
  cat "$CONTAINER/Documents/result.txt"
  rm "$CONTAINER/Documents/result.txt"
done
xcrun simctl terminate "$DEVICE" dev.lira.preview
