import AppKit
import Foundation

let outputDir = URL(fileURLWithPath: "/Volumes/Data/Projects/cashflow/cashflow/Assets.xcassets/AppIcon.appiconset")
let files = ["AppIcon-1024.png", "AppIcon-1024-dark.png", "AppIcon-1024-tinted.png"]
let canvasSize = CGSize(width: 1024, height: 1024)

func drawIcon() -> NSImage {
    let image = NSImage(size: canvasSize)
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = CGRect(origin: .zero, size: canvasSize)
    let corner: CGFloat = 230

    let background = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.44, green: 0.81, blue: 0.20, alpha: 1),
        NSColor(calibratedRed: 0.14, green: 0.57, blue: 0.23, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -90)

    let border = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: corner - 12, yRadius: corner - 12)
    NSColor.white.withAlphaComponent(0.14).setStroke()
    border.lineWidth = 8
    border.stroke()

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: 510, weight: .regular)
    if let book = NSImage(systemSymbolName: "book.pages.fill", accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig) {
        let bookRect = CGRect(x: 196, y: 210, width: 630, height: 630)
        book.draw(in: bookRect, from: .zero, operation: .sourceOver, fraction: 1)
    }

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let dollarAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 188, weight: .black),
        .foregroundColor: NSColor(calibratedRed: 0.18, green: 0.60, blue: 0.25, alpha: 1),
        .paragraphStyle: paragraph
    ]
    NSString(string: "$").draw(in: CGRect(x: 480, y: 446, width: 150, height: 180), withAttributes: dollarAttributes)

    let coinRect = CGRect(x: 674, y: 196, width: 220, height: 220)
    let coinGlow = NSBezierPath(ovalIn: coinRect.insetBy(dx: -20, dy: -20))
    NSColor.black.withAlphaComponent(0.08).setFill()
    coinGlow.fill()

    let coin = NSBezierPath(ovalIn: coinRect)
    let coinGradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.35, alpha: 1),
        NSColor(calibratedRed: 0.97, green: 0.71, blue: 0.16, alpha: 1)
    ])!
    coinGradient.draw(in: coin, relativeCenterPosition: .zero)

    NSColor(calibratedRed: 0.98, green: 0.92, blue: 0.56, alpha: 1).setStroke()
    coin.lineWidth = 14
    coin.stroke()

    let coinInner = NSBezierPath(ovalIn: coinRect.insetBy(dx: 22, dy: 22))
    NSColor.white.withAlphaComponent(0.18).setStroke()
    coinInner.lineWidth = 8
    coinInner.stroke()

    let coinAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 112, weight: .bold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.96),
        .paragraphStyle: paragraph
    ]
    NSString(string: "$").draw(in: CGRect(x: 722, y: 252, width: 124, height: 132), withAttributes: coinAttributes)

    return image
}

let icon = drawIcon()

for file in files {
    let destination = outputDir.appendingPathComponent(file)
    guard let tiff = icon.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        continue
    }
    try png.write(to: destination)
}

print("Generated app icons in \(outputDir.path)")
