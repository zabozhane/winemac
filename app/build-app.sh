#!/bin/zsh
# Builds WineMac.app into the winemac root (next to bin/winemac), which is where the app looks for the CLI.

emulate -L zsh
setopt err_exit no_unset pipe_fail

typeset -r APP_DIR=${0:A:h}
typeset -r WINEMAC_ROOT=${APP_DIR:h}
typeset -r BUILD_DIR=$APP_DIR/.build
typeset -r SWIFTPM_STATE=$WINEMAC_ROOT/cache/swiftpm
typeset -r BUNDLE=$WINEMAC_ROOT/WineMac.app
# AppKit writes preferences and saved window state under the user's home (~/Library/Preferences, ...).
# CFFIXED_USER_HOME points that "home" of the app process inside winemac; child processes keep the real $HOME.
typeset -r APP_HOME=$WINEMAC_ROOT/state/app-home

# SwiftPM keeps caches and config in ~/Library by default; keep them inside winemac like everything else.
swift build --package-path "$APP_DIR" --scratch-path "$BUILD_DIR" -c release \
  --cache-path "$SWIFTPM_STATE/cache" \
  --config-path "$SWIFTPM_STATE/config" \
  --security-path "$SWIFTPM_STATE/security"

typeset -r BINARY=$(swift build --package-path "$APP_DIR" --scratch-path "$BUILD_DIR" -c release --show-bin-path)/WineMac

rm -rf -- "$BUNDLE"
mkdir -p "$APP_HOME"
mkdir -p "$BUNDLE/Contents/MacOS"
cp -- "$BINARY" "$BUNDLE/Contents/MacOS/WineMac"
cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>WineMac</string>
  <key>CFBundleIdentifier</key><string>local.winemac</string>
  <key>CFBundleName</key><string>WineMac</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSEnvironment</key>
  <dict>
    <key>CFFIXED_USER_HOME</key><string>$APP_HOME</string>
  </dict>
</dict>
</plist>
PLIST
# Ad-hoc signature: Apple Silicon refuses to run unsigned arm64 binaries.
codesign --force --sign - "$BUNDLE"
print -r -- "==> Built $BUNDLE"
