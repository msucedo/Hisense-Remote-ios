// Genera la imagen de la compra in-app "Versión completa" (1024×1024, sin transparencia ni
// esquinas redondeadas, como pide App Store Connect). Apple no quiere capturas aquí: es el ícono
// de la app con una estrella de "completa" y mosaicos de apps alrededor.
// Sin dependencias: CoreGraphics + ImageIO.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift tools/make-iap-image.swift [salida.png]
import CoreGraphics
import Foundation
import ImageIO

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : "appstore/iap-version-completa.png")
let iconURL = URL(fileURLWithPath: "HisenseRemote/HisenseRemote/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

let S: CGFloat = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}
func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Fondo oscuro como la app, con un brillo azul-morado (los colores del ícono) detrás del centro.
ctx.setFillColor(rgb(0.05, 0.06, 0.08)); ctx.fill(CGRect(x: 0, y: 0, width: S, height: S))
let glow = CGGradient(colorsSpace: space, colors: [rgb(0.30, 0.38, 0.95, 0.75), rgb(0.33, 0.24, 0.86, 0)] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: S / 2, y: S / 2), startRadius: 0,
                       endCenter: CGPoint(x: S / 2, y: S / 2), endRadius: S * 0.62, options: [])

// Mosaicos de apps alrededor (la función que desbloquea la compra), en los colores del ícono.
let tiles: [(CGFloat, CGFloat, CGFloat, CGColor)] = [   // x, y, tamaño, color
    (150, 760, 130, rgb(0.23, 0.51, 0.98)), (905, 905, 95, rgb(0.33, 0.24, 0.86)),
    (120, 330, 105, rgb(0.33, 0.24, 0.86)), (880, 160, 125, rgb(0.23, 0.51, 0.98)),
    (300, 130, 85, rgb(1, 1, 1, 0.22)), (700, 940, 80, rgb(1, 1, 1, 0.22)),
    (930, 520, 70, rgb(1, 1, 1, 0.18)), (60, 560, 65, rgb(1, 1, 1, 0.18)),
]
for (x, y, s, c) in tiles {
    ctx.addPath(rounded(CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s), s * 0.2237))
    ctx.setFillColor(c); ctx.fillPath()
    // un "botón de play" chico para que se lean como apps de video
    ctx.saveGState(); ctx.translateBy(x: x, y: y)
    let t = s * 0.18
    ctx.move(to: CGPoint(x: -t * 0.8, y: t)); ctx.addLine(to: CGPoint(x: t * 1.1, y: 0))
    ctx.addLine(to: CGPoint(x: -t * 0.8, y: -t)); ctx.closePath()
    ctx.setFillColor(rgb(1, 1, 1, 0.85)); ctx.fillPath(); ctx.restoreGState()
}

// El ícono de la app al centro, con sombra.
guard let src = CGImageSourceCreateWithURL(iconURL as CFURL, nil),
      let icon = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("no pude leer \(iconURL.path)") }
let iconSize: CGFloat = 520
let iconRect = CGRect(x: (S - iconSize) / 2, y: (S - iconSize) / 2, width: iconSize, height: iconSize)
let iconPath = rounded(iconRect, iconSize * 0.2237)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 60, color: rgb(0, 0, 0, 0.5))
ctx.addPath(iconPath); ctx.setFillColor(rgb(0, 0, 0)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState(); ctx.addPath(iconPath); ctx.clip(); ctx.draw(icon, in: iconRect); ctx.restoreGState()

// Insignia dorada con estrella arriba a la derecha del ícono: "versión completa".
let badge = CGPoint(x: iconRect.maxX - 30, y: iconRect.maxY - 30), br: CGFloat = 105
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: rgb(0, 0, 0, 0.45))
ctx.setFillColor(rgb(0.05, 0.06, 0.08))
ctx.fillEllipse(in: CGRect(x: badge.x - br - 12, y: badge.y - br - 12, width: 2 * (br + 12), height: 2 * (br + 12)))
ctx.restoreGState()
let gold = CGGradient(colorsSpace: space, colors: [rgb(1.0, 0.84, 0.30), rgb(0.96, 0.62, 0.10)] as CFArray,
                      locations: [0, 1])!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: badge.x - br, y: badge.y - br, width: 2 * br, height: 2 * br)); ctx.clip()
ctx.drawLinearGradient(gold, start: CGPoint(x: badge.x, y: badge.y + br), end: CGPoint(x: badge.x, y: badge.y - br),
                       options: [])
ctx.restoreGState()
// estrella de 5 puntas
ctx.saveGState(); ctx.translateBy(x: badge.x, y: badge.y - 4)
let outer = br * 0.62, inner = outer * 0.42
for i in 0..<10 {
    let a = CGFloat(i) * .pi / 5 + .pi / 2, r = i % 2 == 0 ? outer : inner
    let p = CGPoint(x: cos(a) * r, y: sin(a) * r)
    if i == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
}
ctx.closePath(); ctx.setFillColor(rgb(1, 1, 1)); ctx.fillPath(); ctx.restoreGState()

let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("no se pudo escribir \(out.path)") }
print("✓ \(out.path)")
