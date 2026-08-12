#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SVG_FILE="$ROOT/icon.svg"
ICON_SET="$ROOT/Resources/AppIcon.appiconset"

if [ ! -f "$SVG_FILE" ]; then
    echo "Error: icon.svg not found"
    exit 1
fi

mkdir -p "$ICON_SET"

echo "Creating icon variants..."

# Icon sizes needed for macOS
declare -a sizes=(16 32 64 128 256 512 1024)

for size in "${sizes[@]}"; do
    # For retina displays, we need @2x versions too
    for scale in 1 2; do
        if [ $scale -eq 1 ]; then
            pixel=$size
            suffix=""
        else
            pixel=$((size * 2))
            suffix="@2x"
        fi

        filename="icon_${size}x${size}${suffix}.png"

        if command -v convert >/dev/null 2>&1; then
            convert -background none -density 96 -resize "${pixel}x${pixel}" \
                "$SVG_FILE" "$ICON_SET/$filename" 2>/dev/null
            echo "  ✓ Created $filename"
        elif command -v magick >/dev/null 2>&1; then
            magick convert -background none -density 96 -resize "${pixel}x${pixel}" \
                "$SVG_FILE" "$ICON_SET/$filename" 2>/dev/null
            echo "  ✓ Created $filename"
        fi
    done
done

# Create Contents.json
cat > "$ICON_SET/Contents.json" << 'EOF'
{
  "images" : [
    {"idiom" : "mac", "size" : "16x16", "filename" : "icon_16x16.png", "scale" : "1x"},
    {"idiom" : "mac", "size" : "16x16", "filename" : "icon_16x16@2x.png", "scale" : "2x"},
    {"idiom" : "mac", "size" : "32x32", "filename" : "icon_32x32.png", "scale" : "1x"},
    {"idiom" : "mac", "size" : "32x32", "filename" : "icon_32x32@2x.png", "scale" : "2x"},
    {"idiom" : "mac", "size" : "64x64", "filename" : "icon_64x64.png", "scale" : "1x"},
    {"idiom" : "mac", "size" : "64x64", "filename" : "icon_64x64@2x.png", "scale" : "2x"},
    {"idiom" : "mac", "size" : "128x128", "filename" : "icon_128x128.png", "scale" : "1x"},
    {"idiom" : "mac", "size" : "128x128", "filename" : "icon_128x128@2x.png", "scale" : "2x"},
    {"idiom" : "mac", "size" : "256x256", "filename" : "icon_256x256.png", "scale" : "1x"},
    {"idiom" : "mac", "size" : "256x256", "filename" : "icon_256x256@2x.png", "scale" : "2x"},
    {"idiom" : "mac", "size" : "512x512", "filename" : "icon_512x512.png", "scale" : "1x"},
    {"idiom" : "mac", "size" : "512x512", "filename" : "icon_512x512@2x.png", "scale" : "2x"}
  ],
  "info" : {"version" : 1, "author" : "xcode"}
}
EOF

echo ""
echo "✓ Icon set created in $ICON_SET"
echo "✓ App will use this icon automatically on next build"
