// Draws the app icon and menu bar glyph into EdgeCases/Assets.xcassets.
// Run from the repo root: swift scripts/make-icons.swift
import AppKit

let assets = URL(filePath: "EdgeCases/Assets.xcassets")

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func png(width: Int, height: Int, to url: URL, draw: (CGContext) -> Void) {
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    draw(context)
    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

struct Palette {
    var background, pad, padStroke, finger: CGColor
}

let light = Palette(background: rgb(0xF1EFE8), pad: rgb(0xFFFFFF), padStroke: rgb(0xD3D1C7), finger: rgb(0xD85A30))

/// Full-bleed square: macOS masks it to its own icon shape, so the art stays inside the middle 80%.
func drawIcon(_ c: CGContext, size: CGFloat, palette p: Palette) {
    c.scaleBy(x: size / 1024, y: size / 1024)
    c.setFillColor(p.background)
    c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))

    let pad = CGRect(x: 172, y: 232, width: 680, height: 560)
    let padPath = CGPath(roundedRect: pad, cornerWidth: 72, cornerHeight: 72, transform: nil)
    c.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: rgb(0x000000, 0.12))
    c.setFillColor(p.pad)
    c.addPath(padPath)
    c.fillPath()
    c.setShadow(offset: .zero, blur: 0, color: nil)
    c.setStrokeColor(p.padStroke)
    c.setLineWidth(10)
    c.addPath(padPath)
    c.strokePath()

    // The finger near the top of the right edge, with the trail it left sliding up.
    let x: CGFloat = 772
    for (y, r, a) in [(340.0, 13.0, 0.30), (425.0, 18.0, 0.50), (515.0, 23.0, 0.75)] as [(CGFloat, CGFloat, CGFloat)] {
        c.setFillColor(p.finger.copy(alpha: a)!)
        c.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
    c.setFillColor(p.finger)
    c.fillEllipse(in: CGRect(x: x - 62, y: 640 - 62, width: 124, height: 124))
}

/// The same picture as a black template for the menu bar, 20×15 points. Paused has no finger.
func drawGlyph(_ c: CGContext, scale: CGFloat, paused: Bool) {
    c.scaleBy(x: scale, y: scale)
    c.setStrokeColor(rgb(0x000000))
    c.setFillColor(rgb(0x000000))
    c.setLineWidth(1.4)
    c.addPath(CGPath(roundedRect: CGRect(x: 1.2, y: 1.2, width: 17.6, height: 12.6), cornerWidth: 2.8, cornerHeight: 2.8, transform: nil))
    c.strokePath()
    guard !paused else { return }
    c.fillEllipse(in: CGRect(x: 13.2, y: 8.2, width: 3.6, height: 3.6))
    for (y, r) in [(6.0, 0.75), (3.9, 0.6)] as [(CGFloat, CGFloat)] {
        c.fillEllipse(in: CGRect(x: 15 - r, y: y - r, width: r * 2, height: r * 2))
    }
}

func write(_ json: String, to url: URL) {
    try! json.write(to: url, atomically: true, encoding: .utf8)
}

let fm = FileManager.default
try? fm.removeItem(at: assets)
let iconSet = assets.appending(path: "AppIcon.appiconset")
let accent = assets.appending(path: "AccentColor.colorset")
for folder in [iconSet, accent] { try! fm.createDirectory(at: folder, withIntermediateDirectories: true) }
write(#"{ "info" : { "author" : "xcode", "version" : 1 } }"#, to: assets.appending(path: "Contents.json"))

var images: [String] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        // Mac icon sets take no dark variant; macOS darkens the icon itself.
        let file = "icon-\(points)@\(scale)x.png"
        let pixels = points * scale
        png(width: pixels, height: pixels, to: iconSet.appending(path: file)) { drawIcon($0, size: CGFloat(pixels), palette: light) }
        images.append(#"{ "filename" : "\#(file)", "idiom" : "mac", "scale" : "\#(scale)x", "size" : "\#(points)x\#(points)" }"#)
    }
}
write(#"{ "images" : [ \#(images.joined(separator: ",\n")) ], "info" : { "author" : "xcode", "version" : 1 } }"#,
      to: iconSet.appending(path: "Contents.json"))

for (name, paused) in [("MenuBarIcon", false), ("MenuBarIconPaused", true)] {
    let glyphSet = assets.appending(path: "\(name).imageset")
    try! fm.createDirectory(at: glyphSet, withIntermediateDirectories: true)
    var glyphs: [String] = []
    for scale in [1, 2, 3] {
        let file = "menubar@\(scale)x.png"
        png(width: 20 * scale, height: 15 * scale, to: glyphSet.appending(path: file)) { drawGlyph($0, scale: CGFloat(scale), paused: paused) }
        glyphs.append(#"{ "filename" : "\#(file)", "idiom" : "universal", "scale" : "\#(scale)x" }"#)
    }
    write(#"{ "images" : [ \#(glyphs.joined(separator: ", ")) ], "info" : { "author" : "xcode", "version" : 1 }, "properties" : { "template-rendering-intent" : "template" } }"#,
          to: glyphSet.appending(path: "Contents.json"))
}

write(#"""
{ "colors" : [
  { "color" : { "color-space" : "srgb", "components" : { "red" : "0.847", "green" : "0.353", "blue" : "0.188", "alpha" : "1.000" } }, "idiom" : "universal" },
  { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
    "color" : { "color-space" : "srgb", "components" : { "red" : "0.910", "green" : "0.443", "blue" : "0.290", "alpha" : "1.000" } }, "idiom" : "universal" }
], "info" : { "author" : "xcode", "version" : 1 } }
"""#, to: accent.appending(path: "Contents.json"))

print("Wrote \(assets.path)")
