import AppKit
import Foundation

// Draws the Bob Select Helper app icon at an arbitrary pixel size and
// writes the full .iconset required by iconutil.

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)

    // macOS icons leave breathing room around the squircle.
    let inset = size * 0.06
    let plate = canvas.insetBy(dx: inset, dy: inset)
    let radius = plate.width * 0.225

    let platePath = NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius)

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.31, green: 0.60, blue: 1.00, alpha: 1.0),
            NSColor(calibratedRed: 0.00, green: 0.32, blue: 0.86, alpha: 1.0)
        ]
    )!
    gradient.draw(in: platePath, angle: -90)

    // Speech bubble
    let bubbleWidth = plate.width * 0.66
    let bubbleHeight = plate.height * 0.46
    let bubble = NSRect(
        x: plate.minX + (plate.width - bubbleWidth) / 2,
        y: plate.minY + plate.height * 0.34,
        width: bubbleWidth,
        height: bubbleHeight
    )
    let bubbleRadius = bubbleHeight * 0.28
    let bubblePath = NSBezierPath(roundedRect: bubble, xRadius: bubbleRadius, yRadius: bubbleRadius)

    // Tail pointing down-left, merged into the bubble shape.
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: bubble.minX + bubble.width * 0.20, y: bubble.minY + bubble.height * 0.18))
    tail.line(to: NSPoint(x: bubble.minX + bubble.width * 0.10, y: plate.minY + plate.height * 0.20))
    tail.line(to: NSPoint(x: bubble.minX + bubble.width * 0.46, y: bubble.minY + bubble.height * 0.16))
    tail.close()

    NSColor.white.setFill()
    bubblePath.fill()
    tail.fill()

    // Text lines inside the bubble.
    let lineColor = NSColor(calibratedRed: 0.00, green: 0.36, blue: 0.90, alpha: 1.0)
    lineColor.setStroke()

    let lineWidth = max(1.0, bubbleHeight * 0.11)
    let lineInsetX = bubble.width * 0.16
    let lineLengths: [CGFloat] = [1.0, 0.82, 0.55]

    for (index, factor) in lineLengths.enumerated() {
        let y = bubble.maxY - bubble.height * (0.30 + 0.22 * CGFloat(index))
        let startX = bubble.minX + lineInsetX
        let maxLength = bubble.width - lineInsetX * 2
        let line = NSBezierPath()
        line.lineWidth = lineWidth
        line.lineCapStyle = .round
        line.move(to: NSPoint(x: startX, y: y))
        line.line(to: NSPoint(x: startX + maxLength * factor, y: y))
        line.stroke()
    }

    // Selection accent dot.
    let dotDiameter = plate.width * 0.17
    let dot = NSRect(
        x: plate.maxX - dotDiameter * 1.25,
        y: plate.maxY - dotDiameter * 1.25,
        width: dotDiameter,
        height: dotDiameter
    )
    NSColor(calibratedRed: 1.00, green: 0.55, blue: 0.16, alpha: 1.0).setFill()
    NSBezierPath(ovalIn: dot).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Exact filenames iconutil expects. Note: no 64x64 entry exists in a .iconset.
let variants: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

let outputDirectory = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.iconset"

try? FileManager.default.createDirectory(
    atPath: outputDirectory,
    withIntermediateDirectories: true
)

for variant in variants {
    let rep = drawIcon(size: variant.pixels)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("Failed to encode \(variant.name)\n".data(using: .utf8)!)
        exit(1)
    }
    let path = (outputDirectory as NSString).appendingPathComponent(variant.name)
    try! data.write(to: URL(fileURLWithPath: path))
    print("  \(variant.name) — \(Int(variant.pixels))x\(Int(variant.pixels))")
}
