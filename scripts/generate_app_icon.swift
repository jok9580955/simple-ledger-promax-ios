import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root
    .appendingPathComponent("简单账本ProMax/Resources/Assets.xcassets/AppIcon.appiconset")
let output = iconset.appendingPathComponent("AppIcon-1024.png")

let width = 1024
let height = 1024
let bytesPerRow = width * 4
var pixels = [UInt8](repeating: 255, count: bytesPerRow * height)

guard let context = CGContext(
    data: &pixels,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("Failed to create drawing context")
}

let size = CGSize(width: width, height: height)
let bounds = CGRect(origin: .zero, size: size)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func cgColor(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    color(red, green, blue, alpha).cgColor
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fillGradient(_ rect: CGRect, colors: [CGColor], start: CGPoint, end: CGPoint) {
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
    context.saveGState()
    context.addRect(rect)
    context.clip()
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
    context.restoreGState()
}

func fillRadialGradient(_ rect: CGRect, colors: [CGColor]) {
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.58, 1])!
    context.saveGState()
    context.addEllipse(in: rect)
    context.clip()
    context.drawRadialGradient(
        gradient,
        startCenter: CGPoint(x: rect.midX - 110, y: rect.midY + 140),
        startRadius: 12,
        endCenter: CGPoint(x: rect.midX, y: rect.midY),
        endRadius: rect.width * 0.56,
        options: []
    )
    context.restoreGState()
}

func fillPath(_ path: CGPath, color: CGColor) {
    context.addPath(path)
    context.setFillColor(color)
    context.fillPath()
}

func strokeLine(from start: CGPoint, to end: CGPoint, width: CGFloat, color: CGColor) {
    context.setStrokeColor(color)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.move(to: start)
    context.addLine(to: end)
    context.strokePath()
}

func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor, kern: CGFloat = 0) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: color,
        .kern: kern
    ]
    NSString(string: text).draw(at: point, withAttributes: attributes)
}

context.setShouldAntialias(true)
context.setAllowsAntialiasing(true)

fillGradient(
    bounds,
    colors: [cgColor(248, 250, 255), cgColor(231, 238, 249), cgColor(214, 226, 244)],
    start: CGPoint(x: 0, y: height),
    end: CGPoint(x: width, y: 0)
)

fillRadialGradient(
    CGRect(x: 72, y: 86, width: 880, height: 880),
    colors: [cgColor(0, 122, 255, 0.28), cgColor(52, 199, 89, 0.10), cgColor(255, 255, 255, 0)]
)

context.setShadow(offset: CGSize(width: 0, height: -26), blur: 54, color: cgColor(24, 70, 140, 0.22))
fillPath(roundedRect(CGRect(x: 156, y: 164, width: 712, height: 696), radius: 164), color: cgColor(255, 255, 255, 0.96))
context.setShadow(offset: .zero, blur: 0)

fillPath(roundedRect(CGRect(x: 258, y: 704, width: 508, height: 86), radius: 43), color: cgColor(10, 132, 255))

context.saveGState()
context.addPath(roundedRect(CGRect(x: 202, y: 564, width: 620, height: 238), radius: 118))
context.clip()
fillGradient(
    CGRect(x: 202, y: 564, width: 620, height: 238),
    colors: [cgColor(255, 255, 255, 0.70), cgColor(255, 255, 255, 0.10)],
    start: CGPoint(x: 202, y: 802),
    end: CGPoint(x: 822, y: 564)
)
context.restoreGState()

let graphics = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics

let amount = NSString(string: "¥36")
let amountAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 208, weight: .bold),
    .foregroundColor: color(18, 23, 34),
    .kern: -3
]
let amountSize = amount.size(withAttributes: amountAttributes)
amount.draw(at: CGPoint(x: (CGFloat(width) - amountSize.width) / 2, y: 466), withAttributes: amountAttributes)

NSGraphicsContext.restoreGraphicsState()

let blue = cgColor(10, 132, 255)
let green = cgColor(52, 199, 89)
let dark = cgColor(22, 28, 40)
let muted = cgColor(137, 143, 153)

for (index, y) in [386, 306, 226].enumerated() {
    context.setFillColor(index == 2 ? green : blue)
    context.fillEllipse(in: CGRect(x: 276, y: CGFloat(y) - 18, width: 36, height: 36))
    strokeLine(from: CGPoint(x: 342, y: y), to: CGPoint(x: 732, y: y), width: 22, color: index == 1 ? dark : muted)
}

guard let cgImage = context.makeImage() else {
    fatalError("Failed to make icon image")
}

try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
guard let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Failed to create PNG destination")
}
CGImageDestinationAddImage(destination, cgImage, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Failed to write PNG")
}

print("Wrote \(output.path)")
