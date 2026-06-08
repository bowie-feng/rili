#!/bin/bash
set -e

APP_NAME="rili"
BUILD_DIR=".build"
RELEASE_DIR="$BUILD_DIR/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle: $APP_BUNDLE"

# 清理旧 bundle
rm -rf "$APP_BUNDLE"

# 创建目录结构
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制二进制
cp "$RELEASE_DIR/$APP_NAME" "$MACOS_DIR/"

# 创建 Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>rili</string>
    <key>CFBundleIdentifier</key>
    <string>com.rili.desktopcalendar</string>
    <key>CFBundleName</key>
    <string>桌面日历</string>
    <key>CFBundleDisplayName</key>
    <string>桌面日历</string>
    <key>CFBundleVersion</key>
    <string>1.1.1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

# 生成图标 (使用系统日历 SF Symbol 生成 PNG → ICNS)
echo "🎨 Generating app icon..."
ICON_PNG="$RESOURCES_DIR/AppIcon.png"
ICONSET="$RESOURCES_DIR/AppIcon.iconset"

# 使用 Swift 生成图标
cat > /tmp/gen-icon.swift << 'SWIFT'
import AppKit
import Foundation

let size = NSSize(width: 512, height: 512)
let image = NSImage(size: size)

image.lockFocus()

// 蓝色圆角矩形背景
let bgPath = NSBezierPath(
    roundedRect: NSRect(origin: .zero, size: size),
    xRadius: 115,
    yRadius: 115
)
NSColor.systemBlue.setFill()
bgPath.fill()

// 白色顶部条 (日历页眉)
let headerRect = NSRect(x: 0, y: size.height * 0.55, width: size.width, height: size.height * 0.2)
let headerPath = NSBezierPath(rect: headerRect)
NSColor.white.withAlphaComponent(0.25).setFill()
headerPath.fill()

// 日历日期文字
let day = Calendar.current.component(.day, from: Date())
let text = "\(day)"
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 180, weight: .bold),
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph
]

let textSize = text.size(withAttributes: attrs)
let textRect = NSRect(
    x: (size.width - textSize.width) / 2,
    y: size.height * 0.12,
    width: textSize.width,
    height: textSize.height
)
text.draw(in: textRect, withAttributes: attrs)

image.unlockFocus()

// 保存 PNG
if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/AppIcon.png"))
    print("Icon generated")
}
SWIFT

swift /tmp/gen-icon.swift 2>/dev/null
rm /tmp/gen-icon.swift

if [ -f "/tmp/AppIcon.png" ]; then
    cp /tmp/AppIcon.png "$ICON_PNG"
    rm /tmp/AppIcon.png

    # 生成 iconset
    mkdir -p "$ICONSET"
    sips -z 16 16   "$ICON_PNG" --out "$ICONSET/icon_16x16.png" &>/dev/null
    sips -z 32 32   "$ICON_PNG" --out "$ICONSET/icon_16x16@2x.png" &>/dev/null
    sips -z 32 32   "$ICON_PNG" --out "$ICONSET/icon_32x32.png" &>/dev/null
    sips -z 64 64   "$ICON_PNG" --out "$ICONSET/icon_32x32@2x.png" &>/dev/null
    sips -z 128 128 "$ICON_PNG" --out "$ICONSET/icon_128x128.png" &>/dev/null
    sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_128x128@2x.png" &>/dev/null
    sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_256x256.png" &>/dev/null
    sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_256x256@2x.png" &>/dev/null
    sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_512x512.png" &>/dev/null
    iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null

    rm -rf "$ICONSET" "$ICON_PNG"
    echo "   Icon created: $RESOURCES_DIR/AppIcon.icns"
else
    echo "   ⚠️  Icon generation skipped (use default)"
fi

# Ad-hoc 代码签名 — SMAppService.register() 要求 bundle 已签名
echo "🔏 Signing app bundle (ad-hoc)..."
xattr -cr "$APP_BUNDLE" 2>/dev/null
codesign --force --sign - "$APP_BUNDLE" 2>/dev/null && echo "   Signed with ad-hoc identity" || echo "   ⚠️  Signing skipped (codesign not available)"

echo ""
echo "✅ App bundle created: $APP_BUNDLE"
echo "   Size: $(du -sh "$APP_BUNDLE" | cut -f1)"
echo ""
echo "📌 To install: mv $APP_BUNDLE /Applications/"
echo "📌 Or double-click: open $APP_BUNDLE"
