#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

swift build -c release

app="$root/Subtitle Cover.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/release/SubtitleCover" "$app/Contents/MacOS/SubtitleCover"
cp "$root/Resources/SubtitleCover.icns" "$app/Contents/Resources/SubtitleCover.icns"
chmod +x "$app/Contents/MacOS/SubtitleCover"

cat > "$app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Subtitle Cover</string>
    <key>CFBundleExecutable</key>
    <string>SubtitleCover</string>
    <key>CFBundleIconFile</key>
    <string>SubtitleCover.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.subtitlecover.app</string>
    <key>CFBundleName</key>
    <string>Subtitle Cover</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --sign - "$app"
echo "Built $app"
