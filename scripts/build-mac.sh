#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
FONT_FILE="node_modules/pretendard/dist/public/variable/PretendardVariable.ttf"
if [ ! -f "$FONT_FILE" ]; then
  echo '먼저 npm ci를 실행해 주세요.' >&2
  exit 1
fi
cp "$FONT_FILE" apps/macos/Sources/MementoMori/Resources/PretendardVariable.ttf
cp apps/web/public/licenses/pretendard.txt apps/macos/Sources/MementoMori/Resources/pretendard-license.txt
swift build --package-path apps/macos -c release
BIN_DIR="$(swift build --package-path apps/macos -c release --show-bin-path)"
APP_DIR="$ROOT_DIR/artifacts/mac/MementoMori.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/MementoMori" "$APP_DIR/Contents/MacOS/MementoMori"
cp apps/macos/Sources/MementoMori/Resources/* "$APP_DIR/Contents/Resources/"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.mementomori.mac</string>
<key>CFBundleName</key><string>MementoMori</string>
<key>CFBundleDisplayName</key><string>메멘토모리</string>
<key>CFBundleExecutable</key><string>MementoMori</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
</dict></plist>
PLIST
ICON_DIR="$ROOT_DIR/artifacts/mac/AppIcon.iconset"
mkdir -p "$ICON_DIR"
for SIZE in 16 32 128 256 512; do
  sips -z "$SIZE" "$SIZE" apps/web/public/icon-512.png --out "$ICON_DIR/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE_SIZE=$((SIZE * 2))
  sips -z "$DOUBLE_SIZE" "$DOUBLE_SIZE" apps/web/public/icon-512.png --out "$ICON_DIR/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICON_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
# Local ad-hoc signature only. Public distribution needs Developer ID + notarization.
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
echo "Built: $APP_DIR"
