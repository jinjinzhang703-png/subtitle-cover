#!/bin/bash
set -euo pipefail
export COPYFILE_DISABLE=1

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

swift build -c release --arch arm64 --arch x86_64

app="$root/dist/Subtitle Cover.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/release/SubtitleCover" "$app/Contents/MacOS/SubtitleCover"
cp "$root/Resources/SubtitleCover.icns" "$app/Contents/Resources/SubtitleCover.icns"
chmod +x "$app/Contents/MacOS/SubtitleCover"
xattr -cr "$app" || true
dot_clean -m "$app" || true

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
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --sign - "$app"

pkg="$root/dist/Subtitle-Cover-1.1.0.pkg"
rm -rf "$root/dist/payload" "$root/dist/component.pkg"
mkdir -p "$root/dist/payload"
ditto --norsrc "$app" "$root/dist/payload/Subtitle Cover.app"
dot_clean -m "$root/dist/payload" || true
pkgbuild \
  --root "$root/dist/payload" \
  --identifier com.subtitlecover.pkg \
  --version 1.1.0 \
  --install-location /Applications \
  --component-plist "$root/scripts/installer/components.plist" \
  "$root/dist/component.pkg"
productbuild \
  --distribution "$root/scripts/installer/distribution.xml" \
  --package-path "$root/dist" \
  --resources "$root/scripts/installer" \
  "$pkg"
rm -rf "$root/dist/payload" "$root/dist/component.pkg"
echo "Built $app"
echo "Built $pkg"
