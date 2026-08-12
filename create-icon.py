#!/usr/bin/env python3
import os
import json
from PIL import Image, ImageDraw

def create_icon(size):
    """Create an icon image at the specified size"""
    # Create a new image with a blue background
    img = Image.new('RGBA', (size, size), (0, 102, 255, 255))
    draw = ImageDraw.Draw(img)

    # Draw rounded rectangle background with gradient effect
    padding = size // 10
    corner_radius = size // 8

    # Main chat bubble shape
    bubble_box = [padding, padding, size - padding, int(size * 0.7)]
    draw.rounded_rectangle(bubble_box, radius=corner_radius, fill=(255, 255, 255, 255))

    # Tail of the bubble
    tail_points = [
        (int(size * 0.25), int(size * 0.65)),
        (int(size * 0.15), size - padding),
        (int(size * 0.35), int(size * 0.7))
    ]
    draw.polygon(tail_points, fill=(255, 255, 255, 255))

    # Draw text lines inside bubble (representing message/translation)
    line_color = (0, 102, 255, 255)
    line_y_positions = [
        int(size * 0.25),
        int(size * 0.40),
        int(size * 0.55)
    ]

    line_width = max(1, size // 40)

    for line_y in line_y_positions:
        x_start = int(padding + size * 0.08)
        x_end = int(size - padding - size * 0.08)
        draw.line([(x_start, line_y), (x_end, line_y)], fill=line_color, width=line_width)

    # Add a small accent circle (represents the "select" action)
    accent_size = size // 6
    accent_x = int(size - padding - accent_size // 2)
    accent_y = int(padding + accent_size // 2)
    accent_box = [
        accent_x - accent_size // 2,
        accent_y - accent_size // 2,
        accent_x + accent_size // 2,
        accent_y + accent_size // 2
    ]
    draw.ellipse(accent_box, fill=(255, 107, 53, 255))  # Orange accent
    draw.ellipse(accent_box, outline=(255, 255, 255, 200), width=max(1, size // 60))

    return img

def main():
    icon_set_dir = 'Resources/AppIcon.appiconset'
    os.makedirs(icon_set_dir, exist_ok=True)

    print("Creating icon variants...")

    # Define all required sizes for macOS
    sizes = [
        (16, 1), (16, 2), (32, 1), (32, 2),
        (64, 1), (64, 2), (128, 1), (128, 2),
        (256, 1), (256, 2), (512, 1), (512, 2)
    ]

    images_info = []

    for base_size, scale in sizes:
        actual_size = base_size * scale
        filename = f"icon_{base_size}x{base_size}{'@2x' if scale == 2 else ''}.png"

        # Create and save icon
        img = create_icon(actual_size)
        filepath = os.path.join(icon_set_dir, filename)
        img.save(filepath)
        print(f"  ✓ Created {filename} ({actual_size}×{actual_size})")

        # Add to Contents.json info
        images_info.append({
            "idiom": "mac",
            "size": f"{base_size}x{base_size}",
            "filename": filename,
            "scale": f"{scale}x"
        })

    # Create Contents.json
    contents = {
        "images": images_info,
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }

    with open(os.path.join(icon_set_dir, 'Contents.json'), 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"\n✓ Icon set created in {icon_set_dir}")
    print("✓ App will use this icon automatically on next build")

if __name__ == '__main__':
    main()
